class_name DirectReachabilityValidator
extends RefCounted

## Bounded offline entry-witness solver and real-body parity validator for one
## materialized layout. Its witnesses are never exposed as player auto-aim.

# A witness is accepted when its first top-surface contact lands within the
# bounded entry-sample tolerance. Requiring the exact sampled triangle would
# reject legitimate adjacent-facet contacts; this solver tolerance is separate
# from the current runtime paint footprint radius.
const TARGET_DISTANCE_TOLERANCE := 2.10
const RIGIDBODY_IDENTITY_DISTANCE_TOLERANCE := \
		StageEntryAimWitness.TERRAIN_FACET_PARITY_TOLERANCE
const RIGIDBODY_TARGET_RADIUS_CLEARANCE := 0.10
const MAXIMUM_PERPENDICULAR_MISS := 1.02
const ELEVATION_SAMPLE_STEP_DEGREES := 1.0
const ELEVATION_BISECTION_ITERATIONS := 12
# Certification bodies use layer 2 and never collide with one another; a
# wider offline batch keeps the real-body parity proof bounded without changing
# gameplay physics or the witness semantics.
const RIGIDBODY_BATCH_SIZE := 256
const WITNESS_SPATIAL_BUCKET_METERS := TARGET_DISTANCE_TOLERANCE
const CHECKSUM_OFFSET := 2166136261
const CHECKSUM_PRIME := 16777619
const DEFAULT_PAINT_SURFACE_TUNING := preload(
	"res://resources/paint/default_paint_surface_tuning.tres"
)


static func select_witness_index(
		witnesses: Array[AimTuple],
		witness_impact_points: PackedVector3Array,
		target_centroid_xz: Vector2
) -> int:
	if witnesses.is_empty() or witnesses.size() != witness_impact_points.size() \
			or not target_centroid_xz.is_finite():
		return -1
	var best_index := -1
	var best_distance_squared := INF
	for index in range(witnesses.size()):
		var witness := witnesses[index]
		var impact := witness_impact_points[index]
		if witness == null or not witness.is_valid() or not impact.is_finite():
			return -1
		var distance_squared := Vector2(impact.x, impact.z).distance_squared_to(
			target_centroid_xz
		)
		if best_index < 0 or distance_squared < best_distance_squared:
			best_index = index
			best_distance_squared = distance_squared
		elif distance_squared == best_distance_squared \
				and _aim_tuple_precedes(witness, witnesses[best_index]):
			best_index = index
	return best_index


static func validate_summit(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		terrain_surface: TerrainSurface,
		layout: GeneratedStageLayout,
		stage_bounds: AABB
) -> Dictionary:
	var region := layout.summit_region(0.25) if layout != null else []
	if region.is_empty():
		return {"valid": false, "rejection": &"empty_summit_region"}
	var witnesses: Array[AimTuple] = []
	var witness_impacts := PackedVector3Array()
	var witness_identities: Array[TrajectoryHitIdentity] = []
	var target_points := PackedVector3Array()
	var target_witness_indices := PackedInt32Array()
	var distance_margins := PackedFloat32Array()
	var range_margins := PackedFloat32Array()
	var maximum_height := -INF
	var summit_addresses: Dictionary = {}
	for sample in region:
		summit_addresses[_triangle_key(sample.cell as Vector2i, int(sample.triangle))] = true
	for height in layout.heights:
		maximum_height = maxf(maximum_height, height)
	var best: Dictionary = {}
	var nearest_height_margin := INF
	for summit in region:
		var world_point := terrain_surface.to_global(summit.point as Vector3)
		var world_normal := (terrain_surface.global_transform.basis.inverse().transposed() \
			* (summit.normal as Vector3)).normalized()
		var solved := solve_one_target(
			space_state,
			cannon,
			layout,
			stage_bounds,
			world_point,
			world_normal,
			summit,
			true
		)
		if not bool(solved.get("valid", false)):
			continue
		var prediction := solved.prediction as TrajectoryPrediction
		if prediction == null or prediction.hit_identity == null \
				or prediction.hit_identity.contact_owner_id \
						!= TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
			continue
		if not summit_addresses.has(_triangle_key(
			prediction.hit_identity.terrain_cell,
			prediction.hit_identity.terrain_triangle
		)):
			continue
		# The witness must describe a shot that reaches terrain before the same
		# never-contacted cleanup used by live projectiles.
		if prediction.duration >= cannon.projectile_data.never_contacted_timeout:
			continue
		var world_offset_y := world_point.y - float(summit.point.y)
		var height_margin := maxf(
			(world_offset_y + maximum_height) - prediction.collision_contact_point().y,
			0.0
		)
		nearest_height_margin = minf(nearest_height_margin, height_margin)
		# A summit witness must remain inside the one-metre summit band. Within
		# that band, prefer a triangle-interior contact so the rigid body does not
		# straddle a faceted edge on the next physics tick.
		if height_margin > 1.0:
			continue
		var barycentric := prediction.hit_identity.barycentric
		var interior_margin := minf(barycentric.x, minf(barycentric.y, barycentric.z))
		if best.is_empty() or interior_margin > float(best.interior_margin) + 0.0001 \
				or (is_equal_approx(interior_margin, float(best.interior_margin)) \
				and height_margin < float(best.height_margin)):
			best = {
				"aim": solved.aim,
				"prediction": prediction,
				"prediction_duration": prediction.duration,
				"world_point": world_point,
				"height_margin": height_margin,
				"interior_margin": interior_margin,
				"range_margin": float(solved.get("range_margin", 0.0)),
			}
	if best.is_empty():
		return {
			"valid": false,
			"rejection": &"summit_contact_below_global_max" \
					if is_finite(nearest_height_margin) else &"summit_unreachable",
			"minimum_height_margin": nearest_height_margin,
		}
	var minimum_height_margin := float(best.height_margin)
	witnesses.append(best.aim as AimTuple)
	var best_prediction: TrajectoryPrediction = best.prediction
	witness_impacts.append(best_prediction.collision_contact_point())
	witness_identities.append(best_prediction.hit_identity)
	target_points.append(best.world_point)
	target_witness_indices.append(0)
	distance_margins.append(maxf(
		TARGET_DISTANCE_TOLERANCE \
				- best_prediction.collision_contact_point().distance_to(best.world_point),
		0.0
	))
	range_margins.append(float(best.range_margin))
	return {
		"valid": true,
		"rejection": &"",
		"region_count": region.size(),
		"witnesses": witnesses,
		"witness_impacts": witness_impacts,
		"witness_identities": witness_identities,
		"target_points": target_points,
		"target_witness_indices": target_witness_indices,
		"minimum_distance_margins": distance_margins,
		"minimum_range_margins": range_margins,
		"target_count": 1,
		"reachable_target_checksum": layout.reachable_target_checksum(target_witness_indices),
		"predictor_reachability_checksum": _prediction_checksum(
			witnesses,
			witness_identities,
			witness_impacts
		),
		"minimum_height_margin": minimum_height_margin,
		"prediction_duration": float(best.prediction_duration),
		"checksum": _summit_checksum(region, witnesses),
	}


