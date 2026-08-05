extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const TERRAIN_FIXTURE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const STAGES: Array[StageData] = [
	preload("res://resources/stages/first_descent.tres"),
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]
const VERTICAL_FOV_DEGREES := 50.0
const ASPECT_RATIO := 16.0 / 9.0

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	root.size = Vector2i(1280, 720)
	await _check_generated_terrain_framing()
	await _check_coalesced_runtime_work()
	if not _failed:
		print("Phase 7 user-QA contract passed: generated terrain framing, static-camera caching, and latest-aim fire refresh.")
	quit(1 if _failed else 0)


func _check_generated_terrain_framing() -> void:
	for stage in STAGES:
		var layout := SeededStageGenerator.generate(
			stage.generation_profile,
			stage.terrain_seed,
			stage
		)
		_assert_true(layout != null and layout.is_valid(), "%s must retain its accepted generated layout" % stage.stage_id)
		if layout == null:
			continue
		var geometry := TerrainGeometryFactory.build(layout)
		var world_bounds := Transform3D(Basis.IDENTITY, stage.terrain_center) \
				* geometry.render_mesh.get_aabb()
		var bounds_center := world_bounds.get_center()
		var center_local_xz := Vector2(
			bounds_center.x - stage.terrain_center.x,
			bounds_center.z - stage.terrain_center.z
		)
		var frame_focus := Vector3(
			bounds_center.x,
			stage.terrain_center.y + layout.height_at_local(center_local_xz.x, center_local_xz.y) + 0.25,
			bounds_center.z
		)
		var authored_poses: Array[Array] = [
			[stage.briefing_camera_position, stage.briefing_camera_target],
			[stage.wide_camera_position, stage.wide_camera_target],
			[stage.result_camera_position, stage.result_camera_target],
		]
		for authored in authored_poses:
			var pose := TerrainCameraFramer.framed_pose_around(
				world_bounds,
				frame_focus,
				authored[0],
				authored[1],
				VERTICAL_FOV_DEGREES,
				ASPECT_RATIO
			)
			_assert_bounds_inside_frustum(String(stage.stage_id), world_bounds, pose[0], pose[1])

		var fixture_root := Node3D.new()
		root.add_child(fixture_root)
		var terrain := TERRAIN_FIXTURE.instantiate() as TerrainSurface
		terrain.position = stage.terrain_center
		fixture_root.add_child(terrain)
		terrain.configure(layout)
		var camera := Camera3D.new()
		camera.fov = VERTICAL_FOV_DEGREES
		fixture_root.add_child(camera)
		var manager := ProjectileManager.new()
		fixture_root.add_child(manager)
		var director := CameraDirector.new()
		fixture_root.add_child(director)
		await physics_frame
		director.configure(camera, stage, manager, terrain)
		for mode in [CameraDirector.Mode.BRIEFING, CameraDirector.Mode.WIDE, CameraDirector.Mode.RESULT]:
			director.set_mode(mode, true)
			_assert_bounds_inside_frustum(
				"%s %s" % [stage.stage_id, CameraDirector.Mode.keys()[mode]],
				terrain.render_world_aabb(),
				camera.global_position,
				director.camera_focus_position()
			)
		fixture_root.queue_free()
		await process_frame


func _check_coalesced_runtime_work() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	_assert_true(game_state.select_stage(&"first_descent"), "Stage 1 must be selectable")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	await process_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var director: CameraDirector = gameplay.get_node("CameraDirector")
	var layout: GeneratedStageLayout = gameplay.generated_layout()
	_assert_true(controller.begin_aiming(), "Phase 7 runtime fixture must enter aiming")
	director.set_mode(CameraDirector.Mode.AIMING, true)
	var settled_safety_count := director.safety_solve_count()
	for _tick in range(12):
		await physics_frame
	_assert_true(
		director.safety_solve_count() == settled_safety_count,
		"a settled Aiming camera must reuse its safe pose without repeated terrain solves"
	)

	var default_aim: AimTuple = layout.default_aim
	var alternate_yaw := default_aim.yaw_degrees + 0.5 \
			if default_aim.yaw_degrees <= 44.0 else default_aim.yaw_degrees - 0.5
	var prediction_count: int = gameplay.prediction_compute_count()
	_assert_true(
		controller.set_aim(alternate_yaw, default_aim.elevation_degrees, float(default_aim.power_percent))
				and controller.set_aim(default_aim.yaw_degrees, default_aim.elevation_degrees, float(default_aim.power_percent))
				and controller.set_aim(alternate_yaw, default_aim.elevation_degrees, float(default_aim.power_percent))
				and controller.set_aim(default_aim.yaw_degrees, default_aim.elevation_degrees, float(default_aim.power_percent)),
		"multiple canonical aim updates must be accepted in one refresh interval"
	)
	_assert_true(
		gameplay.prediction_compute_count() == prediction_count and cannon.current_prediction() == null,
		"same-interval aim updates must schedule rather than synchronously repeat trajectory casts"
	)
	var fired := {"aim": Vector3.ZERO}
	controller.shot_fired.connect(func(_shot: int, yaw: float, elevation: float, power: float) -> void:
		fired.aim = Vector3(yaw, elevation, power)
	)
	_assert_true(not controller.request_fire(), "pending Fire must reject instead of synchronously solving on the Fire path")
	_assert_true(
		gameplay.prediction_compute_count() == prediction_count,
		"pending Fire must not add a synchronous trajectory solve"
	)
	var readiness_budget := 30
	while not cannon.is_aim_valid() and readiness_budget > 0:
		await process_frame
		readiness_budget -= 1
	_assert_true(readiness_budget > 0, "latest aim must publish a matching prediction after the coalesced refresh")
	_assert_true(
		gameplay.prediction_compute_count() == prediction_count + 1,
		"coalesced prediction must perform exactly one latest-aim solve"
	)
	_assert_true(controller.request_fire(), "Fire must succeed once the matching prediction is ready")
	_assert_true(
		Vector3(fired.aim).is_equal_approx(Vector3(
			default_aim.yaw_degrees,
			default_aim.elevation_degrees,
			float(default_aim.power_percent)
		)),
		"the spawned shot must use the latest canonical yaw, elevation, and power"
	)
	_assert_true(manager.active_count() == 1, "latest-aim fire validation must create one physical projectile")
	manager.cleanup()
	gameplay.queue_free()
	await process_frame
	await process_frame
	game_state.persistence_enabled = true


func _assert_bounds_inside_frustum(
		label: String,
		bounds: AABB,
		camera_position: Vector3,
		focus: Vector3
) -> void:
	var forward := (focus - camera_position).normalized()
	var reference_up := Vector3.FORWARD if absf(forward.dot(Vector3.UP)) > 0.98 else Vector3.UP
	var right := forward.cross(reference_up).normalized()
	var up := right.cross(forward).normalized()
	var vertical_tangent := tan(deg_to_rad(VERTICAL_FOV_DEGREES * 0.5))
	var horizontal_tangent := vertical_tangent * ASPECT_RATIO
	for corner in TerrainCameraFramer.bounds_corners(bounds):
		var relative := corner - camera_position
		var depth := relative.dot(forward)
		_assert_true(depth > 0.0, "%s framed terrain corner must remain in front of the camera" % label)
		_assert_true(
			absf(relative.dot(right)) <= depth * horizontal_tangent + 0.001,
			"%s framed terrain must fit horizontally" % label
		)
		_assert_true(
			absf(relative.dot(up)) <= depth * vertical_tangent + 0.001,
			"%s framed terrain must fit vertically" % label
		)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Phase 7 user-QA contract failed: %s" % message)
