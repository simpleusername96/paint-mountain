extends SceneTree

const TERRAIN_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const BACKSTOP_SCENE := preload("res://scenes/gameplay/backstop_environment.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")

var _failed := false
var _stage: StageData


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	_stage = StageCatalog.get_stage(_requested_stage_id())
	_assert_true(_stage != null, "target reachability must use the canonical serialized stage catalog")
	if _stage == null:
		quit(1)
		return
	var candidate_prefix_limit := _candidate_prefix_limit()
	if candidate_prefix_limit > 0:
		await _run_candidate_prefix(candidate_prefix_limit)
		quit(1 if _failed else 0)
		return
	var throughput_sample_limit := _throughput_sample_limit()
	if throughput_sample_limit > 0:
		await _run_throughput_sample(throughput_sample_limit)
		quit(1 if _failed else 0)
		return
	if "--solver-one" in OS.get_cmdline_user_args():
		await _run_solver_one()
		quit(1 if _failed else 0)
		return
	if "--identity-only" in OS.get_cmdline_user_args():
		await _run_identity_only()
		quit(1 if _failed else 0)
		return
	var layout := SeededStageGenerator.generate(
		_stage.generation_profile,
		_stage.terrain_seed,
		_stage
	)
	_assert_true(layout != null, "First Descent must produce a structurally accepted target layout")
	if layout == null:
		quit(1)
		return

	var certification_root := Node3D.new()
	certification_root.name = "TargetReachabilityFixture"
	root.add_child(certification_root)
	var terrain_surface := TERRAIN_SCENE.instantiate() as TerrainSurface
	terrain_surface.position = _stage.terrain_center
	certification_root.add_child(terrain_surface)
	terrain_surface.configure(layout)
	var backstop := BACKSTOP_SCENE.instantiate() as BackstopEnvironment
	certification_root.add_child(backstop)
	backstop.configure(
		layout.containment,
		_stage.paint_world_bounds(),
		_stage.terrain_center.y
	)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	certification_root.add_child(cannon)
	cannon.global_transform = _stage.cannon_transform
	await physics_frame

	_assert_predictor_identity(terrain_surface, layout, cannon)
	var summit := DirectReachabilityValidator.validate_summit(
		root.get_world_3d().direct_space_state,
		cannon,
		terrain_surface,
		layout,
		layout.containment.containment_bounds
	)
	_assert_true(bool(summit.get("valid", false)), "summit region must have a legal predictor witness; result=%s" % str(summit))
	var summit_rigidbody := {}
	if bool(summit.get("valid", false)):
		summit_rigidbody = await DirectReachabilityValidator.validate_rigidbody_batches(
			self,
			certification_root,
			cannon,
			terrain_surface,
			layout,
			layout.containment.containment_bounds,
			summit
		)
		_assert_true(bool(summit_rigidbody.get("valid", false)), "summit witnesses must reproduce through production PaintProjectile; result=%s" % str(summit_rigidbody))
	if "--summit-only" in OS.get_cmdline_user_args():
		_assert_separate_summit_certificate_contract(layout, summit, summit_rigidbody)
		print("Summit reachability: region=%d witness=%d predictor=%d rigidbody=%d margin=%.3f" % [
			int(summit.get("region_count", 0)),
			(summit.get("witnesses", []) as Array).size(),
			int(summit.get("predictor_reachability_checksum", 0)),
			int(summit_rigidbody.get("rigidbody_reachability_checksum", 0)),
			float(summit.get("minimum_height_margin", 0.0)),
		])
		certification_root.queue_free()
		await physics_frame
		quit(1 if _failed else 0)
		return
	var predictor := DirectReachabilityValidator.validate_predictor(
		root.get_world_3d().direct_space_state,
		cannon,
		terrain_surface,
		layout,
		layout.containment.containment_bounds,
		DirectReachabilityValidator.MAXIMUM_UNCOVERED_DIAGNOSTICS,
		func(progress: Dictionary) -> void:
			print(
				(
					"Target reachability progress: visited=%d witnesses=%d reused=%d "
					+ "predictor_calls=%d elapsed_ms=%d"
				) % [
					progress.visited_target_count,
					progress.witness_count,
					progress.reused_target_count,
					progress.predictor_call_count,
					progress.elapsed_ms,
				]
			)
	)
	_assert_true(bool(predictor.get("valid", false)), "every target texel must have a predictor witness whose impact mark covers it; result=%s" % str(predictor))
	var rigidbody := {}
	if bool(predictor.get("valid", false)):
		_assert_predictor_certificate_contract(layout, predictor)
		rigidbody = await DirectReachabilityValidator.validate_rigidbody_batches(
			self,
			certification_root,
			cannon,
			terrain_surface,
			layout,
			layout.containment.containment_bounds,
			predictor
		)
		_assert_true(bool(rigidbody.get("valid", false)), "every distinct witness must reproduce through production PaintProjectile; result=%s" % str(rigidbody))
		if bool(rigidbody.get("valid", false)):
			var certificate := DirectReachabilityValidator.build_certificate(
				_stage.stage_id,
				layout,
				predictor,
				rigidbody,
				summit,
				summit_rigidbody
			)
			_assert_true(certificate != null and certificate.is_valid(), "predictor and real-body parity must build one valid target/summit certificate")
			if certificate != null:
				_assert_true(certificate.witness_count() == predictor.witnesses.size(), "certificate must retain every distinct witness exactly once")
				_assert_true(certificate.target_witness_indices.size() == predictor.target_count, "certificate must assign every target texel in row-major target order")
				_assert_true(certificate.target_witness_indices == rigidbody.target_witness_indices, "certificate must use physical-contact target assignments")
				_assert_true(certificate.default_aim.is_equal_to(predictor.witnesses[predictor.default_witness_index]), "certificate default aim must be the centroid-nearest certified witness")
				_assert_true(certificate.summit_witness != null and certificate.summit_witness.is_equal_to(summit.witnesses[0]), "certificate summit aim must remain independent from the centroid witness table")

	print(
		(
			"Target reachability: target=%d witnesses=%d reused=%d predictor_calls=%d "
			+ "full_mark_fallback=%d predictor_ms=%d rigidbody_ms=%d"
		) % [
			int(predictor.get("target_count", 0)),
			predictor.get("witnesses", []).size(),
			int(predictor.get("reused_target_count", 0)),
			int(predictor.get("predictor_call_count", 0)),
			int(predictor.get("full_mark_fallback_count", 0)),
			int(predictor.get("elapsed_ms", 0)),
			int(rigidbody.get("elapsed_ms", 0)) if bool(predictor.get("valid", false)) else 0,
		]
	)
	certification_root.queue_free()
	await physics_frame
	quit(1 if _failed else 0)


