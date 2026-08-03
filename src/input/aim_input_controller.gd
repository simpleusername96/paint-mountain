class_name AimInputController
extends Node3D

const DRAG_YAW_DEGREES_PER_PIXEL := 0.15
const DRAG_ELEVATION_DEGREES_PER_PIXEL := -0.12
const KEYBOARD_ANGLE_STEP := 0.5
const BUTTON_POWER_STEP := 2.0
const WHEEL_POWER_STEP := 1.0
const HOLD_DELAY_SECONDS := 0.30
const HOLD_REPEAT_SECONDS := 0.08

var _cannon: CannonController
var _stage_controller: StageController
var _drag_active := false
var _held_keys: Dictionary = {}


func configure(cannon: CannonController, stage_controller: StageController) -> void:
	_cannon = cannon
	_stage_controller = stage_controller


func _process(delta: float) -> void:
	if not _can_adjust_aim():
		_held_keys.clear()
		_drag_active = false
		return
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
	return _stage_controller.request_fire(StageController.ActionOrigin.HUMAN)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	var keycode := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	_handle_key(key)
	if keycode in [KEY_TAB, KEY_SPACE]:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_adjust_aim():
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			_drag_active = button.pressed
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust_power(WHEEL_POWER_STEP)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust_power(-WHEEL_POWER_STEP)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _drag_active and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var pointer_scale := _pointer_scale_to_physical_pixels()
			_apply_axis_step(
				motion.relative.x * pointer_scale.x * DRAG_YAW_DEGREES_PER_PIXEL,
				motion.relative.y * pointer_scale.y * DRAG_ELEVATION_DEGREES_PER_PIXEL
			)
		elif not (motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_drag_active = false


func _handle_key(event: InputEventKey) -> void:
	var keycode := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if keycode == KEY_TAB and event.pressed and not event.echo:
		if _stage_controller.current_state == StageController.State.AIMING:
			_stage_controller.enter_briefing(StageController.ActionOrigin.HUMAN)
		elif _stage_controller.current_state == StageController.State.BRIEFING:
			_stage_controller.begin_aiming(StageController.ActionOrigin.HUMAN)
		return
	if keycode == KEY_SPACE:
		if event.pressed and not event.echo:
			request_fire()
		return
	var axis := _axis_for_key(keycode)
	if axis.is_zero_approx():
		return
	if not event.pressed:
		_held_keys.erase(keycode)
		return
	if event.echo or _held_keys.has(keycode) or not _can_adjust_aim():
		return
	_apply_axis_step(axis.x, axis.y)
	_held_keys[keycode] = {
		"yaw": axis.x,
		"elevation": axis.y,
		"elapsed": 0.0,
		"next_repeat": HOLD_DELAY_SECONDS,
	}


func _apply_axis_step(yaw_delta: float, elevation_delta: float) -> void:
	_stage_controller.set_aim(
		_cannon.yaw_degrees + yaw_delta,
		_cannon.elevation_degrees + elevation_delta,
		_cannon.power_percent,
		StageController.ActionOrigin.HUMAN
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
			and not _stage_controller.action_origin_is_locked() \
			and _cannon.input_enabled \
			and _stage_controller.current_state == StageController.State.AIMING


func _pointer_scale_to_physical_pixels() -> Vector2:
	var logical := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	)
	return Vector2(get_viewport().size) / logical