static func _summit_checksum(region: Array[Dictionary], witnesses: Array[AimTuple]) -> int:
	var hash: int = CHECKSUM_OFFSET
	for summit in region:
		hash = _hash_int(hash, int(summit.triangle_id))
	for witness in witnesses:
		hash = _hash_int(hash, int(witness.stable_key().hash()))
	return hash


static func _aim_tuple_precedes(candidate: AimTuple, incumbent: AimTuple) -> bool:
	var candidate_key := [
		absf(candidate.yaw_degrees),
		candidate.elevation_degrees,
		candidate.power_percent,
		candidate.yaw_degrees,
	]
	var incumbent_key := [
		absf(incumbent.yaw_degrees),
		incumbent.elevation_degrees,
		incumbent.power_percent,
		incumbent.yaw_degrees,
	]
	for index in range(candidate_key.size()):
		if candidate_key[index] < incumbent_key[index]:
			return true
		if candidate_key[index] > incumbent_key[index]:
			return false
	return false


static func validate_rigidbody_batches(
		tree: SceneTree,
		certification_root: Node3D,
		cannon: CannonController,
		terrain_surface: TerrainSurface,
		layout: GeneratedStageLayout,
		stage_bounds: AABB,
		predictor_result: Dictionary,
		batch_size: int = RIGIDBODY_BATCH_SIZE
) -> Dictionary:
	var started := Time.get_ticks_msec()
	if tree == null or certification_root == null or cannon == null \
			or cannon.projectile_data == null or terrain_surface == null \
			or layout == null or not bool(predictor_result.get("valid", false)):
		return _failure(&"invalid_rigidbody_input", started)
	var witnesses: Array[AimTuple] = []
	for value in predictor_result.get("witnesses", []):
		witnesses.append(value as AimTuple)
	var expected_identities: Array[TrajectoryHitIdentity] = []
	for value in predictor_result.get("witness_identities", []):
		expected_identities.append(value as TrajectoryHitIdentity)
	var target_points: PackedVector3Array = predictor_result.get("target_points", PackedVector3Array())
	var expected_impacts: PackedVector3Array = predictor_result.get(
		"witness_impacts",
		PackedVector3Array()
	)
	if witnesses.is_empty() or expected_identities.size() != witnesses.size() \
			or expected_impacts.size() != witnesses.size() \
			or target_points.is_empty() or batch_size <= 0:
		return _failure(&"invalid_rigidbody_contract", started)

	var outcomes: Array[Dictionary] = []
	outcomes.resize(witnesses.size())
	var failure_diagnostics: Array[Dictionary] = []
	var physical_points := PackedVector3Array()
	physical_points.resize(witnesses.size())
	var physical_witness_valid := PackedByteArray()
	physical_witness_valid.resize(witnesses.size())
	physical_witness_valid.fill(0)
	var batch_start := 0
	while batch_start < witnesses.size():
		var batch_end := mini(batch_start + batch_size, witnesses.size())
		var pending: Dictionary = {}
		var projectiles: Array[PaintProjectile] = []
		for witness_index in range(batch_start, batch_end):
			var captured_index := witness_index
			var aim := witnesses[captured_index]
			var origin := cannon.get_launch_origin_for(aim.yaw_degrees, aim.elevation_degrees)
			var velocity := CannonBallistics.launch_velocity(
				cannon.projectile_data,
				aim.yaw_degrees,
				aim.elevation_degrees,
				float(aim.power_percent)
			)
			var projectile := PaintProjectile.new()
			projectile.name = "ReachabilityProjectile%06d" % captured_index
			projectile.configure(
				cannon.projectile_data,
				stage_bounds,
				terrain_surface,
				velocity,
				0,
				DEFAULT_PAINT_SURFACE_TUNING,
				captured_index
			)
			projectile.position = certification_root.to_local(origin)
			projectile.linear_velocity = velocity
			projectile.contact_reported.connect(func(
					observed_projectile: PaintProjectile,
					contact: ProjectileContact
			) -> void:
				var existing_outcome = outcomes[captured_index]
				if contact.is_first_contact and existing_outcome != null \
						and (existing_outcome as Dictionary).has("identity"):
					var duplicate_outcome := existing_outcome as Dictionary
					duplicate_outcome["duplicate"] = true
					outcomes[captured_index] = duplicate_outcome
				if not pending.has(captured_index):
					return
				var identity := _runtime_contact_identity(contact, terrain_surface)
				outcomes[captured_index] = {
					"identity": identity,
					"point": contact.world_position,
					"tick": contact.physics_tick,
					"first": contact.is_first_contact,
					"duplicate": false,
				}
				pending.erase(captured_index)
				observed_projectile.deactivate(&"reachability_first_contact")
			)
			projectile.stopped.connect(func(
					_observed_projectile: PaintProjectile,
					reason: StringName
			) -> void:
				if pending.has(captured_index):
					outcomes[captured_index] = {"stopped": reason}
					pending.erase(captured_index)
			)
			certification_root.add_child(projectile)
			projectiles.append(projectile)
			pending[captured_index] = true

		var remaining_ticks := TrajectoryPredictor.MAXIMUM_STEPS
		while not pending.is_empty() and remaining_ticks > 0:
			await tree.physics_frame
			remaining_ticks -= 1
		for witness_index in pending.keys():
			outcomes[int(witness_index)] = {"stopped": &"timeout"}
		for projectile in projectiles:
			if is_instance_valid(projectile):
				projectile.deactivate(&"reachability_batch_cleanup")
		await tree.physics_frame
		batch_start = batch_end

	for witness_index in range(witnesses.size()):
		var outcome_value = outcomes[witness_index]
		if outcome_value == null or not (outcome_value as Dictionary).has("identity"):
			failure_diagnostics.append({
				"witness_index": witness_index,
				"aim": witnesses[witness_index].stable_key(),
				"reason": (outcome_value as Dictionary).get("stopped", &"missing_contact") if outcome_value != null else &"missing_outcome",
			})
			continue
		var outcome := outcome_value as Dictionary
		if not bool(outcome.get("first", false)) or bool(outcome.get("duplicate", false)):
			failure_diagnostics.append({
				"witness_index": witness_index,
				"aim": witnesses[witness_index].stable_key(),
				"reason": &"duplicate_or_nonfirst_contact",
			})
			continue
		var actual_identity: TrajectoryHitIdentity = outcome.identity
		var expected_identity := expected_identities[witness_index]
		if actual_identity == null or expected_identity == null \
				or not outcome.point.is_finite() \
				or not _rigidbody_identity_compatible(
					actual_identity,
					expected_identity,
					expected_impacts[witness_index],
					outcome.point
				):
			failure_diagnostics.append({
				"witness_index": witness_index,
				"aim": witnesses[witness_index].stable_key(),
				"reason": &"wrong_surface_identity",
				"expected": expected_identity.stable_key() if expected_identity != null else &"",
				"actual": actual_identity.stable_key() if actual_identity != null else &"",
			})
			continue
		physical_points[witness_index] = outcome.point
		physical_witness_valid[witness_index] = 1

	# Predictor assignments are only nominations. Reconcile the complete target
	# table against actual rigid-body contact points so a nearby physical witness
	# can cover a texel when the first analytical witness drifted at a facet edge.
	var reconciled_assignments := PackedInt32Array()
	var reconciled_distance_margins := PackedFloat32Array()
	reconciled_distance_margins.resize(witnesses.size())
	var physical_target_tolerance := maxf(
		TARGET_DISTANCE_TOLERANCE,
		cannon.projectile_data.radius + RIGIDBODY_TARGET_RADIUS_CLEARANCE
	)
	var physical_bucket_radius := ceili(
		physical_target_tolerance / WITNESS_SPATIAL_BUCKET_METERS
	)
	var physical_witness_buckets: Dictionary = {}
	for witness_index in range(witnesses.size()):
		reconciled_distance_margins[witness_index] = physical_target_tolerance
		if physical_witness_valid[witness_index] == 1:
			var physical_bucket := _spatial_bucket_for(physical_points[witness_index])
			var physical_indices: PackedInt32Array = physical_witness_buckets.get(
				physical_bucket,
				PackedInt32Array()
			)
			physical_indices.append(witness_index)
			physical_witness_buckets[physical_bucket] = physical_indices
	for target_index in range(target_points.size()):
		var best_witness_index := -1
		var best_distance := INF
		var target_bucket := _spatial_bucket_for(target_points[target_index])
		# Expand the bucket neighborhood from the current physical tolerance so a
		# larger projectile cannot hide a valid nearby witness across a bucket edge.
		for bucket_x in range(
			target_bucket.x - physical_bucket_radius,
			target_bucket.x + physical_bucket_radius + 1
		):
			for bucket_z in range(
				target_bucket.y - physical_bucket_radius,
				target_bucket.y + physical_bucket_radius + 1
			):
				var nearby_indices: PackedInt32Array = physical_witness_buckets.get(
					Vector2i(bucket_x, bucket_z),
					PackedInt32Array()
				)
				for witness_index in nearby_indices:
					var distance := physical_points[witness_index].distance_to(target_points[target_index])
					if distance <= physical_target_tolerance \
							and (distance < best_distance \
							or (is_equal_approx(distance, best_distance) \
							and (best_witness_index < 0 or witness_index < best_witness_index))):
						best_witness_index = witness_index
						best_distance = distance
		if best_witness_index < 0:
			var nearest_physical_distance := INF
			var nearest_physical_point := Vector3.INF
			for witness_index in range(witnesses.size()):
				if physical_witness_valid[witness_index] != 1:
					continue
				var physical_distance := physical_points[witness_index].distance_to(
					target_points[target_index]
				)
				if physical_distance < nearest_physical_distance:
					nearest_physical_distance = physical_distance
					nearest_physical_point = physical_points[witness_index]
			failure_diagnostics.append({
				"target_index": target_index,
				"reason": &"physical_target_uncovered",
				"distance": nearest_physical_distance,
				"tolerance": physical_target_tolerance,
				"physical_point": nearest_physical_point,
				"target_point": target_points[target_index],
			})
			reconciled_assignments.append(0)
			continue
		reconciled_assignments.append(best_witness_index)
		reconciled_distance_margins[best_witness_index] = minf(
			reconciled_distance_margins[best_witness_index],
			physical_target_tolerance - best_distance
		)

	var valid := failure_diagnostics.is_empty()
	return {
		"valid": valid,
		"rejection": &"" if valid else &"rigidbody_parity",
		"failure_diagnostics": failure_diagnostics,
		"outcomes": outcomes,
		"physical_witness_impacts": physical_points,
		"target_witness_indices": reconciled_assignments,
		"minimum_distance_margins": reconciled_distance_margins,
		"rigidbody_reachability_checksum": _rigidbody_checksum(
			witnesses,
			outcomes
		) if valid else 0,
		"witness_count": witnesses.size(),
		"batch_count": ceili(float(witnesses.size()) / float(batch_size)),
		"elapsed_ms": Time.get_ticks_msec() - started,
	}




