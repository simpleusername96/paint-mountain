extends SceneTree

## Headless-only producer for the temporary Stage 1 MVP admission proof. It
## solves and replays one centroid-near default shot; it never loops over or
## certifies the complete target mask.

const TERRAIN_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const BACKSTOP_SCENE := preload("res://scenes/gameplay/backstop_environment.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const BURST_SCENE := preload("res://scenes/mechanisms/burst_node.tscn")
const SPLITTER_SCENE := preload("res://scenes/mechanisms/splitter_node.tscn")
const BUMPER_SCENE := preload("res://scenes/mechanisms/bumper_node.tscn")
const STAGE_PATH := "res://resources/stages/first_descent.tres"
const PERMIT_PATH := "res://resources/stages/permits/first_descent_mvp_v4.tres"

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	var arguments := _parse_arguments()
	if not bool(arguments.valid):
		push_error("Stage MVP permit arguments are invalid: %s" % arguments.rejection)
		quit(2)
		return
	var stage := ResourceLoader.load(
		STAGE_PATH,
		"StageData",
		ResourceLoader.CACHE_MODE_REPLACE
	) as StageData
	if stage == null or stage.generation_profile == null:
		push_error("Stage 1 data/profile could not be loaded.")
		quit(1)
		return
	var result := await _produce(stage)
	if not bool(result.get("valid", false)):
		push_error("Stage 1 MVP permit production failed: %s" % str(result))
		quit(1)
		return
	var permit: StageMvpPermit = result.permit
	if bool(arguments.verify_only):
		var stored := ResourceLoader.load(
			PERMIT_PATH,
			"StageMvpPermit",
			ResourceLoader.CACHE_MODE_REPLACE
		) as StageMvpPermit
		if stored == null or not stored.has_same_proof(permit):
			push_error("Stored Stage 1 MVP permit does not reproduce.")
			quit(1)
			return
	if bool(arguments.write):
		DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(PERMIT_PATH.get_base_dir())
		)
		var save_error := ResourceSaver.save(permit, PERMIT_PATH)
		if save_error != OK:
			push_error("Could not save Stage 1 MVP permit: %s" % error_string(save_error))
			quit(1)
			return
	print(
		"Stage 1 MVP permit valid: seed=%d aim=%s predictor=%s rigidbody=%s centroid=%s" % [
			result.layout.accepted_seed,
			String(permit.default_aim.stable_key()),
			permit.predictor_point,
			permit.rigidbody_point,
			permit.target_centroid_xz,
		]
	)
	quit(0)


func _produce(stage: StageData) -> Dictionary:
	var layout := SeededStageGenerator.generate_structural_sequence(
		stage.generation_profile,
		stage.terrain_seed,
		stage
	)
	if layout == null or not layout.is_valid() or not layout.has_valid_target_mask():
		return {"valid": false, "rejection": &"structural_layout"}
	var materialized := await _materialize(stage, layout)
	if not bool(materialized.get("valid", false)):
		return materialized
	var materialized_root: Node3D = materialized.materialized_root
	var terrain: TerrainSurface = materialized.terrain
	var cannon: CannonController = materialized.cannon
	var containment := ContainmentDomainProof.evaluate(cannon, layout.containment)
	if not bool(containment.get("valid", false)):
		await _free_materialized(materialized_root)
		return {"valid": false, "rejection": &"containment", "evidence": containment}
	var target := _nearest_target_sample(layout, layout.target_centroid_local_xz())
	if not bool(target.get("valid", false)):
		await _free_materialized(materialized_root)
		return target
	var sample: Dictionary = target.sample
	var target_world_point := terrain.to_global(sample.point)
	var target_world_normal := (
		terrain.global_transform.basis.inverse().transposed() * (sample.normal as Vector3)
	).normalized()
	var solved := DirectReachabilityValidator.solve_one_target(
		root.get_world_3d().direct_space_state,
		cannon,
		layout,
		layout.containment.containment_bounds,
		target_world_point,
		target_world_normal,
		sample
	)
	if not bool(solved.get("valid", false)):
		await _free_materialized(materialized_root)
		return {
			"valid": false,
			"rejection": &"default_predictor",
			"evidence": solved,
		}
	var aim: AimTuple = solved.aim
	var prediction: TrajectoryPrediction = solved.prediction
	var centroid_local := layout.target_centroid_local_xz()
	var predictor_local := terrain.to_local(prediction.endpoint)
	if not _is_centroid_near_top(prediction.hit_identity, predictor_local, centroid_local):
		await _free_materialized(materialized_root)
		return {"valid": false, "rejection": &"predictor_centroid_or_identity"}
	var predictor_contract := {
		"valid": true,
		"witnesses": [aim],
		"witness_identities": [prediction.hit_identity],
		"target_witness_indices": PackedInt32Array([0]),
		"target_points": PackedVector3Array([prediction.endpoint]),
	}
	var rigidbody := await DirectReachabilityValidator.validate_rigidbody_batches(
		self,
		materialized_root,
		cannon,
		terrain,
		layout,
		layout.containment.containment_bounds,
		predictor_contract,
		1
	)
	if not bool(rigidbody.get("valid", false)):
		await _free_materialized(materialized_root)
		return {
			"valid": false,
			"rejection": &"default_rigidbody",
			"evidence": rigidbody,
		}
	var outcome: Dictionary = rigidbody.outcomes[0]
	var rigidbody_identity: TrajectoryHitIdentity = outcome.identity
	var rigidbody_local := terrain.to_local(outcome.point)
	if not _is_centroid_near_top(rigidbody_identity, rigidbody_local, centroid_local):
		await _free_materialized(materialized_root)
		return {"valid": false, "rejection": &"rigidbody_centroid_or_identity"}
	var permit := StageMvpPermit.create(
		stage.stage_id,
		layout.profile_version,
		layout.terrain_seed,
		layout.accepted_seed,
		layout.checksum,
		layout.target_mask_checksum,
		layout.placement_checksum(),
		layout.containment.checksum(),
		aim,
		centroid_local,
		prediction.hit_identity,
		predictor_local,
		rigidbody_identity,
		rigidbody_local
	)
	layout.mvp_permit = permit
	var valid := permit.is_valid() and layout.is_mvp_playable()
	await _free_materialized(materialized_root)
	return {
		"valid": valid,
		"rejection": &"" if valid else &"permit_binding",
		"permit": permit,
		"layout": layout,
		"predictor": solved,
		"rigidbody": rigidbody,
	}


