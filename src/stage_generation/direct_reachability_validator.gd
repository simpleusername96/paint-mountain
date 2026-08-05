class_name DirectReachabilityValidator
extends RefCounted

## Headless fairness proof for one materialized layout. Predictor witnesses are
## never exposed to gameplay; the serialized certificate keeps only canonical
## aim tuples, target assignments, margins, and deterministic checksums.

# A witness is accepted when its first top-surface contact lands inside the
# authoritative impact mark. The radius is intentionally the same 2.10 m
# value used by ProjectileData. Requiring the exact sampled triangle would
# reject legitimate contacts on adjacent facets even though the impact mark
# fully covers the scoreable texel.
const TARGET_DISTANCE_TOLERANCE := 2.10
const MAXIMUM_PERPENDICULAR_MISS := 1.02
const ELEVATION_SAMPLE_STEP_DEGREES := 1.0
const ELEVATION_BISECTION_ITERATIONS := 12
const RIGIDBODY_BATCH_SIZE := 128
const MAXIMUM_UNCOVERED_DIAGNOSTICS := 32
const WITNESS_SPATIAL_BUCKET_METERS := TARGET_DISTANCE_TOLERANCE
const CHECKSUM_OFFSET := 2166136261
const CHECKSUM_PRIME := 16777619
const DEFAULT_PAINT_SURFACE_TUNING := preload(
	"res://resources/paint/default_paint_surface_tuning.tres"
)