## MVP-only bounded entry point. It solves exactly one supplied target sample;
## it does not assign or claim reachability for any other target texel.
static func solve_one_target(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		layout: GeneratedStageLayout,
		stage_bounds: AABB,
		target_world_point: Vector3,
		target_world_normal: Vector3,
		target_sample: Dictionary,
		prefer_short_flight: bool = false
) -> Dictionary:
	if space_state == null or cannon == null or layout == null \
			or not target_world_point.is_finite() \
			or not target_world_normal.is_finite() or target_sample.is_empty():
		return {"valid": false, "rejection": &"invalid_single_target_input"}
	return _solve_target(
		space_state,
		cannon,
		layout,
		stage_bounds,
		target_world_point,
		target_world_normal,
		target_sample,
		{},
		_build_solver_cache(cannon),
		TARGET_DISTANCE_TOLERANCE,
		prefer_short_flight
	)


static func _solve_target(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		layout: GeneratedStageLayout,
		stage_bounds: AABB,
		target_world_point: Vector3,
		target_world_normal: Vector3,
		target_sample: Dictionary,
		prediction_cache: Dictionary,
		solver_cache: Dictionary = {},
		maximum_distance: float = TARGET_DISTANCE_TOLERANCE,
		prefer_short_flight: bool = false
) -> Dictionary:
	if solver_cache.is_empty():
		solver_cache = _build_solver_cache(cannon)
	if solver_cache.is_empty():
		return {"valid": false, "rejection": &"invalid_ballistic_cache"}
	var nominations: Array[Dictionary] = []
	var nomination_by_key: Dictionary = {}
	# At 90 degrees the barrel's muzzle offset has no XZ component, exposing the
	# horizontal yaw pivot without depending on CannonController's private nodes.
	# Every legal muzzle offset is collinear with its yaw direction, so bearing
	# from this pivot is the exact nearest-yaw nomination reference.
	var reference_origin := cannon.get_launch_origin_for(0.0, 90.0)
	var reference_delta := Vector2(
		target_world_point.x - reference_origin.x,
		target_world_point.z - reference_origin.z
	)
	# Positive yaw is the aiming camera's screen-right direction and therefore
	# maps toward positive world X for the authored cannon/camera contract.
	var bearing := rad_to_deg(atan2(reference_delta.x, -reference_delta.y))
	var nearest_yaw := AimTuple.snap_angle(bearing)
	var desired_center := target_world_point \
			+ target_world_normal * cannon.projectile_data.radius
	for yaw in [nearest_yaw, nearest_yaw - 0.1, nearest_yaw + 0.1]:
		if yaw < AimTuple.MINIMUM_YAW_DEGREES or yaw > AimTuple.MAXIMUM_YAW_DEGREES:
			continue
		var horizontal_direction := Vector2(
			sin(deg_to_rad(yaw)),
			-cos(deg_to_rad(yaw))
		).normalized()
		var integer_origins := PackedVector3Array()
		for integer_elevation in range(
			ceili(AimTuple.MINIMUM_ELEVATION_DEGREES),
			floori(AimTuple.MAXIMUM_ELEVATION_DEGREES) + 1
		):
			integer_origins.append(cannon.get_launch_origin_for(yaw, float(integer_elevation)))
		for power in range(AimTuple.MINIMUM_POWER_PERCENT, AimTuple.MAXIMUM_POWER_PERCENT + 1):
			var has_previous := false
			var previous_height_error := 0.0
			var speed: float = solver_cache.speeds[power]
			for integer_elevation in range(
				ceili(AimTuple.MINIMUM_ELEVATION_DEGREES),
				floori(AimTuple.MAXIMUM_ELEVATION_DEGREES) + 1
			):
				var elevation_index := integer_elevation - ceili(AimTuple.MINIMUM_ELEVATION_DEGREES)
				var current := _collision_free_endpoint_values(
					integer_origins[elevation_index],
					horizontal_direction,
					speed * float(solver_cache.cosines[elevation_index]),
					speed * float(solver_cache.sines[elevation_index]),
					target_world_point,
					desired_center,
					solver_cache
				)
				if not is_finite(current.x):
					has_previous = false
					continue
				if is_zero_approx(current.x):
					_append_elevation_neighborhood(
						nominations,
						nomination_by_key,
						cannon,
						yaw,
						float(integer_elevation),
						power,
						target_world_point,
						target_world_normal,
						solver_cache
					)
				elif has_previous and signf(previous_height_error) != signf(current.x):
					var root_elevation := _bisect_elevation(
						cannon,
						yaw,
						float(integer_elevation - 1),
						float(integer_elevation),
						power,
						target_world_point,
						target_world_normal,
						solver_cache
					)
					_append_elevation_neighborhood(
						nominations,
						nomination_by_key,
						cannon,
						yaw,
						root_elevation,
						power,
						target_world_point,
						target_world_normal,
						solver_cache
					)
				has_previous = true
				previous_height_error = current.x

	nominations.sort_custom(
		_short_flight_nomination_precedes if prefer_short_flight else _nomination_precedes
	)
	var predictor_calls := 0
	var diagnostics := _new_prediction_diagnostics()
	for nomination in nominations:
		var aim: AimTuple = nomination.aim
		var key := aim.stable_key()
		var prediction: TrajectoryPrediction = prediction_cache.get(key)
		if prediction == null:
			prediction = TrajectoryPredictor.predict_motion(
				space_state,
				cannon.get_launch_origin_for(aim.yaw_degrees, aim.elevation_degrees),
				CannonBallistics.launch_velocity(
					cannon.projectile_data,
					aim.yaw_degrees,
					aim.elevation_degrees,
					float(aim.power_percent)
				),
				cannon.projectile_data.radius,
				cannon.projectile_data.linear_damp,
				stage_bounds,
				TrajectoryPredictor.COLLISION_MASK,
				false
			)
			prediction_cache[key] = prediction
			predictor_calls += 1
		_record_prediction_diagnostic(
			diagnostics,
			prediction,
			target_world_point,
			target_sample,
			aim
		)
		if not _prediction_witnesses_target(
				prediction,
				target_world_point,
				target_sample,
				maximum_distance
			):
			continue
		return {
			"valid": true,
			"aim": aim,
			"prediction": prediction,
			"range_margin": maxf(
				MAXIMUM_PERPENDICULAR_MISS - float(nomination.perpendicular_miss),
				0.0
			),
			"candidate_count": nominations.size(),
			"predictor_calls": predictor_calls,
		}
	return {
		"valid": false,
		"candidate_count": nominations.size(),
		"predictor_calls": predictor_calls,
		"diagnostics": _finalize_prediction_diagnostics(diagnostics),
	}