func _assert_separate_summit_certificate_contract(
		layout: GeneratedStageLayout,
		summit: Dictionary,
		summit_rigidbody: Dictionary
) -> void:
	# This is a serialization-only guard used by the summit fast path. It keeps
	# the target witness table deliberately distinct from the summit witness so
	# a summit outside the scoreable route mask cannot be forced into it.
	var target_aim := AimTuple.new(0.0, 10.0, 0)
	var summit_witnesses: Array = summit.get("witnesses", [])
	if summit_witnesses.is_empty():
		return
	var summit_aim := summit_witnesses[0] as AimTuple
	var target_assignments := PackedInt32Array()
	target_assignments.resize(layout.target_pixel_count())
	var target_checksum := layout.reachable_target_checksum(target_assignments)
	var certificate := DirectReachabilityValidator.build_certificate(
		StringName(String(layout.profile_id).trim_suffix("_v7")),
		layout,
		{
			"valid": true,
			"witnesses": [target_aim],
			"target_witness_indices": target_assignments,
			"minimum_distance_margins": PackedFloat32Array([1.0]),
			"minimum_range_margins": PackedFloat32Array([1.0]),
			"default_witness_index": 0,
			"reachable_target_checksum": target_checksum,
			"predictor_reachability_checksum": 1,
		},
		{
			"valid": true,
			"rigidbody_reachability_checksum": 1,
		},
		summit,
		summit_rigidbody
	)
	_assert_true(certificate != null and certificate.is_valid(), "summit certificate must serialize a separate legal witness")
	_assert_true(certificate != null and certificate.summit_witness != null, "summit certificate must expose its dedicated witness")
	_assert_true(certificate != null and certificate.summit_witness.is_equal_to(summit_aim), "dedicated summit witness must round-trip unchanged")
	if certificate != null:
		# The primitive certificate can validate a non-empty assignment array, but
		# only the generated layout knows how many scoreable texels exist. A
		# shortened prefix must therefore fail the complete-proof boundary.
		var partial_assignments := PackedInt32Array()
		partial_assignments.resize(maxi(layout.target_pixel_count() - 1, 1))
		var partial_predictor := {
			"valid": true,
			"witnesses": [target_aim],
			"target_witness_indices": partial_assignments,
			"minimum_distance_margins": PackedFloat32Array([1.0]),
			"minimum_range_margins": PackedFloat32Array([1.0]),
			"default_witness_index": 0,
			"reachable_target_checksum": layout.reachable_target_checksum(partial_assignments),
			"predictor_reachability_checksum": 1,
		}
		var partial_certificate := DirectReachabilityValidator.build_certificate(
			StringName(String(layout.profile_id).trim_suffix("_v7")),
			layout,
			partial_predictor,
			{"valid": true, "rigidbody_reachability_checksum": 1},
			summit,
			summit_rigidbody
		)
		layout.reachability_certificate = partial_certificate
		_assert_true(not layout.is_certified(), "a partial target assignment must not certify the layout")
		layout.reachability_certificate = null
	_assert_true(certificate != null and not certificate.summit_witness.is_equal_to(target_aim), "dedicated summit witness must not alias the target witness table")


