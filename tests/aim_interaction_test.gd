extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const BURST_SCENE := preload("res://scenes/mechanisms/burst_node.tscn")
const SPLITTER_SCENE := preload("res://scenes/mechanisms/splitter_node.tscn")
const BUMPER_SCENE := preload("res://scenes/mechanisms/bumper_node.tscn")
const BURST_DATA := preload("res://resources/mechanisms/burst_node.tres")
const SPLITTER_DATA := preload("res://resources/mechanisms/splitter_node.tres")
const BUMPER_DATA := preload("res://resources/mechanisms/bumper_node.tres")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const PAINT_SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")
const TERRAIN_FIXTURE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")

const AIM_CASES := [
	Vector3(-28, 18, 0), Vector3(-28, 43, 50), Vector3(-28, 68, 100),
	Vector3(-14, 28, 75), Vector3(-14, 58, 25), Vector3(0, 18, 100),
	Vector3(0, 43, 50), Vector3(0, 68, 0), Vector3(14, 28, 25),
	Vector3(28, 58, 75),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	root.size = Vector2i(1280, 720)
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var unlocked: Dictionary = root.get_node("/root/SaveSystem").default_data()
	unlocked.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(unlocked)
	var manual_only := "--manual-only" in OS.get_cmdline_user_args()
	await _check_manual_input(game_state)
	if not manual_only:
		await _check_stage_predictions(game_state)
		await _check_isolated_prediction_fixtures()
	game_state.persistence_enabled = true
	if not _failed:
		print(
			"Aim interaction passed: Aim Lock and Map Inspection input routing." \
			if manual_only else \
			"Task 06 aiming passed: manual input contract, stage predictions, mechanism casts, bounds exit, and preview cap."
		)
	quit(1 if _failed else 0)


func _check_manual_input(game_state: Node) -> void:
	_assert_true(game_state.select_stage(&"first_descent"), "First Descent must be selectable")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	var cannon: CannonController = gameplay.get_node("Cannon")
	var stage_controller: StageController = gameplay.get_node("StageController")
	var camera_director: CameraDirector = gameplay.get_node("CameraDirector")
	var aim_input: AimInputController = gameplay.get_node("AimInputController")
	var hud: HUDController = gameplay.get_node("HUD")
	_assert_true(stage_controller.begin_aiming(), "manual input fixture must begin in aiming")
	_assert_true(camera_director.aim_is_locked(), "Start must enter Aim Lock")
	var initial := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, false)
	_assert_aim(cannon, initial, "terrain/viewport click must not change aim")

	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	var drag := InputEventMouseMotion.new()
	drag.position = Vector2(660, 310)
	drag.relative = Vector2(20, -10)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(drag)
	await process_frame
	await _push_mouse_button(Vector2(660, 310), MOUSE_BUTTON_LEFT, false)
	_assert_aim(cannon, initial + Vector3(3.0, 1.2, 0.0), "empty viewport drag must change yaw and elevation independently")

	var before_key := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	await _push_key(KEY_D, true)
	_assert_aim(cannon, before_key + Vector3(0.5, 0, 0), "D press must apply one immediate yaw step")
	await create_timer(0.25).timeout
	_assert_aim(cannon, before_key + Vector3(0.5, 0, 0), "key hold must wait 300 ms")
	await create_timer(0.07).timeout
	_assert_aim(cannon, before_key + Vector3(1.0, 0, 0), "key hold must repeat at 300 ms")
	await create_timer(0.08).timeout
	_assert_aim(cannon, before_key + Vector3(1.5, 0, 0), "key hold must repeat every 80 ms")
	await _push_key(KEY_D, false)
	var before_echo := cannon.yaw_degrees
	await _push_key(KEY_D, true, true)
	_assert_close(cannon.yaw_degrees, before_echo, 0.0001, "OS key echo must not create a second step")
	var before_axis_keys := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	await _push_key(KEY_A, true)
	await _push_key(KEY_A, false)
	await _push_key(KEY_W, true)
	await _push_key(KEY_W, false)
	await _push_key(KEY_S, true)
	await _push_key(KEY_S, false)
	_assert_aim(cannon, before_axis_keys + Vector3(-0.5, 0.0, 0.0), "A/W/S must change only their requested angle axis")

	var before_wheel := cannon.power_percent
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_WHEEL_UP, true)
	_assert_close(cannon.power_percent, before_wheel + 1.0, 0.0001, "wheel up must add exactly 1% power")
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_WHEEL_DOWN, true)
	_assert_close(cannon.power_percent, before_wheel, 0.0001, "wheel down must subtract exactly 1% power")

	var decrease := hud.find_child("PowerDecrease", true, false) as Button
	_assert_true(decrease != null, "HUD must expose the power decrement button")
	if decrease != null:
		var before_ui := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
		var center := decrease.get_screen_transform() * (decrease.size * 0.5)
		await _push_mouse_button(center, MOUSE_BUTTON_LEFT, true)
		await _push_mouse_button(center, MOUSE_BUTTON_LEFT, false)
		_assert_aim(cannon, before_ui + Vector3(0, 0, -2.0), "UI power click must change only power and never begin an aim drag")
		var before_hold := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
		await _push_mouse_button(center, MOUSE_BUTTON_LEFT, true)
		await create_timer(0.25).timeout
		_assert_aim(cannon, before_hold + Vector3(0, 0, -2.0), "power button hold must wait 300 ms")
		await create_timer(0.07).timeout
		_assert_aim(cannon, before_hold + Vector3(0, 0, -4.0), "power button hold must repeat at 300 ms")
		await create_timer(0.08).timeout
		_assert_aim(cannon, before_hold + Vector3(0, 0, -6.0), "power button hold must repeat every 80 ms")
		await _push_mouse_button(center, MOUSE_BUTTON_LEFT, false)
		var before_focus := cannon.power_percent
		decrease.grab_focus()
		await _push_key(KEY_ENTER, true)
		await _push_key(KEY_ENTER, false)
		_assert_close(cannon.power_percent, before_focus - 2.0, 0.0001, "focused power button must activate through keyboard")

	cannon.set_aim(AimTuple.MAXIMUM_YAW_DEGREES, AimTuple.MAXIMUM_ELEVATION_DEGREES, 100.0)
	await _push_key(KEY_D, true)
	await _push_key(KEY_D, false)
	await _push_key(KEY_W, true)
	await _push_key(KEY_W, false)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_WHEEL_UP, true)
	_assert_aim(
		cannon,
		Vector3(AimTuple.MAXIMUM_YAW_DEGREES, AimTuple.MAXIMUM_ELEVATION_DEGREES, 100.0),
		"manual inputs must clamp to the legal maxima"
	)
	cannon.set_aim(AimTuple.MINIMUM_YAW_DEGREES, AimTuple.MINIMUM_ELEVATION_DEGREES, 0.0)
	await _push_key(KEY_A, true)
	await _push_key(KEY_A, false)
	await _push_key(KEY_S, true)
	await _push_key(KEY_S, false)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_WHEEL_DOWN, true)
	_assert_aim(
		cannon,
		Vector3(AimTuple.MINIMUM_YAW_DEGREES, AimTuple.MINIMUM_ELEVATION_DEGREES, 0.0),
		"manual inputs must clamp to the legal minima"
	)

	var aim_before_inspection := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	await _push_key(KEY_TAB, true)
	await _push_key(KEY_TAB, false)
	_assert_true(
		stage_controller.current_state == StageController.State.AIMING \
				and camera_director.current_interaction_mode == CameraDirector.InteractionMode.MAP_INSPECTION,
		"Tab must enter Map Inspection without leaving the Board Phase"
	)
	var inspection_distance_before := camera_director.inspection_distance()
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_WHEEL_UP, true)
	_assert_true(
		camera_director.inspection_distance() < inspection_distance_before,
		"wheel input must zoom the inspection camera"
	)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	var inspection_drag := InputEventMouseMotion.new()
	inspection_drag.position = Vector2(680, 300)
	inspection_drag.relative = Vector2(40, -20)
	inspection_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(inspection_drag)
	await process_frame
	await _push_mouse_button(Vector2(680, 300), MOUSE_BUTTON_LEFT, false)
	await _push_key(KEY_D, true)
	await _push_key(KEY_D, false)
	_assert_true(not aim_input.request_fire(), "Map Inspection must block Fire")
	_assert_aim(cannon, aim_before_inspection, "Map Inspection must not mutate the stored aim")
	await _push_key(KEY_TAB, true)
	await _push_key(KEY_TAB, false)
	_assert_true(camera_director.aim_is_locked(), "Tab must return to Aim Lock")
	_assert_aim(cannon, aim_before_inspection, "returning to Aim Lock must restore the same aim")
	_assert_true(
		stage_controller.lock_action_origin(StageController.ActionOrigin.REPLAY),
		"replay lock fixture must acquire the action origin"
	)
	await _push_key(KEY_TAB, true)
	await _push_key(KEY_TAB, false)
	_assert_true(camera_director.aim_is_locked(), "replay lock must block human mode switching")
	_assert_true(
		stage_controller.release_action_origin(StageController.ActionOrigin.REPLAY),
		"replay lock fixture must release the action origin"
	)
	var admitted_aim: AimTuple = gameplay.generated_layout().default_aim
	cannon.set_aim(admitted_aim.yaw_degrees, admitted_aim.elevation_degrees, float(admitted_aim.power_percent))
	await create_timer(0.12).timeout
	var fired := {"count": 0}
	stage_controller.shot_fired.connect(func(_number: int, _yaw: float, _elevation: float, _power: float) -> void:
		fired.count += 1
	)
	var shots_before := stage_controller.shots_remaining
	var fire_button := hud.find_child("FireButton", true, false) as Button
	_assert_true(fire_button != null, "HUD must expose the Fire button")
	if fire_button != null:
		var fire_center := fire_button.get_screen_transform() * (fire_button.size * 0.5)
		await _push_mouse_button(fire_center, MOUSE_BUTTON_LEFT, true)
		await _push_mouse_button(fire_center, MOUSE_BUTTON_LEFT, false)
		_assert_true(fired.count == 1, "Fire button must request exactly one shot")
		_assert_true(stage_controller.shots_remaining == shots_before - 1, "Fire button must consume one shot")
		stage_controller.restart(false)
		fired.count = 0
		shots_before = stage_controller.shots_remaining
	await _push_key(KEY_SPACE, true)
	await _push_key(KEY_SPACE, true, true)
	_assert_true(fired.count == 1, "Space press plus echo must fire exactly once")
	_assert_true(stage_controller.shots_remaining == shots_before - 1, "one Space press must consume one shot")
	gameplay.queue_free()
	await process_frame