static func _collision_free_endpoint_error(
		cannon: CannonController,
		yaw_degrees: float,
		elevation_degrees: float,
		power_percent: int,
		target_world_point: Vector3,
		target_world_normal: Vector3,
		solver_cache: Dictionary = {}
) -> Dictionary:
	if solver_cache.is_empty():
		solver_cache = _build_solver_cache(cannon)
	if solver_cache.is_empty():
		return {}
	var origin := cannon.get_launch_origin_for(yaw_degrees, elevation_degrees)
	var direction := CannonBallistics.launch_direction(yaw_degrees, elevation_degrees)
	var horizontal_direction := Vector2(direction.x, direction.z).normalized()
	if horizontal_direction.is_zero_approx():
		return {}
	var delta_xz := Vector2(
		target_world_point.x - origin.x,
		target_world_point.z - origin.z
	)
	var projected_range := delta_xz.dot(horizontal_direction)
	var perpendicular_miss := absf(delta_xz.cross(horizontal_direction))
	if projected_range <= 0.0 or perpendicular_miss > MAXIMUM_PERPENDICULAR_MISS:
		return {}
	var speed := cannon.projectile_data.launch_speed(float(power_percent))
	var horizontal_speed := speed * cos(deg_to_rad(elevation_degrees))
	if horizontal_speed <= 0.000001:
		return {}
	var vertical_speed := speed * sin(deg_to_rad(elevation_degrees))
	return _collision_free_endpoint_error_from_components(
		origin,
		horizontal_direction,
		horizontal_speed,
		vertical_speed,
		target_world_point,
		target_world_normal,
		cannon.projectile_data.radius,
		solver_cache
	)