func _run_candidate_prefix(requested_target_count: int) -> void:
	var started := Time.get_ticks_msec()
	var profile := _stage.generation_profile
	var contract := profile.generation_contract
	var candidates: Array[Dictionary] = []
	for attempt_index in range(contract.attempt_count):
		candidates.append({
			"attempt": attempt_index,
			"seed": int((_stage.terrain_seed + attempt_index * contract.attempt_seed_stride) & 0x7fffffff),
		})
	candidates.append({"attempt": -1, "seed": profile.fallback_seed})
	var structurally_accepted_count := 0
	var target_prefix_pass_count := 0
	for candidate in candidates:
		var candidate_started := Time.get_ticks_msec()
		var layout := SeededStageGenerator._build_attempt(
			_stage.stage_id,
			profile,
			_stage.terrain_seed,
			int(candidate.seed),
			int(candidate.attempt)
		)
		if layout == null or not SeededStageGenerator._validate(profile, layout) \
				or not SeededStageGenerator._finalize_layout(profile, _stage, layout):
			print(
				(
					"Reachability candidate first-target: attempt=%d seed=%d structural=false "
					+ "rejection=%s elapsed_ms=%d"
				) % [
					candidate.attempt,
					candidate.seed,
					layout.metrics.get("rejection", &"graph") if layout != null else &"graph",
					Time.get_ticks_msec() - candidate_started,
				]
			)
			continue
		structurally_accepted_count += 1

		var fixture_root := Node3D.new()
		root.add_child(fixture_root)
		var terrain_surface := TERRAIN_SCENE.instantiate() as TerrainSurface
		terrain_surface.position = _stage.terrain_center
		fixture_root.add_child(terrain_surface)
		terrain_surface.configure(layout)
		var backstop := BACKSTOP_SCENE.instantiate() as BackstopEnvironment
		fixture_root.add_child(backstop)
		backstop.configure(
			layout.containment,
			_stage.paint_world_bounds(),
			_stage.terrain_center.y
		)
		var cannon := CANNON_SCENE.instantiate() as CannonController
		fixture_root.add_child(cannon)
		cannon.global_transform = _stage.cannon_transform
		await physics_frame

		var prefix := _validate_target_prefix(
			root.get_world_3d().direct_space_state,
			cannon,
			terrain_surface,
			layout,
			requested_target_count
		)
		var valid := bool(prefix.get("valid", false))
		if valid:
			target_prefix_pass_count += 1
		print(
			(
				"Reachability candidate prefix: attempt=%d seed=%d structural=true "
				+ "requested=%d visited=%d rejected_pixel=%s valid=%s witnesses=%d "
				+ "reused=%d candidates=%d predictor_calls=%d solver_ms=%d elapsed_ms=%d"
			) % [
				candidate.attempt,
				candidate.seed,
				requested_target_count,
				int(prefix.visited_target_count),
				str(prefix.get("rejected_pixel", Vector2i(-1, -1))),
				str(valid),
				int(prefix.witness_count),
				int(prefix.reused_target_count),
				int(prefix.candidate_tuple_count),
				int(prefix.predictor_call_count),
				int(prefix.elapsed_ms),
				Time.get_ticks_msec() - candidate_started,
			]
		)
		if not valid:
			print(
				"Reachability candidate prefix diagnostics: attempt=%d pixel=%s %s" % [
					candidate.attempt,
					str(prefix.get("rejected_pixel", Vector2i(-1, -1))),
					str(prefix.get("solver_diagnostics", {})),
				]
			)
		fixture_root.queue_free()
		await physics_frame
	print(
		(
			"Reachability candidate prefix summary: requested=%d candidates=%d structural=%d "
			+ "passing=%d elapsed_ms=%d"
		) % [
			requested_target_count,
			candidates.size(),
			structurally_accepted_count,
			target_prefix_pass_count,
			Time.get_ticks_msec() - started,
		]
	)
	_assert_true(
		target_prefix_pass_count > 0,
		"all structurally accepted First Descent candidates fail the requested exact target prefix"
	)


