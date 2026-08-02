class_name CameraDirector
extends Node

signal mode_changed(mode: int)

enum Mode {
	BRIEFING,
	AIMING,
	FOLLOW,
	WIDE,
	CANNON,
	RESULT,
}

const TRANSITION_SECONDS := 0.5

var current_mode: Mode = Mode.AIMING
var _camera: Camera3D
var _stage_data: StageData
var _projectile_manager: ProjectileManager
var _transition: Tween
var _briefing_yaw_offset: float = 0.0
var _briefing_zoom_offset: float = 0.0
var _shake_remaining: float = 0.0
var _shake_strength: float = 0.0
var _shake_phase: float = 0.0


func configure(camera: Camera3D, stage_data: StageData, projectile_manager: ProjectileManager) -> void:
	_camera = camera
	_stage_data = stage_data
	_projectile_manager = projectile_manager
	set_mode(Mode.BRIEFING, true)


func _process(delta: float) -> void:
	if current_mode == Mode.FOLLOW and _projectile_manager != null:
		var active := _projectile_manager.active_projectiles()
		if not active.is_empty():
			var focus := Vector3.ZERO
			for projectile in active:
				focus += projectile.global_position
			focus /= float(active.size())
			var desired := focus + Vector3(10.0, 7.0, 14.0)
			_camera.global_position = _camera.global_position.lerp(desired, clampf(delta * 3.6, 0.0, 1.0))
			_camera.look_at(focus, Vector3.UP)
	_update_shake(delta)


func add_impact_shake(strength: float) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and not bool(game_state.settings.get("camera_shake", true)):
		return
	_shake_strength = maxf(_shake_strength, clampf(strength, 0.0, 0.5))
	_shake_remaining = maxf(_shake_remaining, 0.2)


func _unhandled_input(event: InputEvent) -> void:
	if current_mode != Mode.BRIEFING or _camera == null:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_briefing_yaw_offset = clampf(_briefing_yaw_offset + event.relative.x * 0.16, -22.0, 22.0)
		_apply_briefing_orbit()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_briefing_zoom_offset = clampf(_briefing_zoom_offset - 5.0, -22.0, 28.0)
			_apply_briefing_orbit()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_briefing_zoom_offset = clampf(_briefing_zoom_offset + 5.0, -22.0, 28.0)
			_apply_briefing_orbit()


func set_mode(mode: Mode, immediate: bool = false) -> void:
	if _camera == null or _stage_data == null:
		return
	current_mode = mode
	if mode == Mode.FOLLOW:
		mode_changed.emit(current_mode)
		return
	var position_and_target := _bookmark_for(mode)
	_move_to(position_and_target[0], position_and_target[1], immediate)
	mode_changed.emit(current_mode)


func mode_name() -> String:
	return Mode.keys()[current_mode]


func focus_briefing_target(world_position: Vector3) -> bool:
	if current_mode != Mode.BRIEFING or _camera == null or _stage_data == null:
		return false
	var view_direction := (_stage_data.briefing_camera_position - _stage_data.briefing_camera_target).normalized()
	var desired_position := world_position + view_direction * 42.0 + Vector3.UP * 6.0
	_move_to(desired_position, world_position, false)
	return true


func _bookmark_for(mode: Mode) -> Array[Vector3]:
	match mode:
		Mode.BRIEFING:
			return [_stage_data.briefing_camera_position, _stage_data.briefing_camera_target]
		Mode.WIDE:
			return [_stage_data.wide_camera_position, _stage_data.wide_camera_target]
		Mode.RESULT:
			return [_stage_data.result_camera_position, _stage_data.result_camera_target]
		Mode.CANNON:
			return [_stage_data.aiming_camera_position + Vector3(7.0, 2.0, 2.0), _stage_data.aiming_camera_target]
		_:
			return [_stage_data.aiming_camera_position, _stage_data.aiming_camera_target]


func _move_to(position: Vector3, target: Vector3, immediate: bool) -> void:
	if _transition != null and _transition.is_valid():
		_transition.kill()
	var target_transform := Transform3D(Basis.IDENTITY, position).looking_at(target, Vector3.UP)
	if immediate:
		_camera.global_transform = target_transform
		return
	_transition = create_tween()
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_transition.tween_property(_camera, "global_transform", target_transform, TRANSITION_SECONDS)


func _apply_briefing_orbit() -> void:
	var base_offset := _stage_data.briefing_camera_position - _stage_data.briefing_camera_target
	var rotated := base_offset.rotated(Vector3.UP, deg_to_rad(_briefing_yaw_offset))
	var direction := rotated.normalized()
	var distance := clampf(rotated.length() + _briefing_zoom_offset, 82.0, 152.0)
	_move_to(_stage_data.briefing_camera_target + direction * distance, _stage_data.briefing_camera_target, true)


func _update_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_remaining <= 0.0:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0
		return
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	_shake_phase += delta * 48.0
	var fade := clampf(_shake_remaining / 0.2, 0.0, 1.0)
	_camera.h_offset = sin(_shake_phase * 1.7) * _shake_strength * fade
	_camera.v_offset = cos(_shake_phase * 2.3) * _shake_strength * fade