static func _collision_free_endpoint_error_from_components(
		origin: Vector3,
		horizontal_direction: Vector2,
		horizontal_speed: float,
		vertical_speed: float,
		target_world_point: Vector3,
		target_world_normal: Vector3,
		projectile_radius: float,
		solver_cache: Dictionary
) -> Dictionary:
	var desired_center := target_world_point + target_world_normal * projectile_radius
	var values := _collision_free_endpoint_values(
		origin,
		horizontal_direction,
		horizontal_speed,
		vertical_speed,
		target_world_point,
		desired_center,
		solver_cache
	)
	if not is_finite(values.x):
		return {}
	return {
		"height_error": values.x,
		"endpoint_error": values.y,
		"perpendicular_miss": values.z,
		"projected_range": values.w,
	}


static func _collision_free_endpoint_values(
		origin: Vector3,
		horizontal_direction: Vector2,
		horizontal_speed: float,
		vertical_speed: float,
		target_world_point: Vector3,
		desired_center: Vector3,
		solver_cache: Dictionary
) -> Vector4:
	var delta_xz := Vector2(
		target_world_point.x - origin.x,
		target_world_point.z - origin.z
	)
	var projected_range := delta_xz.dot(horizontal_direction)
	var perpendicular_miss := absf(delta_xz.cross(horizontal_direction))
	if projected_range <= 0.0 or perpendicular_miss > MAXIMUM_PERPENDICULAR_MISS \
			or horizontal_speed <= 0.000001:
		return Vector4(INF, INF, INF, INF)
	var relative := CannonBallistics.damped_position_at_horizontal_range(
		horizontal_speed,
		vertical_speed,
		projected_range,
		solver_cache
	)
	if relative == Vector2.INF:
		return Vector4(INF, INF, INF, INF)
	var endpoint := origin + Vector3(
		horizontal_direction.x * relative.x,
		relative.y,
		horizontal_direction.y * relative.x
	)
	return Vector4(
		endpoint.y - desired_center.y,
		endpoint.distance_to(desired_center),
		perpendicular_miss,
		projected_range
	)