func _validate_target_prefix(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		terrain_surface: TerrainSurface,
		layout: GeneratedStageLayout,
		requested_target_count: int
) -> Dictionary:
	var started := Time.get_ticks_msec()
	var witnesses: Array[AimTuple] = []
	var witness_impacts := PackedVector3Array()
	var witnesses_by_triangle: Dictionary = {}
	var prediction_cache: Dictionary = {}
	var solver_cache := DirectReachabilityValidator._build_solver_cache(cannon)
	var predictor_call_count := 0
	var candidate_tuple_count := 0
	var reused_target_count := 0
	var visited_target_count := 0
	var mask_size := StageGenerationContract.REQUIRED_MASK_SIZE
	for pixel_y in range(mask_size):
		for pixel_x in range(mask_size):
			var pixel_index := pixel_y * mask_size + pixel_x
			if layout.target_mask[pixel_index] < 128:
				continue
			var local_xz := DirectReachabilityValidator._pixel_center_local(
				Vector2i(pixel_x, pixel_y),
				layout.local_bounds,
				mask_size
			)
			var sample := layout.top_topology.surface_sample_at_local(
				local_xz.x,
				local_xz.y,
				false
			)
			if sample.is_empty():
				return {
					"valid": false,
					"rejection": &"target_surface_sample",
					"rejected_pixel": Vector2i(pixel_x, pixel_y),
					"visited_target_count": visited_target_count,
					"witness_count": witnesses.size(),
					"reused_target_count": reused_target_count,
					"predictor_call_count": predictor_call_count,
					"candidate_tuple_count": candidate_tuple_count,
					"prediction_cache_size": prediction_cache.size(),
					"elapsed_ms": Time.get_ticks_msec() - started,
				}
			var target_world_point: Vector3 = terrain_surface.to_global(sample.point as Vector3)
			var target_world_normal: Vector3 = (
				terrain_surface.global_transform.basis.inverse().transposed()
				* (sample.normal as Vector3)
			).normalized()
			var triangle_key := DirectReachabilityValidator._triangle_key(
				sample.cell,
				int(sample.triangle)
			)
			var reused_index := DirectReachabilityValidator._nearest_reusable_witness(
				witnesses_by_triangle.get(triangle_key, PackedInt32Array()),
				witness_impacts,
				target_world_point
			)
			if reused_index >= 0:
				reused_target_count += 1
			else:
				var solved := DirectReachabilityValidator._solve_target(
					space_state,
					cannon,
					layout,
					layout.containment.containment_bounds,
					target_world_point,
					target_world_normal,
					sample,
					prediction_cache,
					solver_cache
				)
				predictor_call_count += int(solved.get("predictor_calls", 0))
				candidate_tuple_count += int(solved.get("candidate_count", 0))
				if not bool(solved.get("valid", false)):
					return {
						"valid": false,
						"rejection": &"uncovered_target",
						"rejected_pixel": Vector2i(pixel_x, pixel_y),
						"solver_diagnostics": solved.get("diagnostics", {}),
						"visited_target_count": visited_target_count,
						"witness_count": witnesses.size(),
						"reused_target_count": reused_target_count,
						"predictor_call_count": predictor_call_count,
						"candidate_tuple_count": candidate_tuple_count,
						"prediction_cache_size": prediction_cache.size(),
						"elapsed_ms": Time.get_ticks_msec() - started,
					}
				var witness_index := witnesses.size()
				witnesses.append(solved.aim as AimTuple)
				witness_impacts.append((solved.prediction as TrajectoryPrediction).endpoint)
				var triangle_witnesses: PackedInt32Array = witnesses_by_triangle.get(
					triangle_key,
					PackedInt32Array()
				)
				triangle_witnesses.append(witness_index)
				witnesses_by_triangle[triangle_key] = triangle_witnesses
			visited_target_count += 1
			if visited_target_count >= requested_target_count:
				return {
					"valid": true,
					"rejection": &"",
					"rejected_pixel": Vector2i(-1, -1),
					"visited_target_count": visited_target_count,
					"witness_count": witnesses.size(),
					"reused_target_count": reused_target_count,
					"predictor_call_count": predictor_call_count,
					"candidate_tuple_count": candidate_tuple_count,
					"prediction_cache_size": prediction_cache.size(),
					"elapsed_ms": Time.get_ticks_msec() - started,
				}
	return {
		"valid": visited_target_count > 0,
		"rejection": &"" if visited_target_count > 0 else &"empty_target_mask",
		"rejected_pixel": Vector2i(-1, -1),
		"visited_target_count": visited_target_count,
		"witness_count": witnesses.size(),
		"reused_target_count": reused_target_count,
		"predictor_call_count": predictor_call_count,
		"candidate_tuple_count": candidate_tuple_count,
		"prediction_cache_size": prediction_cache.size(),
		"elapsed_ms": Time.get_ticks_msec() - started,
	}


