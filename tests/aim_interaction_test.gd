extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	root.size = Vector2i(1280, 720)
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var save_data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	save_data.unlocked_stages = ["first_descent"]
	game_state.initialize_from_data(save_data)
	_assert_true(game_state.select_stage(&"first_descent"), "First Descent must be selectable")

	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	await _check_aim_and_inspection_input(gameplay)
	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true

	if not _failed:
		print("Aim interaction passed: representative Aim Lock and Map Inspection input routing.")
	quit(1 if _failed else 0)


func _check_aim_and_inspection_input(gameplay: Node) -> void:
	var cannon: CannonController = gameplay.get_node("Cannon")
	var camera: Camera3D = gameplay.get_node("Camera")
	var stage_controller: StageController = gameplay.get_node("StageController")
	var camera_director: CameraDirector = gameplay.get_node("CameraDirector")
	var aim_input: AimInputController = gameplay.get_node("AimInputController")
	_assert_true(stage_controller.begin_aiming(), "input fixture must enter the aiming phase")
	camera_director.set_mode(CameraDirector.Mode.AIMING, true)
	_assert_true(camera_director.aim_is_locked(), "aiming must begin in Aim Lock")

	# The shared ballistic convention must agree with what the authored aiming
	# camera presents: increasing yaw moves the shot toward screen right.
	var center_screen := _screen_position_for_yaw(camera, cannon, 0.0)
	var right_screen := _screen_position_for_yaw(camera, cannon, 16.0)
	_assert_true(
		right_screen.x > center_screen.x,
		"positive yaw must move the trajectory toward screen right"
	)

	cannon.set_aim(0.0, 38.0, 50.0)
	var interaction_states: Array[bool] = []
	aim_input.aim_interaction_changed.connect(
		func(active: bool) -> void: interaction_states.append(active)
	)
	var before_click := _aim(cannon)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, false)
	_assert_aim_unchanged(cannon, before_click, "a click without dragging must preserve aim")
	_assert_true(
		interaction_states == [true, false],
		"pointer press/release must expose one interaction interval to prediction scheduling"
	)

	# Four motions that are each too small for the canonical 0.1-degree step must
	# retain their shared remainder and equal one combined physical motion.
	cannon.set_aim(0.0, 38.0, 50.0)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	for _index in range(4):
		await _push_aim_motion(Vector2(0.1, 0.0))
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, false)
	var accumulated_yaw := cannon.yaw_degrees
	cannon.set_aim(0.0, 38.0, 50.0)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	await _push_aim_motion(Vector2(0.4, 0.0))
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, false)
	_assert_true(
		is_equal_approx(cannon.yaw_degrees, accumulated_yaw) \
				and accumulated_yaw > 0.0,
		"sub-step pointer motion must equal one combined motion instead of being discarded"
	)

	# screen_relative is already physical motion. Changing the viewport must not
	# add a second scaling factor.
	root.size = Vector2i(1280, 720)
	cannon.set_aim(0.0, 38.0, 50.0)
	await _perform_aim_drag(Vector2(10.0, 0.0))
	var yaw_1280 := cannon.yaw_degrees
	root.size = Vector2i(1920, 1080)
	cannon.set_aim(0.0, 38.0, 50.0)
	await _perform_aim_drag(Vector2(10.0, 0.0))
	var yaw_1920 := cannon.yaw_degrees
	_assert_true(
		is_equal_approx(yaw_1280, yaw_1920),
		"equal physical screen motion must produce equal aim at both resolutions"
	)
	root.size = Vector2i(1280, 720)
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.update_setting(&"aim_sensitivity_percent", 50, false)
	cannon.set_aim(0.0, 38.0, 50.0)
	await _perform_aim_drag(Vector2(10.0, 0.0))
	_assert_true(
		is_equal_approx(cannon.yaw_degrees, 0.8) \
				and aim_input.sensitivity_percent() == 50,
		"50% sensitivity must scale pointer aim only"
	)
	game_state.update_setting(&"aim_sensitivity_percent", 100, false)

	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	var aim_drag := InputEventMouseMotion.new()
	aim_drag.position = Vector2(680, 300)
	aim_drag.relative = Vector2(40, -20)
	aim_drag.screen_relative = Vector2(40, -20)
	aim_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(aim_drag)
	await process_frame
	await _push_mouse_button(Vector2(680, 300), MOUSE_BUTTON_LEFT, false)
	_assert_true(
		cannon.yaw_degrees > before_click.x and cannon.elevation_degrees > before_click.y,
		"right/up drag in Aim Lock must increase yaw/elevation"
	)

	var yaw_before_key := cannon.yaw_degrees
	await _push_key(KEY_D, true)
	await _push_key(KEY_D, false)
	_assert_true(cannon.yaw_degrees > yaw_before_key, "D must move aim toward screen right")
	var power_before_wheel := cannon.power_percent
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_WHEEL_UP, true)
	_assert_true(cannon.power_percent > power_before_wheel, "wheel up in Aim Lock must increase power")

	var aim_before_inspection := _aim(cannon)
	await _push_key(KEY_TAB, true)
	await _push_key(KEY_TAB, false)
	_assert_true(
		stage_controller.current_state == StageController.State.AIMING \
				and camera_director.current_interaction_mode == CameraDirector.InteractionMode.MAP_INSPECTION,
		"Tab must enter Map Inspection without leaving the aiming phase"
	)

	var distance_before_zoom := camera_director.inspection_distance()
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_WHEEL_UP, true)
	_assert_true(
		camera_director.inspection_distance() < distance_before_zoom,
		"wheel up in Map Inspection must zoom toward the map"
	)
	var camera_before_orbit := camera.global_position
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	var orbit_drag := InputEventMouseMotion.new()
	orbit_drag.position = Vector2(700, 330)
	orbit_drag.relative = Vector2(60, 10)
	orbit_drag.screen_relative = Vector2(60, 10)
	orbit_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(orbit_drag)
	await physics_frame
	await process_frame
	await _push_mouse_button(Vector2(700, 330), MOUSE_BUTTON_LEFT, false)
	_assert_true(
		camera.global_position.distance_to(camera_before_orbit) > 0.01,
		"left drag in Map Inspection must orbit the camera"
	)
	await _push_key(KEY_D, true)
	await _push_key(KEY_D, false)
	_assert_true(not aim_input.request_fire(), "Map Inspection must block Fire")
	_assert_aim_unchanged(cannon, aim_before_inspection, "Map Inspection must not change stored aim")

	await _push_key(KEY_TAB, true)
	await _push_key(KEY_TAB, false)
	_assert_true(camera_director.aim_is_locked(), "Tab must return to Aim Lock")
	_assert_aim_unchanged(cannon, aim_before_inspection, "returning to Aim Lock must preserve aim")


func _screen_position_for_yaw(
		camera: Camera3D,
		cannon: CannonController,
		yaw_degrees: float
) -> Vector2:
	var elevation := 38.0
	var direction := CannonBallistics.launch_direction(yaw_degrees, elevation)
	var endpoint := cannon.get_launch_origin_for(yaw_degrees, elevation) + direction * 80.0
	_assert_true(not camera.is_position_behind(endpoint), "screen-direction sample must stay in front of camera")
	return camera.unproject_position(endpoint)


func _aim(cannon: CannonController) -> Vector3:
	return Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)


func _push_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	event.pressed = pressed
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


func _push_aim_motion(screen_delta: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.relative = screen_delta
	motion.screen_relative = screen_delta
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame


func _perform_aim_drag(screen_delta: Vector2) -> void:
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, true)
	await _push_aim_motion(screen_delta)
	await _push_mouse_button(Vector2(640, 320), MOUSE_BUTTON_LEFT, false)


func _assert_aim_unchanged(cannon: CannonController, expected: Vector3, message: String) -> void:
	_assert_true(_aim(cannon).is_equal_approx(expected), message)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Aim interaction check failed: %s" % message)