func _check_stage_predictions(game_state: Node) -> void:
	for stage_id in [&"first_descent", &"burst_basin", &"split_ridge"]:
		_assert_true(game_state.select_stage(stage_id), "%s must be selectable" % stage_id)
		var gameplay := GAMEPLAY_SCENE.instantiate()
		root.add_child(gameplay)
		await physics_frame
		await process_frame
		var cannon: CannonController = gameplay.get_node("Cannon")
		var preview: TrajectoryPreview = gameplay.get_node("TrajectoryPreview")
		var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
		for aim in AIM_CASES:
			cannon.set_aim(aim.x, aim.y, aim.z)
			await create_timer(0.06).timeout
			var prediction := cannon.current_prediction()
			_assert_true(prediction != null, "%s %s must produce a prediction" % [stage_id, aim])
			if prediction == null:
				continue
			_assert_true(prediction.kind != TrajectoryPrediction.Kind.TIMEOUT, "%s %s must end at collision or bounds" % [stage_id, aim])
			_assert_true(preview.visible_sample_count() <= 96, "%s %s preview must use at most 96 dots" % [stage_id, aim])
			_assert_preview_endpoints(preview, cannon.get_launch_origin(), prediction.endpoint, "%s %s" % [stage_id, aim])
			var actual := await _run_actual_first_event(manager, cannon)
			_assert_true(not actual.is_empty(), "%s %s runtime must produce a first event" % [stage_id, aim])
			if actual.is_empty():
				continue
			_assert_true(int(actual.kind) == prediction.kind, "%s %s preview/runtime event kind must agree" % [stage_id, aim])
			_assert_true(Vector3(actual.endpoint).distance_to(prediction.endpoint) <= 2.0, "%s %s preview/runtime endpoint must agree within 2 m" % [stage_id, aim])
			if prediction.kind == TrajectoryPrediction.Kind.COLLISION:
				_assert_true(actual.collider == prediction.collider, "%s %s preview/runtime collider must agree (actual=%s type=%s predicted=%s type=%s)" % [stage_id, aim, actual.collider, typeof(actual.collider), prediction.collider, typeof(prediction.collider)])
			manager.cleanup()
			await process_frame
		gameplay.queue_free()
		await process_frame