func _run_throughput_sample(requested_target_count: int) -> void:
	var layout := SeededStageGenerator.generate_structural_sequence(
		_stage.generation_profile,
		_stage.terrain_seed,
		_stage
	)
	_assert_true(layout != null, "throughput sample requires the accepted First Descent layout")
	if layout == null:
		return
	var total_target_count := 0
	for byte in layout.target_mask:
		if byte >= 128:
			total_target_count += 1
	var target_limit := mini(requested_target_count, total_target_count)

	var fixture_root := Node3D.new()
	root.add_child(fixture_root)
	var terrain_surface := TERRAIN_SCENE.instantiate() as TerrainSurface
	terrain_surface.position = _stage.terrain_center
	fixture_root.add_child(terrain_surface)
	terrain_surface.configure(layout)
	var backstop := BACKSTOP_SCENE.instantiate() as BackstopEnvironment
	fixture_root.add_child(backstop)
	backstop.configure(
		layout.containment,
		_stage.paint_world_bounds(),
		_stage.terrain_center.y
	)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	fixture_root.add_child(cannon)
	cannon.global_transform = _stage.cannon_transform
	await physics_frame

	var started := Time.get_ticks_msec()
	var witnesses: Array[AimTuple] = []
	var witness_impacts := PackedVector3Array()
	var witnesses_by_triangle: Dictionary = {}
	var prediction_cache: Dictionary = {}
	var solver_cache := DirectReachabilityValidator._build_solver_cache(cannon)
	var predictor_call_count := 0
	var candidate_tuple_count := 0
	var reused_target_count := 0
	var visited_target_count := 0
	var mask_size := StageGenerationContract.REQUIRED_MASK_SIZE
	for pixel_y in range(mask_size):
		for pixel_x in range(mask_size):
			var pixel_index := pixel_y * mask_size + pixel_x
			if layout.target_mask[pixel_index] < 128:
				continue
			var local_xz := DirectReachabilityValidator._pixel_center_local(
				Vector2i(pixel_x, pixel_y),
				layout.local_bounds,
				mask_size
			)
			var sample := layout.top_topology.surface_sample_at_local(
				local_xz.x,
				local_xz.y,
				false
			)
			_assert_true(not sample.is_empty(), "throughput sample target must map to top topology")
			if sample.is_empty():
				fixture_root.queue_free()
				await physics_frame
				return
			var target_world_point: Vector3 = terrain_surface.to_global(sample.point as Vector3)
			var target_world_normal: Vector3 = (
				terrain_surface.global_transform.basis.inverse().transposed()
				* (sample.normal as Vector3)
			).normalized()
			var triangle_key := DirectReachabilityValidator._triangle_key(
				sample.cell,
				int(sample.triangle)
			)
			var reused_index := DirectReachabilityValidator._nearest_reusable_witness(
				witnesses_by_triangle.get(triangle_key, PackedInt32Array()),
				witness_impacts,
				target_world_point
			)
			if reused_index >= 0:
				reused_target_count += 1
			else:
				var solved := DirectReachabilityValidator._solve_target(
					root.get_world_3d().direct_space_state,
					cannon,
					layout,
					layout.containment.containment_bounds,
					target_world_point,
					target_world_normal,
					sample,
					prediction_cache,
					solver_cache
				)
				predictor_call_count += int(solved.get("predictor_calls", 0))
				candidate_tuple_count += int(solved.get("candidate_count", 0))
				_assert_true(
					bool(solved.get("valid", false)),
					"throughput sample found an uncovered target at pixel %s; result=%s"
							% [Vector2i(pixel_x, pixel_y), str(solved)]
				)
				if not bool(solved.get("valid", false)):
					print(
						(
							"Reachability bounded sample rejected: visited=%d pixel=%s "
							+ "witnesses=%d reused=%d predictor_calls=%d candidates=%d "
							+ "cache=%d elapsed_ms=%d"
						) % [
							visited_target_count,
							str(Vector2i(pixel_x, pixel_y)),
							witnesses.size(),
							reused_target_count,
							predictor_call_count,
							candidate_tuple_count,
							prediction_cache.size(),
							Time.get_ticks_msec() - started,
						]
					)
					print(
						"Reachability bounded sample diagnostics: %s"
								% str(solved.get("diagnostics", {}))
					)
					fixture_root.queue_free()
					await physics_frame
					return
				var witness_index := witnesses.size()
				witnesses.append(solved.aim as AimTuple)
				witness_impacts.append((solved.prediction as TrajectoryPrediction).endpoint)
				var triangle_witnesses: PackedInt32Array = witnesses_by_triangle.get(
					triangle_key,
					PackedInt32Array()
				)
				triangle_witnesses.append(witness_index)
				witnesses_by_triangle[triangle_key] = triangle_witnesses
			visited_target_count += 1
			if visited_target_count >= target_limit:
				break
		if visited_target_count >= target_limit:
			break
	var elapsed_ms := Time.get_ticks_msec() - started
	var projected_full_ms := roundi(
		float(elapsed_ms) * float(total_target_count) / maxf(float(visited_target_count), 1.0)
	)
	print(
		(
			"Reachability bounded sample: visited=%d total=%d witnesses=%d reused=%d "
			+ "predictor_calls=%d candidates=%d cache=%d elapsed_ms=%d projected_full_ms=%d"
		) % [
			visited_target_count,
			total_target_count,
			witnesses.size(),
			reused_target_count,
			predictor_call_count,
			candidate_tuple_count,
			prediction_cache.size(),
			elapsed_ms,
			projected_full_ms,
		]
	)
	fixture_root.queue_free()
	await physics_frame