func _materialize(stage: StageData, layout: GeneratedStageLayout) -> Dictionary:
	var materialized_root := Node3D.new()
	materialized_root.name = "StageMvpPermitRoot"
	root.add_child(materialized_root)
	var terrain := TERRAIN_SCENE.instantiate() as TerrainSurface
	terrain.name = "TerrainSurface"
	terrain.position = stage.terrain_center
	materialized_root.add_child(terrain)
	terrain.configure(layout)
	var backstop := BACKSTOP_SCENE.instantiate() as BackstopEnvironment
	backstop.name = "BackstopEnvironment"
	materialized_root.add_child(backstop)
	backstop.configure(
		layout.containment,
		stage.paint_world_bounds(),
		stage.terrain_center.y + TerrainGeometryFactory.DEFAULT_BASE_Y
	)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	cannon.name = "Cannon"
	materialized_root.add_child(cannon)
	cannon.global_transform = stage.cannon_transform
	var mechanisms := Node3D.new()
	mechanisms.name = "Mechanisms"
	materialized_root.add_child(mechanisms)
	for placement_index in range(layout.mechanism_placements.size()):
		var placement := layout.mechanism_placements[placement_index]
		var packed_scene := _mechanism_scene(placement.mechanism_data.kind)
		if packed_scene == null:
			await _free_materialized(materialized_root)
			return {"valid": false, "rejection": &"mechanism_scene"}
		var mechanism := packed_scene.instantiate() as GimmickBase
		mechanism.name = "PermitMechanism%02d" % placement_index
		mechanism.data = placement.mechanism_data
		mechanism.transform = placement.local_transform
		mechanism.position += stage.terrain_center
		mechanisms.add_child(mechanism)
	await physics_frame
	return {
		"valid": true,
		"materialized_root": materialized_root,
		"terrain": terrain,
		"cannon": cannon,
	}


func _nearest_target_sample(layout: GeneratedStageLayout, centroid: Vector2) -> Dictionary:
	if not centroid.is_finite():
		return {"valid": false, "rejection": &"target_centroid"}
	var mask := layout.target_mask
	var mask_size := StageGenerationContract.REQUIRED_MASK_SIZE
	var best_distance := INF
	var best_pixel := Vector2i(-1, -1)
	var best_local := Vector2.ZERO
	for pixel_y in range(mask_size):
		for pixel_x in range(mask_size):
			if mask[pixel_y * mask_size + pixel_x] < 128:
				continue
			var normalized := Vector2(
				(float(pixel_x) + 0.5) / float(mask_size),
				(float(pixel_y) + 0.5) / float(mask_size)
			)
			var local := layout.local_bounds.position \
					+ normalized * layout.local_bounds.size
			var distance := local.distance_squared_to(centroid)
			if distance < best_distance:
				best_distance = distance
				best_pixel = Vector2i(pixel_x, pixel_y)
				best_local = local
	if best_pixel.x < 0:
		return {"valid": false, "rejection": &"empty_target"}
	var sample := layout.surface_sample_at_local(best_local.x, best_local.y, false)
	return {
		"valid": not sample.is_empty(),
		"rejection": &"" if not sample.is_empty() else &"target_surface",
		"pixel": best_pixel,
		"sample": sample,
	}


func _is_centroid_near_top(
		identity: TrajectoryHitIdentity,
		local_point: Vector3,
		centroid: Vector2
) -> bool:
	return identity != null and identity.is_valid() \
			and identity.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			and identity.contact_shape_id == TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID \
			and Vector2(local_point.x, local_point.z).distance_to(centroid) \
					<= StageMvpPermit.MAXIMUM_CENTROID_DISTANCE_METERS


func _mechanism_scene(kind: MechanismData.Kind) -> PackedScene:
	match kind:
		MechanismData.Kind.BURST:
			return BURST_SCENE
		MechanismData.Kind.SPLITTER:
			return SPLITTER_SCENE
		MechanismData.Kind.BUMPER:
			return BUMPER_SCENE
	return null


func _free_materialized(materialized_root: Node3D) -> void:
	if is_instance_valid(materialized_root):
		materialized_root.queue_free()
	await physics_frame


func _parse_arguments() -> Dictionary:
	var verify_only := false
	var write := false
	for argument in OS.get_cmdline_user_args():
		if argument == "--verify-only" and not verify_only and not write:
			verify_only = true
		elif argument == "--write-mvp-permit=%s" % PERMIT_PATH \
				and not verify_only and not write:
			write = true
		else:
			return {"valid": false, "rejection": &"unknown_or_conflicting_argument"}
	return {"valid": true, "verify_only": verify_only, "write": write}
