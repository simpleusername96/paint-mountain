extends SceneTree

const TERRAIN_FIXTURE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const STAGES: Array[StageData] = [
	preload("res://resources/stages/first_descent.tres"),
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]
const VIEWPORT_SIZE := Vector2i(1280, 720)
const VERTICAL_FOV_DEGREES := 55.0
const ASPECT_RATIO := 16.0 / 9.0
const FRUSTUM_EPSILON := 0.002
const MAXIMUM_AUTHORED_DISTANCE_RATIO := 1.35

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	root.size = VIEWPORT_SIZE
	for stage in STAGES:
		await _check_stage(stage)
	if not _failed:
		print("Phase 8 aiming composition passed: close authored views retain cannon and first impact for all stages.")
	quit(1 if _failed else 0)


func _check_stage(stage: StageData) -> void:
	var generation_started := Time.get_ticks_usec()
	var layout := SeededStageGenerator.generate_structural_sequence(
		stage.generation_profile,
		stage.terrain_seed,
		stage
	)
	_assert_true(layout != null and layout.is_valid(), "%s must generate a valid layout" % stage.stage_id)
	if layout == null:
		return
	var generation_ms := float(Time.get_ticks_usec() - generation_started) / 1000.0

	var fixture_root := Node3D.new()
	root.add_child(fixture_root)
	var terrain := TERRAIN_FIXTURE.instantiate() as TerrainSurface
	terrain.position = stage.terrain_center
	fixture_root.add_child(terrain)
	terrain.configure(layout)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	fixture_root.add_child(cannon)
	cannon.global_transform = stage.cannon_transform
	var camera := Camera3D.new()
	camera.fov = VERTICAL_FOV_DEGREES
	fixture_root.add_child(camera)
	var manager := ProjectileManager.new()
	fixture_root.add_child(manager)
	var director := CameraDirector.new()
	fixture_root.add_child(director)
	await physics_frame

	var aim_started := Time.get_ticks_usec()
	var runtime_aim := DefaultAimSolver.find_runtime_aim(
		camera.get_world_3d().direct_space_state,
		cannon,
		terrain,
		layout
	)
	var aim_ms := float(Time.get_ticks_usec() - aim_started) / 1000.0
	print("%s initialization timing generation=%.2f ms aim=%.2f ms" % [
		stage.stage_id, generation_ms, aim_ms,
	])
	_assert_true(runtime_aim != null, "%s must derive a bounded runtime default aim" % stage.stage_id)
	if runtime_aim == null:
		fixture_root.queue_free()
		await process_frame
		return
	cannon.set_aim(
		runtime_aim.yaw_degrees,
		runtime_aim.elevation_degrees,
		float(runtime_aim.power_percent)
	)
	var prediction := TrajectoryPredictor.predict(
		camera.get_world_3d().direct_space_state,
		cannon,
		layout.containment.containment_bounds
	)
	_assert_true(
		prediction != null and prediction.is_fireable(),
		"%s runtime default aim must retain its first impact" % stage.stage_id
	)
	director.configure(camera, stage, manager, terrain)
	director.set_mode(CameraDirector.Mode.AIMING, true)
	var focus := director.camera_focus_position()
	print("%s aiming pose authored=%s -> %s final=%s -> %s" % [
		stage.stage_id,
		stage.aiming_camera_position,
		stage.aiming_camera_target,
		camera.global_position,
		focus,
	])
	_assert_points_inside_frustum(
		"%s cannon base" % stage.stage_id,
		[cannon.global_position],
		camera.global_position,
		focus
	)
	_assert_points_inside_frustum(
		"%s muzzle" % stage.stage_id,
		[cannon.get_launch_origin()],
		camera.global_position,
		focus
	)
	_assert_points_inside_frustum(
		"%s first impact" % stage.stage_id,
		[prediction.endpoint],
		camera.global_position,
		focus
	)
	var authored_distance := stage.aiming_camera_position.distance_to(stage.aiming_camera_target)
	_assert_true(
		camera.global_position.distance_to(focus) <= authored_distance * MAXIMUM_AUTHORED_DISTANCE_RATIO,
		"%s aiming camera must stay near authored scale instead of backing out to full-terrain framing" % stage.stage_id
	)
	_assert_camera_outside_terrain(String(stage.stage_id), camera.global_position, terrain)
	var surface_focus := terrain.contains_world_xz(Vector2(focus.x, focus.z)) \
			and focus.distance_to(terrain.world_surface_point(Vector2(focus.x, focus.z))) <= 0.3
	_assert_true(
		director.view_ray_is_clear(camera.global_position, focus, surface_focus),
		"%s final aiming focus ray must not cross an intervening terrain face" % stage.stage_id
	)

	fixture_root.queue_free()
	await process_frame


func _assert_points_inside_frustum(
		label: String,
		points: Array[Vector3],
		camera_position: Vector3,
		focus: Vector3
) -> void:
	var basis := _view_basis(camera_position, focus)
	var forward: Vector3 = basis[0]
	var right: Vector3 = basis[1]
	var up: Vector3 = basis[2]
	var vertical_tangent := tan(deg_to_rad(VERTICAL_FOV_DEGREES * 0.5))
	var horizontal_tangent := vertical_tangent * ASPECT_RATIO
	for point in points:
		var relative := point - camera_position
		var depth := relative.dot(forward)
		_assert_true(depth > 0.0, "%s framed point must remain in front of the camera" % label)
		_assert_true(
			absf(relative.dot(right)) <= depth * horizontal_tangent + FRUSTUM_EPSILON,
			"%s framed point must fit horizontally" % label
		)
		_assert_true(
			absf(relative.dot(up)) <= depth * vertical_tangent + FRUSTUM_EPSILON,
			"%s framed point must fit vertically" % label
		)


func _assert_camera_outside_terrain(label: String, camera_position: Vector3, terrain: TerrainSurface) -> void:
	if not terrain.contains_world_xz(Vector2(camera_position.x, camera_position.z)):
		return
	var surface_y := terrain.world_surface_point(Vector2(camera_position.x, camera_position.z)).y
	_assert_true(
		camera_position.y - surface_y >= CameraDirector.CAMERA_CLEARANCE - FRUSTUM_EPSILON,
		"%s aiming camera must retain terrain clearance" % label
	)


func _view_basis(camera_position: Vector3, focus: Vector3) -> Array[Vector3]:
	var forward := (focus - camera_position).normalized()
	var reference_up := Vector3.FORWARD if absf(forward.dot(Vector3.UP)) > 0.98 else Vector3.UP
	var right := forward.cross(reference_up).normalized()
	return [forward, right, right.cross(forward).normalized()]


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Phase 8 aiming composition failed: %s" % message)