func _throughput_sample_limit() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--throughput-sample="):
			return maxi(argument.trim_prefix("--throughput-sample=").to_int(), 0)
	return 0


func _candidate_prefix_limit() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument == "--candidate-prefix-first-target":
			return 1
		if argument.begins_with("--candidate-prefix-targets="):
			return maxi(argument.trim_prefix("--candidate-prefix-targets=").to_int(), 0)
	return 0


func _run_identity_only() -> void:
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FACETED)
	var fixture_root := Node3D.new()
	root.add_child(fixture_root)
	var terrain_surface := TERRAIN_SCENE.instantiate() as TerrainSurface
	fixture_root.add_child(terrain_surface)
	terrain_surface.configure(layout)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	fixture_root.add_child(cannon)
	await physics_frame
	var sample := layout.top_topology.surface_sample_at_local(1.0, 1.0, false)
	var point: Vector3 = sample.point
	var prediction := TrajectoryPredictor.predict_motion(
		root.get_world_3d().direct_space_state,
		point + Vector3.UP * 20.0,
		Vector3.DOWN * 50.0,
		cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp,
		AABB(Vector3(-30.0, -30.0, -30.0), Vector3(60.0, 100.0, 60.0)),
		1
	)
	var certification_prediction := TrajectoryPredictor.predict_motion(
		root.get_world_3d().direct_space_state,
		point + Vector3.UP * 20.0,
		Vector3.DOWN * 50.0,
		cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp,
		AABB(Vector3(-30.0, -30.0, -30.0), Vector3(60.0, 100.0, 60.0)),
		1,
		false
	)
	_assert_true(prediction.kind == TrajectoryPrediction.Kind.COLLISION, "identity fixture must collide")
	_assert_true(prediction.hit_identity != null and prediction.hit_identity.is_valid(), "identity fixture must resolve stable metadata and exact topology")
	_assert_true(not prediction.sampled_points.is_empty(), "normal gameplay prediction must retain preview points by default")
	_assert_true(certification_prediction.sampled_points.is_empty(), "offline certification prediction must skip preview-point allocation")
	_assert_true(
		certification_prediction.kind == prediction.kind
				and certification_prediction.endpoint.is_equal_approx(prediction.endpoint)
				and is_equal_approx(certification_prediction.duration, prediction.duration)
				and certification_prediction.hit_identity != null
				and prediction.hit_identity != null
				and certification_prediction.hit_identity.stable_key() == prediction.hit_identity.stable_key(),
		"preview capture and allocation-free certification must preserve endpoint and identity semantics"
	)
	if prediction.hit_identity != null:
		_assert_true(prediction.hit_identity.terrain_cell == sample.cell, "identity fixture must retain canonical cell")
		_assert_true(prediction.hit_identity.terrain_triangle == int(sample.triangle), "identity fixture must retain canonical triangle")
	fixture_root.queue_free()
	await physics_frame


