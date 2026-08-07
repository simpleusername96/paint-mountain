class_name AimInputController
extends Node3D

signal aim_interaction_changed(active: bool)

const DRAG_YAW_DEGREES_PER_PIXEL := 0.15
const DRAG_ELEVATION_DEGREES_PER_PIXEL := -0.12
const KEYBOARD_ANGLE_STEP := 0.5
const BUTTON_POWER_STEP := 2.0
const WHEEL_POWER_STEP := 1.0
const HOLD_DELAY_SECONDS := 0.30
const HOLD_REPEAT_SECONDS := 0.08
const MINIMUM_SENSITIVITY_PERCENT := 50
const MAXIMUM_SENSITIVITY_PERCENT := 150

var _cannon: CannonController
var _stage_controller: StageController
var _camera_director: CameraDirector
var _drag_active := false
var _pending_drag_degrees := Vector2.ZERO
var _requested_angles := Vector2.ZERO
var _held_keys: Dictionary = {}
var _sensitivity_percent := 100
var _publishing_pointer_aim := false


func configure(
		cannon: CannonController,
		stage_controller: StageController,
		camera_director: CameraDirector
) -> void:
	_cannon = cannon
	_stage_controller = stage_controller
	_camera_director = camera_director
	_requested_angles = Vector2(cannon.yaw_degrees, cannon.elevation_degrees)
	if not cannon.aim_changed.is_connected(_on_cannon_aim_changed):
		cannon.aim_changed.connect(_on_cannon_aim_changed)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		if not game_state.settings_changed.is_connected(_on_settings_changed):
			game_state.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(game_state.settings)


func _process(delta: float) -> void:
	if not _can_adjust_aim():
		_held_keys.clear()
		_end_drag()
		_pending_drag_degrees = Vector2.ZERO
		return
	_flush_pending_drag()
	for keycode in _held_keys.keys():
		var held: Dictionary = _held_keys[keycode]
		held.elapsed = float(held.elapsed) + delta
		while float(held.elapsed) + 0.000001 >= float(held.next_repeat):
			_apply_axis_step(float(held.yaw), float(held.elevation))
			held.next_repeat = float(held.next_repeat) + HOLD_REPEAT_SECONDS
		_held_keys[keycode] = held


func adjust_power(delta_percent: float) -> bool:
	if not _can_adjust_aim():
		return false
	return _stage_controller.set_aim(
		_cannon.yaw_degrees,
		_cannon.elevation_degrees,
		_cannon.power_percent + delta_percent,
		StageController.ActionOrigin.HUMAN
	)


func adjust_power_button(direction: float) -> bool:
	return adjust_power(signf(direction) * BUTTON_POWER_STEP)


func adjust_yaw(delta_degrees: float) -> bool:
	if not _can_adjust_aim():
		return false
	_apply_axis_step(delta_degrees, 0.0)
	return true


func adjust_elevation(delta_degrees: float) -> bool:
	if not _can_adjust_aim():
		return false
	_apply_axis_step(0.0, delta_degrees)
	return true


func request_fire() -> bool:
	if not _can_adjust_aim():
		return false
	_flush_pending_drag()
	return _stage_controller.request_fire(StageController.ActionOrigin.HUMAN)


func requested_angles() -> Vector2:
	return _requested_angles