static func validate_predictor(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		terrain_surface: TerrainSurface,
		layout: GeneratedStageLayout,
		stage_bounds: AABB,
		maximum_uncovered_diagnostics: int = MAXIMUM_UNCOVERED_DIAGNOSTICS,
		progress_callback: Callable = Callable()
) -> Dictionary:
	var started := Time.get_ticks_msec()
	if space_state == null or cannon == null or cannon.projectile_data == null \
			or terrain_surface == null or layout == null or not layout.is_valid() \
			or not layout.has_valid_target_mask():
		return _failure(&"invalid_input", started)
	var mask := layout.target_mask
	var mask_size := StageGenerationContract.REQUIRED_MASK_SIZE
	if mask.size() != mask_size * mask_size:
		return _failure(&"invalid_target_mask_size", started)

	var witnesses: Array[AimTuple] = []
	var witness_impacts := PackedVector3Array()
	var witness_identities: Array[TrajectoryHitIdentity] = []
	var witness_range_margins := PackedFloat32Array()
	var witness_maximum_distances := PackedFloat32Array()
	var target_witness_indices := PackedInt32Array()
	var target_pixel_indices := PackedInt32Array()
	var target_points := PackedVector3Array()
	var witnesses_by_triangle: Dictionary = {}
	var witnesses_by_spatial_bucket: Dictionary = {}
	var prediction_cache: Dictionary = {}
	var solver_cache := _build_solver_cache(cannon)
	var predictor_call_count := 0
	var candidate_tuple_count := 0
	var reused_target_count := 0
	var uncovered_diagnostics: Array[Dictionary] = []
	var uncovered_count := 0
	var centroid_sum := Vector2.ZERO

	for pixel_y in range(mask_size):
		for pixel_x in range(mask_size):
			var pixel_index := pixel_y * mask_size + pixel_x
			if mask[pixel_index] < 128:
				continue
			var local_xz := _pixel_center_local(Vector2i(pixel_x, pixel_y), layout.local_bounds, mask_size)
			var sample := layout.top_topology.surface_sample_at_local(local_xz.x, local_xz.y, false)
			if sample.is_empty():
				return _failure(&"target_surface_sample", started)
			var target_world_point: Vector3 = terrain_surface.to_global(sample.point as Vector3)
			var target_world_normal: Vector3 = (
				terrain_surface.global_transform.basis.inverse().transposed() * (sample.normal as Vector3)
			).normalized()
			centroid_sum += Vector2(target_world_point.x, target_world_point.z)
			target_pixel_indices.append(pixel_index)
			target_points.append(target_world_point)
			if progress_callback.is_valid() and target_points.size() % 512 == 0:
				progress_callback.call({
					"visited_target_count": target_points.size(),
					"witness_count": witnesses.size(),
					"reused_target_count": reused_target_count,
					"predictor_call_count": predictor_call_count,
					"candidate_tuple_count": candidate_tuple_count,
					"elapsed_ms": Time.get_ticks_msec() - started,
				})

			var triangle_key := _triangle_key(sample.cell, int(sample.triangle))
			var reused_index := _nearest_reusable_witness(
				witnesses_by_triangle.get(triangle_key, PackedInt32Array()),
				witness_impacts,
				target_world_point
			)
			if reused_index < 0:
				reused_index = _nearest_spatial_reusable_witness(
					witnesses_by_spatial_bucket,
					witness_impacts,
					target_world_point
				)
			if reused_index >= 0:
				var reused_distance := witness_impacts[reused_index].distance_to(target_world_point)
				witness_maximum_distances[reused_index] = maxf(
					witness_maximum_distances[reused_index],
					reused_distance
				)
				witness_range_margins[reused_index] = minf(
					witness_range_margins[reused_index],
					_range_margin_for_target(cannon, witnesses[reused_index], target_world_point)
				)
				target_witness_indices.append(reused_index)
				reused_target_count += 1
				continue

			var solved := _solve_target(
				space_state,
				cannon,
				layout,
				stage_bounds,
				target_world_point,
				target_world_normal,
				sample,
				prediction_cache,
				solver_cache
			)
			predictor_call_count += int(solved.get("predictor_calls", 0))
			candidate_tuple_count += int(solved.get("candidate_count", 0))
			if not bool(solved.get("valid", false)):
				uncovered_count += 1
				if uncovered_diagnostics.size() < maximum_uncovered_diagnostics:
					uncovered_diagnostics.append({
						"pixel": Vector2i(pixel_x, pixel_y),
						"pixel_index": pixel_index,
						"local_xz": local_xz,
						"world_point": target_world_point,
						"cell": sample.cell,
						"triangle": int(sample.triangle),
						"candidate_count": int(solved.get("candidate_count", 0)),
						"predictor_calls": int(solved.get("predictor_calls", 0)),
					})
				# One uncovered target rejects the layout. Continue only long enough to
				# provide bounded diagnostics instead of spending hours on a failed seed.
				if uncovered_count >= maxi(maximum_uncovered_diagnostics, 1):
					return _uncovered_failure(
						started,
						uncovered_count,
						uncovered_diagnostics,
						target_pixel_indices.size(),
						predictor_call_count,
						candidate_tuple_count
					)
				continue

			var witness: AimTuple = solved.aim
			var prediction: TrajectoryPrediction = solved.prediction
			var witness_index := witnesses.size()
			witnesses.append(witness)
			witness_impacts.append(prediction.endpoint)
			witness_identities.append(prediction.hit_identity)
			witness_range_margins.append(float(solved.range_margin))
			witness_maximum_distances.append(prediction.endpoint.distance_to(target_world_point))
			target_witness_indices.append(witness_index)
			var triangle_witnesses: PackedInt32Array = witnesses_by_triangle.get(
				triangle_key,
				PackedInt32Array()
			)
			triangle_witnesses.append(witness_index)
			witnesses_by_triangle[triangle_key] = triangle_witnesses
			_register_spatial_witness(
				witnesses_by_spatial_bucket,
				prediction.endpoint,
				witness_index
			)

	if uncovered_count > 0:
		return _uncovered_failure(
			started,
			uncovered_count,
			uncovered_diagnostics,
			target_pixel_indices.size(),
			predictor_call_count,
			candidate_tuple_count
		)
	if target_points.is_empty() or witnesses.is_empty() \
			or target_witness_indices.size() != target_points.size():
		return _failure(&"empty_reachability_proof", started)

	var distance_margins := PackedFloat32Array()
	for maximum_distance in witness_maximum_distances:
		distance_margins.append(maxf(TARGET_DISTANCE_TOLERANCE - maximum_distance, 0.0))
	var centroid := centroid_sum / float(target_points.size())
	var default_index := select_witness_index(
		witnesses,
		witness_impacts,
		centroid
	)
	if default_index < 0 or Vector2(
		witness_impacts[default_index].x,
		witness_impacts[default_index].z
	).distance_to(centroid) > 8.0:
		return _failure(&"default_aim_outside_centroid_gate", started)

	return {
		"valid": true,
		"rejection": &"",
		"target_count": target_points.size(),
		"visited_target_count": target_points.size(),
		"uncovered_count": 0,
		"uncovered_diagnostics": [],
		"witnesses": witnesses,
		"witness_impacts": witness_impacts,
		"witness_identities": witness_identities,
		"target_witness_indices": target_witness_indices,
		"target_pixel_indices": target_pixel_indices,
		"target_points": target_points,
		"minimum_distance_margins": distance_margins,
		"minimum_range_margins": witness_range_margins,
		"default_witness_index": default_index,
		"target_centroid_xz": centroid,
		"reachable_target_checksum": layout.reachable_target_checksum(
			target_witness_indices
		),
		"predictor_reachability_checksum": _prediction_checksum(
			witnesses,
			witness_identities,
			witness_impacts
		),
		"predictor_call_count": predictor_call_count,
		"candidate_tuple_count": candidate_tuple_count,
		"reused_target_count": reused_target_count,
		"elapsed_ms": Time.get_ticks_msec() - started,
	}


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
	for height in layout.heights:
		maximum_height = maxf(maximum_height, height)
	var best: Dictionary = {}
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
			summit
		)
		if not bool(solved.get("valid", false)):
			continue
		var prediction := solved.prediction as TrajectoryPrediction
		var world_offset_y := world_point.y - float(summit.point.y)
		var height_margin := maxf(
			(world_offset_y + maximum_height) - prediction.endpoint.y,
			0.0
		)
		if best.is_empty() or height_margin < float(best.height_margin):
			best = {
				"aim": solved.aim,
				"prediction": prediction,
				"world_point": world_point,
				"height_margin": height_margin,
				"range_margin": float(solved.get("range_margin", 0.0)),
			}
	if best.is_empty():
		return {"valid": false, "rejection": &"summit_unreachable"}
	var minimum_height_margin := float(best.height_margin)
	if minimum_height_margin > 1.0:
		return {
			"valid": false,
			"rejection": &"summit_contact_below_global_max",
			"minimum_height_margin": minimum_height_margin,
		}
	witnesses.append(best.aim as AimTuple)
	var best_prediction: TrajectoryPrediction = best.prediction
	witness_impacts.append(best_prediction.endpoint)
	witness_identities.append(best_prediction.hit_identity)
	target_points.append(best.world_point)
	target_witness_indices.append(0)
	distance_margins.append(maxf(
		TARGET_DISTANCE_TOLERANCE - best_prediction.endpoint.distance_to(best.world_point),
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
	var target_assignments: PackedInt32Array = predictor_result.get(
		"target_witness_indices",
		PackedInt32Array()
	)
	var target_points: PackedVector3Array = predictor_result.get("target_points", PackedVector3Array())
	if witnesses.is_empty() or expected_identities.size() != witnesses.size() \
			or target_assignments.size() != target_points.size() or batch_size <= 0:
		return _failure(&"invalid_rigidbody_contract", started)

	var assigned_targets: Array[PackedInt32Array] = []
	assigned_targets.resize(witnesses.size())
	for witness_index in range(witnesses.size()):
		assigned_targets[witness_index] = PackedInt32Array()
	for target_index in range(target_assignments.size()):
		assigned_targets[target_assignments[target_index]].append(target_index)

	var outcomes: Array[Dictionary] = []
	outcomes.resize(witnesses.size())
	var failure_diagnostics: Array[Dictionary] = []
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
				or not actual_identity.has_same_surface_address(expected_identity):
			failure_diagnostics.append({
				"witness_index": witness_index,
				"aim": witnesses[witness_index].stable_key(),
				"reason": &"wrong_surface_identity",
				"expected": expected_identity.stable_key() if expected_identity != null else &"",
				"actual": actual_identity.stable_key() if actual_identity != null else &"",
			})
			continue
		var point: Vector3 = outcome.point
		for target_index in assigned_targets[witness_index]:
			if point.distance_to(target_points[target_index]) > TARGET_DISTANCE_TOLERANCE:
				failure_diagnostics.append({
					"witness_index": witness_index,
					"aim": witnesses[witness_index].stable_key(),
					"reason": &"assigned_target_distance",
					"target_index": target_index,
					"distance": point.distance_to(target_points[target_index]),
				})
				break

	var valid := failure_diagnostics.is_empty()
	return {
		"valid": valid,
		"rejection": &"" if valid else &"rigidbody_parity",
		"failure_diagnostics": failure_diagnostics,
		"outcomes": outcomes,
		"rigidbody_reachability_checksum": _rigidbody_checksum(
			witnesses,
			outcomes
		) if valid else 0,
		"witness_count": witnesses.size(),
		"batch_count": ceili(float(witnesses.size()) / float(batch_size)),
		"elapsed_ms": Time.get_ticks_msec() - started,
	}


static func build_certificate(
		stage_id: StringName,
		layout: GeneratedStageLayout,
		predictor_result: Dictionary,
		rigidbody_result: Dictionary,
		summit_result: Dictionary = {},
		summit_rigidbody_result: Dictionary = {}
) -> DirectReachabilityCertificate:
	if layout == null or not bool(predictor_result.get("valid", false)) \
			or not bool(rigidbody_result.get("valid", false)):
		return null
	if not summit_result.is_empty() and (
			not bool(summit_result.get("valid", false))
			or not bool(summit_rigidbody_result.get("valid", false))
		):
		return null
	var witnesses: Array[AimTuple] = []
	for value in predictor_result.get("witnesses", []):
		witnesses.append(value as AimTuple)
	var angles := PackedInt32Array()
	var powers := PackedInt32Array()
	for witness in witnesses:
		angles.append(roundi(witness.yaw_degrees * 10.0))
		angles.append(roundi(witness.elevation_degrees * 10.0))
		powers.append(witness.power_percent)
	var summit_region_checksum := 0
	var summit_triangle_ids := PackedInt32Array()
	var summit_witness_index := -1
	var summit_witness_angle_tenths := PackedInt32Array()
	var summit_witness_power := -1
	var summit_predictor_checksum := 0
	var summit_rigidbody_checksum := 0
	var summit_height_margin := 0.0
	if not summit_result.is_empty():
		summit_region_checksum = layout.summit_region_checksum()
		summit_triangle_ids = layout.summit_triangle_ids()
		summit_predictor_checksum = int(summit_result.get(
			"predictor_reachability_checksum", 0
		))
		summit_rigidbody_checksum = int(summit_rigidbody_result.get(
			"rigidbody_reachability_checksum", 0
		))
		var summit_witnesses: Array = summit_result.get("witnesses", [])
		if summit_witnesses.is_empty():
			return null
		# Keep summit proof independent from target coverage. The summit may be
		# outside the scoreable route mask, so it must not be forced into the
		# centroid witness table.
		var summit_aim := summit_witnesses[0] as AimTuple
		if summit_aim == null or not summit_aim.is_valid():
			return null
		summit_witness_angle_tenths.append(roundi(summit_aim.yaw_degrees * 10.0))
		summit_witness_angle_tenths.append(roundi(summit_aim.elevation_degrees * 10.0))
		summit_witness_power = summit_aim.power_percent
		summit_height_margin = _summit_height_margin(layout, summit_result, 0)
		if summit_height_margin > 1.0:
			return null
	var certificate := DirectReachabilityCertificate.create(
		stage_id,
		layout.profile_version,
		layout.terrain_seed,
		layout.accepted_seed,
		layout.checksum,
		layout.target_mask_checksum,
		layout.placement_checksum(),
		layout.containment.checksum(),
		int(predictor_result.reachable_target_checksum),
		int(predictor_result.predictor_reachability_checksum),
		int(rigidbody_result.rigidbody_reachability_checksum),
		angles,
		powers,
		predictor_result.target_witness_indices,
		predictor_result.minimum_distance_margins,
		predictor_result.minimum_range_margins,
		int(predictor_result.default_witness_index),
		summit_region_checksum,
		summit_triangle_ids,
		summit_witness_index,
		summit_predictor_checksum,
		summit_rigidbody_checksum,
		summit_height_margin,
		summit_witness_angle_tenths,
		summit_witness_power
	)
	return certificate if certificate.is_valid() else null


static func _summit_height_margin(
		layout: GeneratedStageLayout,
		summit_result: Dictionary,
		summit_index: int
) -> float:
	var maximum_height := -INF
	for height in layout.heights:
		maximum_height = maxf(maximum_height, height)
	var target_points: PackedVector3Array = summit_result.get(
		"target_points",
		PackedVector3Array()
	)
	var witness_impacts: PackedVector3Array = summit_result.get(
		"witness_impacts",
		PackedVector3Array()
	)
	if summit_index < 0 or summit_index >= target_points.size() \
			or summit_index >= witness_impacts.size():
		return INF
	var local_samples := layout.summit_region(0.25)
	if summit_index >= local_samples.size():
		return INF
	var world_offset_y := target_points[summit_index].y \
			- float(local_samples[summit_index].point.y)
	return maxf(
		(world_offset_y + maximum_height) - witness_impacts[summit_index].y,
		0.0
	)


static func certificate_matches(
		expected: DirectReachabilityCertificate,
		actual: DirectReachabilityCertificate
) -> bool:
	if expected == null or actual == null or not expected.is_valid() or not actual.is_valid():
		return false
	var summit_matches := true
	var summit_fields_present := expected.summit_region_checksum != 0 \
			or actual.summit_region_checksum != 0
	if summit_fields_present:
		summit_matches = expected.summit_region_checksum == actual.summit_region_checksum \
				and expected.summit_triangle_ids == actual.summit_triangle_ids \
				and expected.summit_witness != null \
				and actual.summit_witness != null \
				and expected.summit_witness.is_equal_to(actual.summit_witness) \
				and expected.summit_predictor_reachability_checksum == actual.summit_predictor_reachability_checksum \
				and expected.summit_rigidbody_reachability_checksum == actual.summit_rigidbody_reachability_checksum \
				and is_equal_approx(expected.summit_minimum_height_margin, actual.summit_minimum_height_margin)
	return expected.stage_id == actual.stage_id \
			and expected.profile_version == actual.profile_version \
			and expected.requested_seed == actual.requested_seed \
			and expected.accepted_seed == actual.accepted_seed \
			and expected.height_checksum == actual.height_checksum \
			and expected.target_checksum == actual.target_checksum \
			and expected.placement_checksum == actual.placement_checksum \
			and expected.containment_checksum == actual.containment_checksum \
			and expected.reachable_target_checksum == actual.reachable_target_checksum \
			and expected.predictor_reachability_checksum == actual.predictor_reachability_checksum \
			and expected.rigidbody_reachability_checksum == actual.rigidbody_reachability_checksum \
			and expected.witness_angle_tenths_read_only() == actual.witness_angle_tenths_read_only() \
			and expected.witness_powers_read_only() == actual.witness_powers_read_only() \
			and expected.target_witness_indices == actual.target_witness_indices \
			and expected.minimum_distance_margins == actual.minimum_distance_margins \
			and expected.minimum_range_margins == actual.minimum_range_margins \
			and expected.default_witness_index == actual.default_witness_index \
			and summit_matches


## MVP-only bounded entry point. It solves exactly one supplied target sample;
## it does not assign or claim reachability for any other target texel.
static func solve_one_target(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		layout: GeneratedStageLayout,
		stage_bounds: AABB,
		target_world_point: Vector3,
		target_world_normal: Vector3,
		target_sample: Dictionary
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
		_build_solver_cache(cannon)
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
		solver_cache: Dictionary = {}
) -> Dictionary:
	if solver_cache.is_empty():
		solver_cache = _build_solver_cache(cannon)
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
	# CannonBallistics maps positive yaw toward negative X, matching the
	# CannonController yaw pivot. Invert the X component when recovering the
	# legal yaw from a target bearing.
	var bearing := rad_to_deg(atan2(-reference_delta.x, -reference_delta.y))
	var nearest_yaw := AimTuple.snap_angle(bearing)
	var desired_center := target_world_point \
			+ target_world_normal * cannon.projectile_data.radius
	for yaw in [nearest_yaw, nearest_yaw - 0.1, nearest_yaw + 0.1]:
		if yaw < AimTuple.MINIMUM_YAW_DEGREES or yaw > AimTuple.MAXIMUM_YAW_DEGREES:
			continue
		var horizontal_direction := Vector2(
			-sin(deg_to_rad(yaw)),
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

	nominations.sort_custom(_nomination_precedes)
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
		if not _prediction_witnesses_target(prediction, target_world_point, target_sample):
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
	var relative := _damped_position_at_horizontal_range_cached(
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
	var damping := maxf(1.0 - cannon.projectile_data.linear_damp * step, 0.0)
	var gravity_magnitude := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var gravity_direction := Vector3(ProjectSettings.get_setting(
		"physics/3d/default_gravity_vector",
		Vector3.DOWN
	)).normalized()
	var gravity_y := gravity_direction.y * gravity_magnitude
	var horizontal_factors := PackedFloat64Array()
	var gravity_offsets := PackedFloat64Array()
	horizontal_factors.resize(TrajectoryPredictor.MAXIMUM_STEPS + 1)
	gravity_offsets.resize(TrajectoryPredictor.MAXIMUM_STEPS + 1)
	for step_count in range(1, TrajectoryPredictor.MAXIMUM_STEPS + 1):
		if is_equal_approx(damping, 1.0):
			horizontal_factors[step_count] = step * float(step_count)
			gravity_offsets[step_count] = gravity_y * step * step \
					* float(step_count * (step_count + 1)) * 0.5
		else:
			var damping_sum := damping * (1.0 - pow(damping, step_count)) / (1.0 - damping)
			horizontal_factors[step_count] = step * damping_sum
			gravity_offsets[step_count] = step * gravity_y * step / (1.0 - damping) \
					* (float(step_count) - damping_sum)
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
	return {
		"step": step,
		"damping": damping,
		"log_damping": log(damping) if not is_equal_approx(damping, 1.0) else 0.0,
		"asymptotic_factor": step * damping / (1.0 - damping) \
				if not is_equal_approx(damping, 1.0) else INF,
		"horizontal_factors": horizontal_factors,
		"gravity_offsets": gravity_offsets,
		"speeds": speeds,
		"sines": sines,
		"cosines": cosines,
	}


static func _damped_position_at_horizontal_range_cached(
		horizontal_speed: float,
		vertical_speed: float,
		projected_range: float,
		solver_cache: Dictionary
) -> Vector2:
	var step: float = solver_cache.step
	var damping: float = solver_cache.damping
	if damping <= 0.0:
		return Vector2.INF
	var step_count := 0
	if is_equal_approx(damping, 1.0):
		step_count = ceili(projected_range / maxf(horizontal_speed * step, 0.000001))
	else:
		var asymptotic_range := horizontal_speed * float(solver_cache.asymptotic_factor)
		if projected_range >= asymptotic_range:
			return Vector2.INF
		var remaining_ratio := 1.0 - projected_range / asymptotic_range
		step_count = ceili(log(remaining_ratio) / float(solver_cache.log_damping))
	step_count = clampi(step_count, 1, TrajectoryPredictor.MAXIMUM_STEPS)
	var horizontal_factors: PackedFloat64Array = solver_cache.horizontal_factors
	var gravity_offsets: PackedFloat64Array = solver_cache.gravity_offsets
	var previous := Vector2(
		horizontal_speed * horizontal_factors[step_count - 1],
		vertical_speed * horizontal_factors[step_count - 1] + gravity_offsets[step_count - 1]
	)
	var current := Vector2(
		horizontal_speed * horizontal_factors[step_count],
		vertical_speed * horizontal_factors[step_count] + gravity_offsets[step_count]
	)
	if current.x + 0.000001 < projected_range:
		return Vector2.INF
	var fraction := clampf(
		(projected_range - previous.x) / maxf(current.x - previous.x, 0.000001),
		0.0,
		1.0
	)
	return previous.lerp(current, fraction)


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
			aim.power_percent,
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


static func _prediction_witnesses_target(
		prediction: TrajectoryPrediction,
		target_world_point: Vector3,
		target_sample: Dictionary
) -> bool:
	if prediction == null or prediction.kind != TrajectoryPrediction.Kind.COLLISION \
			or prediction.hit_identity == null:
		return false
	var identity := prediction.hit_identity
	return identity.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			and not target_sample.is_empty() \
			and prediction.endpoint.distance_to(target_world_point) <= TARGET_DISTANCE_TOLERANCE


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
	var distance := prediction.endpoint.distance_to(target_world_point)
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


static func _nearest_reusable_witness(
		candidate_indices: PackedInt32Array,
		witness_impacts: PackedVector3Array,
		target_world_point: Vector3
) -> int:
	var best_index := -1
	var best_distance := INF
	for witness_index in candidate_indices:
		var distance := witness_impacts[witness_index].distance_to(target_world_point)
		if distance <= TARGET_DISTANCE_TOLERANCE \
				and (distance < best_distance or (distance == best_distance and witness_index < best_index)):
			best_index = witness_index
			best_distance = distance
	return best_index


static func _nearest_spatial_reusable_witness(
		buckets: Dictionary,
		witness_impacts: PackedVector3Array,
		target_world_point: Vector3
) -> int:
	var center := _spatial_bucket_for(target_world_point)
	var candidates := PackedInt32Array()
	for offset_z in range(-1, 2):
		for offset_x in range(-1, 2):
			var bucket_key := center + Vector2i(offset_x, offset_z)
			var bucket: PackedInt32Array = buckets.get(bucket_key, PackedInt32Array())
			for witness_index in bucket:
				candidates.append(witness_index)
	return _nearest_reusable_witness(candidates, witness_impacts, target_world_point)


static func _register_spatial_witness(
		buckets: Dictionary,
		world_point: Vector3,
		witness_index: int
) -> void:
	var bucket_key := _spatial_bucket_for(world_point)
	var bucket: PackedInt32Array = buckets.get(bucket_key, PackedInt32Array())
	bucket.append(witness_index)
	buckets[bucket_key] = bucket


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
		ContainmentSpec.CONTACT_OWNER_META,
		&""
	))
	var shape_owner_id := collision_object.shape_find_owner(contact.collider_shape_index)
	if shape_owner_id < 0:
		return null
	var shape_owner := collision_object.shape_owner_get_owner(shape_owner_id)
	if shape_owner == null:
		return null
	var shape_id := StringName(shape_owner.get_meta(ContainmentSpec.CONTACT_SHAPE_META, &""))
	if owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
		return terrain_surface.classify_top_hit(
			contact.world_position,
			contact.normal,
			shape_id,
			contact.collider_shape_index
		)
	var identity := TrajectoryHitIdentity.new(
		owner_id,
		shape_id,
		contact.collider_shape_index
	)
	return identity if identity.is_valid() else null


static func _pixel_center_local(pixel: Vector2i, bounds: Rect2, mask_size: int) -> Vector2:
	return Vector2(
		lerpf(bounds.position.x, bounds.end.x, (float(pixel.x) + 0.5) / float(mask_size)),
		lerpf(bounds.position.y, bounds.end.y, (float(pixel.y) + 0.5) / float(mask_size))
	)


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
	return _hash_int(hash, aim.power_percent)


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


static func _uncovered_failure(
		started: int,
		uncovered_count: int,
		diagnostics: Array[Dictionary],
		visited_target_count: int,
		predictor_call_count: int,
		candidate_tuple_count: int
) -> Dictionary:
	return {
		"valid": false,
		"rejection": &"uncovered_target",
		"uncovered_count": uncovered_count,
		"uncovered_diagnostics": diagnostics,
		"visited_target_count": visited_target_count,
		"predictor_call_count": predictor_call_count,
		"candidate_tuple_count": candidate_tuple_count,
		"elapsed_ms": Time.get_ticks_msec() - started,
	}


static func _failure(rejection: StringName, started: int) -> Dictionary:
	return {
		"valid": false,
		"rejection": rejection,
		"elapsed_ms": Time.get_ticks_msec() - started,
	}