static func _build_solver_cache(cannon: CannonController) -> Dictionary:
	var step := TrajectoryPredictor.PHYSICS_STEP
	var gravity_magnitude := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var gravity_direction := Vector3(ProjectSettings.get_setting(
		"physics/3d/default_gravity_vector",
		Vector3.DOWN
	)).normalized()
	var gravity_y := gravity_direction.y * gravity_magnitude
	var cache := CannonBallistics.build_damped_motion_cache(
		cannon.projectile_data.linear_damp,
		gravity_y,
		step,
		TrajectoryPredictor.MAXIMUM_STEPS
	)
	if cache.is_empty():
		return {}
	var speeds := PackedFloat32Array()
	speeds.resize(AimTuple.MAXIMUM_POWER_PERCENT + 1)
	for power in range(AimTuple.MAXIMUM_POWER_PERCENT + 1):
		speeds[power] = cannon.projectile_data.launch_speed(float(power))
	var sines := PackedFloat32Array()
	var cosines := PackedFloat32Array()
	var elevation_count := floori(AimTuple.MAXIMUM_ELEVATION_DEGREES) \
			- ceili(AimTuple.MINIMUM_ELEVATION_DEGREES) + 1
	sines.resize(elevation_count)
	cosines.resize(elevation_count)
	for index in range(elevation_count):
		var elevation := float(ceili(AimTuple.MINIMUM_ELEVATION_DEGREES) + index)
		sines[index] = sin(deg_to_rad(elevation))
		cosines[index] = cos(deg_to_rad(elevation))
	cache["speeds"] = speeds
	cache["sines"] = sines
	cache["cosines"] = cosines
	return cache


static func _bisect_elevation(
		cannon: CannonController,
		yaw_degrees: float,
		lower_elevation: float,
		upper_elevation: float,
		power_percent: int,
		target_world_point: Vector3,
		target_world_normal: Vector3,
		solver_cache: Dictionary
) -> float:
	var lower := lower_elevation
	var upper := upper_elevation
	var lower_result := _collision_free_endpoint_error(
		cannon, yaw_degrees, lower, power_percent, target_world_point, target_world_normal,
		solver_cache
	)
	for _iteration in range(ELEVATION_BISECTION_ITERATIONS):
		var middle := (lower + upper) * 0.5
		var middle_result := _collision_free_endpoint_error(
			cannon, yaw_degrees, middle, power_percent, target_world_point, target_world_normal,
			solver_cache
		)
		if middle_result.is_empty():
			break
		if signf(float(lower_result.height_error)) == signf(float(middle_result.height_error)):
			lower = middle
			lower_result = middle_result
		else:
			upper = middle
	return (lower + upper) * 0.5


static func _append_elevation_neighborhood(
		nominations: Array[Dictionary],
		nomination_by_key: Dictionary,
		cannon: CannonController,
		yaw_degrees: float,
		root_elevation: float,
		power_percent: int,
		target_world_point: Vector3,
		target_world_normal: Vector3,
		solver_cache: Dictionary
) -> void:
	var nearest := AimTuple.snap_angle(root_elevation)
	for elevation in [nearest, nearest - 0.1, nearest + 0.1]:
		var aim := AimTuple.canonicalize(yaw_degrees, elevation, power_percent)
		if aim == null or not is_equal_approx(aim.elevation_degrees, elevation):
			continue
		var endpoint := _collision_free_endpoint_error(
			cannon,
			aim.yaw_degrees,
			aim.elevation_degrees,
			int(aim.power_percent),
			target_world_point,
			target_world_normal,
			solver_cache
		)
		if endpoint.is_empty():
			continue
		var key := aim.stable_key()
		var nomination := {
			"aim": aim,
			"endpoint_error": float(endpoint.endpoint_error),
			"perpendicular_miss": float(endpoint.perpendicular_miss),
			"flight_duration": _damped_duration_at_horizontal_range_cached(
				float(solver_cache.speeds[int(aim.power_percent)]) * cos(deg_to_rad(aim.elevation_degrees)),
				float(endpoint.projected_range),
				solver_cache
			),
		}
		if not nomination_by_key.has(key):
			nomination_by_key[key] = nominations.size()
			nominations.append(nomination)
		elif float(nomination.endpoint_error) < float(
			nominations[int(nomination_by_key[key])].endpoint_error
		):
			nominations[int(nomination_by_key[key])] = nomination


static func _nomination_precedes(first: Dictionary, second: Dictionary) -> bool:
	var first_aim: AimTuple = first.aim
	var second_aim: AimTuple = second.aim
	var first_key := [
		float(first.endpoint_error),
		absf(first_aim.yaw_degrees),
		first_aim.elevation_degrees,
		first_aim.power_percent,
		first_aim.yaw_degrees,
	]
	var second_key := [
		float(second.endpoint_error),
		absf(second_aim.yaw_degrees),
		second_aim.elevation_degrees,
		second_aim.power_percent,
		second_aim.yaw_degrees,
	]
	for index in range(first_key.size()):
		if first_key[index] < second_key[index]:
			return true
		if first_key[index] > second_key[index]:
			return false
	return false