func _run_solver_one() -> void:
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	var fixture_root := Node3D.new()
	root.add_child(fixture_root)
	var terrain_surface := TERRAIN_SCENE.instantiate() as TerrainSurface
	terrain_surface.position = Vector3(0.0, 0.0, -45.0)
	fixture_root.add_child(terrain_surface)
	terrain_surface.configure(layout)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	cannon.position = Vector3(0.0, 0.0, 5.0)
	fixture_root.add_child(cannon)
	await physics_frame
	var sample := layout.top_topology.surface_sample_at_local(0.0, 0.0, false)
	var target_point := terrain_surface.to_global(sample.point)
	var solved := DirectReachabilityValidator._solve_target(
		root.get_world_3d().direct_space_state,
		cannon,
		layout,
		AABB(Vector3(-50.0, -30.0, -80.0), Vector3(100.0, 130.0, 120.0)),
		target_point,
		Vector3.UP,
		sample,
		{}
	)
	_assert_true(bool(solved.get("valid", false)), "fixed-lattice solver must nominate and verify a direct flat target; result=%s" % str(solved))
	if bool(solved.get("valid", false)):
		var prediction: TrajectoryPrediction = solved.prediction
		_assert_true(prediction.hit_identity.terrain_cell == sample.cell and prediction.hit_identity.terrain_triangle == int(sample.triangle), "single-target solve must retain exact triangle identity")
		_assert_true(prediction.endpoint.distance_to(target_point) <= DirectReachabilityValidator.TARGET_DISTANCE_TOLERANCE, "single-target solve must satisfy the 2.10 m impact-mark coverage tolerance")
		print("Single target witness: %s candidates=%d predictor_calls=%d" % [
			solved.aim.stable_key(), solved.candidate_count, solved.predictor_calls,
		])
	fixture_root.queue_free()
	await physics_frame