func sensitivity_percent() -> int:
	return _sensitivity_percent


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	var keycode := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	var consumed := _handle_key(key)
	if consumed and keycode in [KEY_TAB, KEY_SPACE]:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_adjust_aim():
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_begin_drag()
			else:
				_flush_pending_drag()
				_end_drag()
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust_power(WHEEL_POWER_STEP)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust_power(-WHEEL_POWER_STEP)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _drag_active and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var sensitivity := float(_sensitivity_percent) / 100.0
			_pending_drag_degrees += Vector2(
				motion.screen_relative.x * DRAG_YAW_DEGREES_PER_PIXEL * sensitivity,
				motion.screen_relative.y * DRAG_ELEVATION_DEGREES_PER_PIXEL * sensitivity
			)
		elif not (motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_flush_pending_drag()
			_end_drag()


func _handle_key(event: InputEventKey) -> bool:
	var keycode := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if keycode == KEY_TAB and event.pressed and not event.echo:
		if _stage_controller == null or _stage_controller.action_origin_is_locked():
			return false
		if _camera_director != null and _camera_director.current_mode == CameraDirector.Mode.FOLLOW:
			return _camera_director.return_to_aim_view()
		return _stage_controller.current_state == StageController.State.AIMING \
				and _camera_director != null \
				and _camera_director.toggle_interaction_mode()
	if keycode == KEY_SPACE:
		# Secondary focused buttons retain native Space activation. Fire keeps its
		# one-press shortcut even when the primary button owns focus.
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner is Button and focus_owner.name != &"FireButton":
			return false
		if event.pressed and not event.echo:
			return request_fire()
		return false
	var axis := _axis_for_key(keycode)
	if axis.is_zero_approx():
		return false
	if not event.pressed:
		_held_keys.erase(keycode)
		return false
	if event.echo or _held_keys.has(keycode) or not _can_adjust_aim():
		return false
	_apply_axis_step(axis.x, axis.y)
	_held_keys[keycode] = {
		"yaw": axis.x,
		"elevation": axis.y,
		"elapsed": 0.0,
		"next_repeat": HOLD_DELAY_SECONDS,
	}
	return false


func _apply_axis_step(yaw_delta: float, elevation_delta: float) -> void:
	_stage_controller.set_aim(
		_cannon.yaw_degrees + yaw_delta,
		_cannon.elevation_degrees + elevation_delta,
		_cannon.power_percent,
		StageController.ActionOrigin.HUMAN
	)


func _flush_pending_drag() -> void:
	if _pending_drag_degrees.is_zero_approx():
		return
	_requested_angles += _pending_drag_degrees
	_pending_drag_degrees = Vector2.ZERO
	_requested_angles.x = clampf(
		_requested_angles.x,
		AimTuple.MINIMUM_YAW_DEGREES,
		AimTuple.MAXIMUM_YAW_DEGREES
	)
	_requested_angles.y = clampf(
		_requested_angles.y,
		AimTuple.MINIMUM_ELEVATION_DEGREES,
		AimTuple.MAXIMUM_ELEVATION_DEGREES
	)
	_publishing_pointer_aim = true
	_stage_controller.set_aim(
		_requested_angles.x,
		_requested_angles.y,
		_cannon.power_percent,
		StageController.ActionOrigin.HUMAN
	)
	_publishing_pointer_aim = false


func _begin_drag() -> void:
	if _drag_active:
		return
	_drag_active = true
	aim_interaction_changed.emit(true)


func _end_drag() -> void:
	if not _drag_active:
		return
	_drag_active = false
	aim_interaction_changed.emit(false)


func _on_cannon_aim_changed(yaw: float, elevation: float, _power: float) -> void:
	if not _publishing_pointer_aim:
		_requested_angles = Vector2(yaw, elevation)


func _on_settings_changed(settings: Dictionary) -> void:
	_sensitivity_percent = clampi(
		int(settings.get("aim_sensitivity_percent", 100)),
		MINIMUM_SENSITIVITY_PERCENT,
		MAXIMUM_SENSITIVITY_PERCENT
	)


func _axis_for_key(keycode: Key) -> Vector2:
	match keycode:
		KEY_A:
			return Vector2(-KEYBOARD_ANGLE_STEP, 0.0)
		KEY_D:
			return Vector2(KEYBOARD_ANGLE_STEP, 0.0)
		KEY_W:
			return Vector2(0.0, KEYBOARD_ANGLE_STEP)
		KEY_S:
			return Vector2(0.0, -KEYBOARD_ANGLE_STEP)
		_:
			return Vector2.ZERO


func _can_adjust_aim() -> bool:
	return _cannon != null and _stage_controller != null \
			and _camera_director != null \
			and _camera_director.current_mode == CameraDirector.Mode.AIMING \
			and _camera_director.aim_is_locked() \
			and not _stage_controller.action_origin_is_locked() \
			and _cannon.input_enabled \
			and _stage_controller.current_state == StageController.State.AIMING