func _run_actual_first_event(manager: ProjectileManager, cannon: CannonController) -> Dictionary:
	var origin := cannon.get_launch_origin()
	var velocity := cannon.get_launch_velocity()
	var projectile := manager.spawn_projectile(
		cannon.projectile_data, origin, velocity
	)
	_assert_true(projectile != null, "runtime prediction fixture must spawn its projectile")
	if projectile == null:
		return {}
	projectile.freeze = true
	var position := origin
	var gravity_magnitude := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var gravity_direction := Vector3(ProjectSettings.get_setting("physics/3d/default_gravity_vector", Vector3.DOWN)).normalized()
	var gravity := gravity_direction * gravity_magnitude
	for _frame in range(720):
		velocity *= maxf(1.0 - cannon.projectile_data.linear_damp / 60.0, 0.0)
		velocity += gravity / 60.0
		var next_position := position + velocity / 60.0
		var parameters := PhysicsTestMotionParameters3D.new()
		parameters.from = Transform3D(Basis.IDENTITY, position)
		parameters.motion = next_position - position
		parameters.max_collisions = 1
		var motion_result := PhysicsTestMotionResult3D.new()
		if PhysicsServer3D.body_test_motion(projectile.get_rid(), parameters, motion_result):
			return {
				"kind": TrajectoryPrediction.Kind.COLLISION,
				"endpoint": motion_result.get_collision_point(0),
				"normal": motion_result.get_collision_normal(0),
				"collider": motion_result.get_collider(0),
			}
		var exit_fraction := _bounds_exit_fraction(position, next_position, projectile.stage_bounds)
		if exit_fraction < 1.0:
			return {
				"kind": TrajectoryPrediction.Kind.BOUNDS_EXIT,
				"endpoint": position.lerp(next_position, exit_fraction),
				"normal": Vector3.ZERO,
				"collider": null,
			}
		position = next_position
	return {}