static func _short_flight_nomination_precedes(first: Dictionary, second: Dictionary) -> bool:
	var first_duration := float(first.get("flight_duration", INF))
	var second_duration := float(second.get("flight_duration", INF))
	if not is_equal_approx(first_duration, second_duration):
		return first_duration < second_duration
	return _nomination_precedes(first, second)


static func _damped_duration_at_horizontal_range_cached(
		horizontal_speed: float,
		projected_range: float,
		solver_cache: Dictionary
) -> float:
	if horizontal_speed <= 0.000001 or projected_range <= 0.0:
		return INF
	var step: float = solver_cache.step
	var damping: float = solver_cache.damping
	if damping <= 0.0:
		return INF
	var step_count := 0
	if is_equal_approx(damping, 1.0):
		step_count = ceili(projected_range / maxf(horizontal_speed * step, 0.000001))
	else:
		var asymptotic_range := horizontal_speed * float(solver_cache.asymptotic_factor)
		if projected_range >= asymptotic_range:
			return INF
		var remaining_ratio := 1.0 - projected_range / asymptotic_range
		step_count = ceili(log(remaining_ratio) / float(solver_cache.log_damping))
	return float(clampi(step_count, 1, TrajectoryPredictor.MAXIMUM_STEPS)) * step


static func _prediction_witnesses_target(
	prediction: TrajectoryPrediction,
	target_world_point: Vector3,
	target_sample: Dictionary,
	maximum_distance: float = TARGET_DISTANCE_TOLERANCE
) -> bool:
	if prediction == null or prediction.kind != TrajectoryPrediction.Kind.COLLISION \
			or prediction.hit_identity == null:
		return false
	var identity := prediction.hit_identity
	return identity.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			and not target_sample.is_empty() \
			and prediction.collision_contact_point().distance_to(target_world_point) \
					<= maximum_distance


static func _new_prediction_diagnostics() -> Dictionary:
	return {
		"kind_counts": {
			"collision": 0,
			"bounds_exit": 0,
			"timeout": 0,
			"missing": 0,
		},
		"owner_shape_counts": {},
		"terrain_address_counts": {
			"same_triangle": 0,
			"same_cell_wrong_triangle": 0,
			"wrong_cell": 0,
			"invalid_identity": 0,
		},
		"minimum_same_triangle_distance": INF,
		"minimum_terrain_top_distance": INF,
		"nearest_same_triangle_aim": &"",
		"nearest_terrain_top_aim": &"",
	}


static func _record_prediction_diagnostic(
		diagnostics: Dictionary,
		prediction: TrajectoryPrediction,
		target_world_point: Vector3,
		target_sample: Dictionary,
		aim: AimTuple
) -> void:
	var kind_counts: Dictionary = diagnostics.kind_counts
	if prediction == null:
		kind_counts["missing"] = int(kind_counts.missing) + 1
		return
	match prediction.kind:
		TrajectoryPrediction.Kind.COLLISION:
			kind_counts["collision"] = int(kind_counts.collision) + 1
		TrajectoryPrediction.Kind.BOUNDS_EXIT:
			kind_counts["bounds_exit"] = int(kind_counts.bounds_exit) + 1
		TrajectoryPrediction.Kind.TIMEOUT:
			kind_counts["timeout"] = int(kind_counts.timeout) + 1
	if prediction.kind != TrajectoryPrediction.Kind.COLLISION:
		return
	var identity := prediction.hit_identity
	var owner_shape_counts: Dictionary = diagnostics.owner_shape_counts
	if identity == null:
		owner_shape_counts["<invalid>"] = int(owner_shape_counts.get("<invalid>", 0)) + 1
		return
	var owner_shape_key := "%s|%s" % [identity.contact_owner_id, identity.contact_shape_id]
	owner_shape_counts[owner_shape_key] = int(owner_shape_counts.get(owner_shape_key, 0)) + 1
	if identity.contact_owner_id != TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
		return
	var distance := prediction.collision_contact_point().distance_to(target_world_point)
	if distance < float(diagnostics.minimum_terrain_top_distance):
		diagnostics.minimum_terrain_top_distance = distance
		diagnostics.nearest_terrain_top_aim = aim.stable_key()
	var address_counts: Dictionary = diagnostics.terrain_address_counts
	if identity.terrain_cell != target_sample.cell:
		address_counts["wrong_cell"] = int(address_counts.wrong_cell) + 1
		return
	if identity.terrain_triangle != int(target_sample.triangle):
		address_counts["same_cell_wrong_triangle"] = int(
			address_counts.same_cell_wrong_triangle
		) + 1
		return
	address_counts["same_triangle"] = int(address_counts.same_triangle) + 1
	if distance < float(diagnostics.minimum_same_triangle_distance):
		diagnostics.minimum_same_triangle_distance = distance
		diagnostics.nearest_same_triangle_aim = aim.stable_key()


static func _finalize_prediction_diagnostics(diagnostics: Dictionary) -> Dictionary:
	if not is_finite(float(diagnostics.minimum_same_triangle_distance)):
		diagnostics.minimum_same_triangle_distance = -1.0
	if not is_finite(float(diagnostics.minimum_terrain_top_distance)):
		diagnostics.minimum_terrain_top_distance = -1.0
	return diagnostics