func _assert_predictor_identity(
		terrain_surface: TerrainSurface,
		layout: GeneratedStageLayout,
		cannon: CannonController
) -> void:
	var sample := layout.top_topology.surface_sample_at_local(0.0, 20.0, false)
	var point := terrain_surface.to_global(sample.point)
	var direction := (point + Vector3.UP * 10.0 - (point + Vector3.UP * 30.0)).normalized()
	var prediction := TrajectoryPredictor.predict_motion(
		root.get_world_3d().direct_space_state,
		point + Vector3.UP * 30.0,
		direction * 60.0,
		cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp,
		layout.containment.containment_bounds,
		1
	)
	_assert_true(prediction.kind == TrajectoryPrediction.Kind.COLLISION, "production predictor must report a physical top collision")
	_assert_true(prediction.hit_identity != null and prediction.hit_identity.is_valid(), "predictor collision must include immutable hit identity")
	if prediction.hit_identity == null:
		return
	_assert_true(prediction.hit_identity.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID, "predictor owner ID must come from TerrainTopBody metadata")
	_assert_true(prediction.hit_identity.contact_shape_id == TerrainSurface.TOP_SHAPE_ID, "predictor shape ID must come from the exact CollisionShape3D owner")
	_assert_true(prediction.hit_identity.body_shape_index == 0, "predictor must retain PhysicsServer body-shape index")
	var classified := terrain_surface.classify_top_hit(
		prediction.endpoint,
		prediction.normal,
		TerrainSurface.TOP_SHAPE_ID,
		prediction.hit_identity.body_shape_index
	)
	_assert_true(
		classified != null and prediction.hit_identity.stable_key() == classified.stable_key(),
		"predictor must preserve TerrainSurface's canonical classification for the actual contact"
	)


func _assert_predictor_certificate_contract(
		layout: GeneratedStageLayout,
		predictor: Dictionary
) -> void:
	var expected_target_count := 0
	for byte in layout.target_mask:
		if byte >= 128:
			expected_target_count += 1
	_assert_true(int(predictor.target_count) == expected_target_count, "validator must visit every target texel, not a representative sample")
	_assert_true(predictor.target_witness_indices.size() == expected_target_count, "every target texel must have one witness index")
	_assert_true(predictor.minimum_distance_margins.size() == predictor.witnesses.size(), "distance margins must be stored per distinct witness")
	_assert_true(predictor.minimum_range_margins.size() == predictor.witnesses.size(), "range margins must be stored per distinct witness")
	for margin in predictor.minimum_distance_margins:
		_assert_true(margin >= 0.0, "distance margin must never widen the fixed 2.10 m impact-mark tolerance")
	for margin in predictor.minimum_range_margins:
		_assert_true(margin >= 0.0, "range margin must never widen the fixed 1.02 m nomination tolerance")
	var default_point: Vector3 = predictor.witness_impacts[predictor.default_witness_index]
	var centroid: Vector2 = predictor.target_centroid_xz
	_assert_true(Vector2(default_point.x, default_point.z).distance_to(centroid) <= 8.0, "default witness must first hit within 8 m of target centroid")
	_assert_true(int(predictor.reachable_target_checksum) != 0 and int(predictor.predictor_reachability_checksum) != 0, "predictor proof checksums must be populated")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Target reachability check failed: %s" % message)


func _requested_stage_id() -> StringName:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			return StageCatalog.canonical_id(StringName(argument.trim_prefix("--stage=")))
	return &"stage_01"