func _check_isolated_prediction_fixtures() -> void:
	var fixture_root := Node3D.new()
	root.add_child(fixture_root)
	var terrain := TERRAIN_FIXTURE.instantiate() as TerrainSurface
	fixture_root.add_child(terrain)
	terrain.configure(TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT))
	var manager := ProjectileManager.new()
	fixture_root.add_child(manager)
	manager.configure_terrain(terrain)
	var paint := PaintSystem.new()
	fixture_root.add_child(paint)
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	var target_mask := PackedByteArray()
	target_mask.resize(PaintSystem.MASK_SIZE * PaintSystem.MASK_SIZE)
	target_mask.fill(255)
	_assert_true(layout.install_target_mask(target_mask, TargetMaskRasterizer.byte_checksum(target_mask)), "aim fixture target mask must install exactly once")
	paint.configure(
		layout.local_bounds, 0.0, null, Color.BLUE, layout, PAINT_SURFACE_TUNING
	)
	var top_body := terrain.get_node("TerrainTopBody") as StaticBody3D
	paint.configure_top_surface_identity(
		top_body.get_rid(),
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID,
		0
	)
	var fixtures := [
		[BURST_SCENE, BURST_DATA, Vector3(-8, 0, -6), Vector3(-8, 2, 4), Vector3(0, 0, -40)],
		[SPLITTER_SCENE, SPLITTER_DATA, Vector3.ZERO, Vector3(0, 8, 0), Vector3(0, -40, 0)],
		[BUMPER_SCENE, BUMPER_DATA, Vector3(8, 0, -6), Vector3(8, 8, -6), Vector3(0, -30, 0)],
	]
	for fixture in fixtures:
		var mechanism := (fixture[0] as PackedScene).instantiate() as GimmickBase
		mechanism.data = fixture[1]
		mechanism.position = fixture[2]
		mechanism.configure(manager, paint)
		fixture_root.add_child(mechanism)
		if mechanism is SplitterNode:
			mechanism.configure_route_targets(PackedVector3Array([Vector3(-7, 0, -12), Vector3(0, 0, -13), Vector3(7, 0, -12)]), Vector3(0, 0, -1))
		elif mechanism is BumperNode:
			mechanism.configure_downstream_tangent(Vector3(0, 0, -1))
		await physics_frame
		var prediction := TrajectoryPredictor.predict_motion(
			root.get_world_3d().direct_space_state,
			fixture[3], fixture[4], PROJECTILE_DATA.radius,
			PROJECTILE_DATA.linear_damp,
			AABB(Vector3(-24, -12, -24), Vector3(48, 48, 48))
		)
		_assert_true(prediction.kind == TrajectoryPrediction.Kind.COLLISION, "%s predictor fixture must collide" % mechanism.name)
		_assert_true(prediction.collider == mechanism.mechanism_body(), "%s predictor must return the physical mechanism body (actual=%s expected=%s)" % [mechanism.name, prediction.collider, mechanism.mechanism_body()])
		_assert_true(not prediction.normal.is_zero_approx(), "%s predictor collision must return a measured normal" % mechanism.name)
		mechanism.queue_free()
		await process_frame

	var bounds := AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	var exit_prediction := TrajectoryPredictor.predict_motion(
		root.get_world_3d().direct_space_state,
		Vector3.ZERO, Vector3(20, 0, 0), PROJECTILE_DATA.radius,
		PROJECTILE_DATA.linear_damp, bounds, 0
	)
	_assert_true(exit_prediction.kind == TrajectoryPrediction.Kind.BOUNDS_EXIT, "empty fixture must classify a bounds exit")
	_assert_close(exit_prediction.endpoint.x, 2.0, 0.001, "bounds exit must stop at the first boundary crossing")
	_assert_true(exit_prediction.normal.is_zero_approx() and not exit_prediction.is_fireable(), "bounds exit must have no normal and remain non-fireable")
	var timeout_prediction := TrajectoryPredictor.predict_motion(
		root.get_world_3d().direct_space_state,
		Vector3.ZERO, Vector3.ZERO, PROJECTILE_DATA.radius,
		PROJECTILE_DATA.linear_damp,
		AABB(Vector3(-10000, -10000, -10000), Vector3.ONE * 20000), 0
	)
	_assert_true(timeout_prediction.kind == TrajectoryPrediction.Kind.TIMEOUT, "12-second empty-space fixture must classify timeout")
	_assert_true(not timeout_prediction.is_fireable() and timeout_prediction.diagnostic == &"maximum_duration", "timeout must retain diagnostics and remain non-fireable")
	var timeout_cannon := CannonController.new()
	timeout_cannon.projectile_data = PROJECTILE_DATA
	timeout_cannon.set_prediction(timeout_prediction)
	_assert_true(not timeout_cannon.request_fire(), "Cannon fire guard must reject a timeout prediction")
	timeout_cannon.free()
	fixture_root.queue_free()
	await process_frame