static func _rigidbody_identity_compatible(
		actual: TrajectoryHitIdentity,
		expected: TrajectoryHitIdentity,
		expected_endpoint: Vector3,
		actual_point: Vector3
) -> bool:
	if actual == null or expected == null or not actual.is_valid() or not expected.is_valid():
		return false
	if actual.contact_owner_id != expected.contact_owner_id \
			or actual.contact_shape_id != expected.contact_shape_id \
			or actual.body_shape_index != expected.body_shape_index:
		return false
	if actual.contact_owner_id != TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
		return actual.has_same_surface_address(expected)
	# A rigid sphere can cross a faceted edge between physics ticks. The owner,
	# shape, and body-shape metadata prove it remained on the same top collider;
	# the endpoint/contact distance prevents a distant triangle from masquerading
	# as an adjacent facet.
	if actual.terrain_cell == expected.terrain_cell \
			and actual.terrain_triangle == expected.terrain_triangle:
		return true
	return expected_endpoint.is_finite() and actual_point.is_finite() \
			and actual_point.distance_to(expected_endpoint) \
			<= RIGIDBODY_IDENTITY_DISTANCE_TOLERANCE


static func _spatial_bucket_for(world_point: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_point.x / WITNESS_SPATIAL_BUCKET_METERS),
		floori(world_point.z / WITNESS_SPATIAL_BUCKET_METERS)
	)


static func _range_margin_for_target(
		cannon: CannonController,
		aim: AimTuple,
		target_world_point: Vector3
) -> float:
	var origin := cannon.get_launch_origin_for(aim.yaw_degrees, aim.elevation_degrees)
	var direction := CannonBallistics.launch_direction(aim.yaw_degrees, aim.elevation_degrees)
	var horizontal_direction := Vector2(direction.x, direction.z).normalized()
	var delta := Vector2(target_world_point.x - origin.x, target_world_point.z - origin.z)
	return maxf(MAXIMUM_PERPENDICULAR_MISS - absf(delta.cross(horizontal_direction)), 0.0)


static func _runtime_contact_identity(
		contact: ProjectileContact,
		terrain_surface: TerrainSurface
) -> TrajectoryHitIdentity:
	var collision_object := contact.collider as CollisionObject3D
	if collision_object == null:
		return null
	var owner_id := StringName(collision_object.get_meta(
		PlayBoundsSpec.CONTACT_OWNER_META,
		&""
	))
	var shape_owner_id := collision_object.shape_find_owner(contact.collider_shape_index)
	if shape_owner_id < 0:
		return null
	var shape_owner := collision_object.shape_owner_get_owner(shape_owner_id)
	if shape_owner == null:
		return null
	var shape_id := StringName(shape_owner.get_meta(PlayBoundsSpec.CONTACT_SHAPE_META, &""))
	if owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
		return terrain_surface.classify_top_physics_hit(
			contact.world_position,
			shape_id,
			contact.collider_shape_index
		)
	var identity := TrajectoryHitIdentity.new(
		owner_id,
		shape_id,
		contact.collider_shape_index
	)
	return identity if identity.is_valid() else null


static func _triangle_key(cell: Vector2i, triangle: int) -> int:
	return ((cell.y * StageGenerationContract.REQUIRED_CELL_COUNT.x + cell.x) * 2) + triangle


static func _prediction_checksum(
		witnesses: Array[AimTuple],
		identities: Array[TrajectoryHitIdentity],
		points: PackedVector3Array
) -> int:
	var hash := CHECKSUM_OFFSET
	for index in range(witnesses.size()):
		hash = _hash_int(hash, index)
		hash = _hash_aim(hash, witnesses[index])
		hash = _hash_identity(hash, identities[index])
		hash = _hash_point(hash, points[index])
	return hash


static func _rigidbody_checksum(
		witnesses: Array[AimTuple],
		outcomes: Array[Dictionary]
) -> int:
	var hash := CHECKSUM_OFFSET
	for index in range(witnesses.size()):
		var outcome: Dictionary = outcomes[index]
		hash = _hash_int(hash, index)
		hash = _hash_aim(hash, witnesses[index])
		hash = _hash_identity(hash, outcome.identity)
		hash = _hash_point(hash, outcome.point)
		hash = _hash_int(hash, int(outcome.tick))
	return hash


static func _hash_aim(hash: int, aim: AimTuple) -> int:
	hash = _hash_int(hash, roundi(aim.yaw_degrees * 10.0))
	hash = _hash_int(hash, roundi(aim.elevation_degrees * 10.0))
	return _hash_int(hash, int(aim.power_percent))


static func _hash_identity(hash: int, identity: TrajectoryHitIdentity) -> int:
	hash = _hash_string(hash, String(identity.contact_owner_id))
	hash = _hash_string(hash, String(identity.contact_shape_id))
	hash = _hash_int(hash, identity.body_shape_index)
	hash = _hash_int(hash, identity.terrain_cell.x)
	hash = _hash_int(hash, identity.terrain_cell.y)
	return _hash_int(hash, identity.terrain_triangle)


static func _hash_point(hash: int, point: Vector3) -> int:
	hash = _hash_int(hash, AimTuple._round_half_away_from_zero(point.x * 1000.0))
	hash = _hash_int(hash, AimTuple._round_half_away_from_zero(point.y * 1000.0))
	return _hash_int(hash, AimTuple._round_half_away_from_zero(point.z * 1000.0))


static func _hash_string(hash: int, value: String) -> int:
	var bytes := value.to_utf8_buffer()
	hash = _hash_int(hash, bytes.size())
	for byte in bytes:
		hash = hash ^ byte
		hash = int((hash * CHECKSUM_PRIME) & 0xffffffff)
	return hash


static func _hash_int(hash: int, value: int) -> int:
	for shift in [0, 8, 16, 24]:
		hash = hash ^ ((value >> shift) & 0xff)
		hash = int((hash * CHECKSUM_PRIME) & 0xffffffff)
	return hash




static func _failure(rejection: StringName, started: int) -> Dictionary:
	return {
		"valid": false,
		"rejection": rejection,
		"elapsed_ms": Time.get_ticks_msec() - started,
	}