func _bounds_exit_fraction(start: Vector3, finish: Vector3, bounds: AABB) -> float:
	if not bounds.has_point(start):
		return 0.0
	if bounds.has_point(finish):
		return 1.0
	var motion := finish - start
	var result := 1.0
	for axis in range(3):
		if is_zero_approx(motion[axis]):
			continue
		var boundary := bounds.position[axis] if finish[axis] < bounds.position[axis] else bounds.end[axis]
		var fraction := (boundary - start[axis]) / motion[axis]
		if fraction >= 0.0:
			result = minf(result, fraction)
	return clampf(result, 0.0, 1.0)


func _assert_preview_endpoints(preview: TrajectoryPreview, origin: Vector3, endpoint: Vector3, label: String) -> void:
	var visible_dots: Array[MeshInstance3D] = []
	for child in preview.get_children():
		if child is MeshInstance3D and child.name.begins_with("TrajectoryDot") and child.visible:
			visible_dots.append(child)
	_assert_true(not visible_dots.is_empty(), "%s preview must contain its launch dot" % label)
	if visible_dots.is_empty():
		return
	_assert_true(visible_dots.front().global_position.distance_to(origin) <= 0.001, "%s preview must begin at the launch origin" % label)
	_assert_true(visible_dots.back().global_position.distance_to(endpoint) <= 0.001, "%s preview must include the exact endpoint" % label)


func _push_key(keycode: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame


func _push_mouse_button(position: Vector2, button_index: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button_index
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _assert_aim(cannon: CannonController, expected: Vector3, message: String) -> void:
	var actual := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	_assert_true(
		actual.is_equal_approx(expected),
		"%s (actual %s, expected %s)" % [message, actual, expected]
	)


func _assert_close(actual: float, expected: float, tolerance: float, message: String) -> void:
	_assert_true(absf(actual - expected) <= tolerance, "%s (actual %.5f, expected %.5f)" % [message, actual, expected])


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Task 06 aim check failed: %s" % message)
