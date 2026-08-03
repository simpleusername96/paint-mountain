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

const CAMERA_CLEARANCE := 1.5
const CORRECTION_SMOOTH_TIME := 0.20
const SPLIT_FRAME_MARGIN := 1.15
const FOLLOW_RELEASE_RATIO := 0.85
const OCCLUSION_END_TOLERANCE := 0.25
const FOLLOW_DIRECTION := Vector3(10.0, 7.0, 14.0)

var current_mode: Mode = Mode.AIMING
var _camera: Camera3D
var _stage_data: StageData
var _projectile_manager: ProjectileManager
var _terrain_surface: TerrainSurface
var _desired_position := Vector3.ZERO
var _desired_focus := Vector3.ZERO
var _camera_velocity := Vector3.ZERO
var _briefing_yaw_offset: float = 0.0
var _briefing_zoom_offset: float = 0.0
var _follow_wide_latched: bool = false
var _shake_remaining: float = 0.0
var _shake_strength: float = 0.0
var _shake_phase: float = 0.0


func configure(
		camera: Camera3D,
		stage_data: StageData,
		projectile_manager: ProjectileManager,
		terrain_surface: TerrainSurface
) -> void:
	_camera = camera
	_stage_data = stage_data
	_projectile_manager = projectile_manager
	_terrain_surface = terrain_surface
	set_mode(Mode.BRIEFING, true)


func _physics_process(delta: float) -> void:
	if _camera == null or _stage_data == null:
		return
	if current_mode == Mode.FOLLOW:
		_update_follow_target()
	var safe_focus := _safe_focus(_desired_focus)
	var safe_target := safe_position_for(_desired_position, safe_focus, _focus_is_terrain(_desired_focus))
	var corrected := _smooth_damp(_camera.global_position, safe_target, delta)
	corrected = safe_position_for(corrected, safe_focus, _focus_is_terrain(_desired_focus))
	_camera.global_position = corrected
	if not corrected.is_equal_approx(safe_focus):
		_look_at_focus(safe_focus)


func _process(delta: float) -> void:
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
		set_briefing_offsets(_briefing_yaw_offset + event.relative.x * 0.16, _briefing_zoom_offset)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_briefing_offsets(_briefing_yaw_offset, _briefing_zoom_offset - 5.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_briefing_offsets(_briefing_yaw_offset, _briefing_zoom_offset + 5.0)


func set_mode(mode: Mode, immediate: bool = false) -> void:
	if _camera == null or _stage_data == null:
		return
	current_mode = mode
	if mode == Mode.FOLLOW:
		_follow_wide_latched = false
		_update_follow_target()
	else:
		var bookmark := _bookmark_for(mode)
		_move_to(bookmark[0], bookmark[1], immediate)
	mode_changed.emit(current_mode)


func mode_name() -> String:
	return Mode.keys()[current_mode]


func focus_briefing_target(world_position: Vector3) -> bool:
	if current_mode != Mode.BRIEFING or _camera == null or _stage_data == null:
		return false
	var view_direction := (_stage_data.briefing_camera_position - _stage_data.briefing_camera_target).normalized()
	_move_to(world_position + view_direction * 42.0 + Vector3.UP * 6.0, world_position, false)
	return true


func set_briefing_offsets(yaw_degrees: float, zoom_distance: float) -> void:
	_briefing_yaw_offset = clampf(yaw_degrees, -22.0, 22.0)
	_briefing_zoom_offset = clampf(zoom_distance, -22.0, 28.0)
	_apply_briefing_orbit()


func camera_focus_position() -> Vector3:
	return _safe_focus(_desired_focus)


func follow_wide_is_latched() -> bool:
	return _follow_wide_latched


func safe_position_for(desired: Vector3, focus: Vector3, terrain_focus: bool = false) -> Vector3:
	if _terrain_surface == null:
		return desired
	var candidate := desired
	if _terrain_surface.contains_world_xz(Vector2(candidate.x, candidate.z)):
		var surface := _terrain_surface.world_surface_point(Vector2(candidate.x, candidate.z))
		candidate.y = maxf(candidate.y, surface.y + CAMERA_CLEARANCE)
	for _attempt in range(8):
		var hit := _terrain_ray(candidate, focus)
		if hit.is_empty():
			break
		var hit_position: Vector3 = hit.position
		if terrain_focus and hit_position.distance_to(focus) <= OCCLUSION_END_TOLERANCE:
			break
		candidate.y += maxf(3.0, hit_position.distance_to(focus) * 0.28)
		if _terrain_surface.contains_world_xz(Vector2(candidate.x, candidate.z)):
			var raised_surface := _terrain_surface.world_surface_point(Vector2(candidate.x, candidate.z))
			candidate.y = maxf(candidate.y, raised_surface.y + CAMERA_CLEARANCE)
	if not view_ray_is_clear(candidate, focus, terrain_focus):
		# A direct overhead fallback is deterministic and cannot hide the focus behind another ridge.
		var vertical_distance := clampf(desired.distance_to(focus), 24.0, _stage_data.follow_camera_max_distance)
		candidate = focus + Vector3.UP * vertical_distance
		if _terrain_surface.contains_world_xz(Vector2(candidate.x, candidate.z)):
			var focus_surface := _terrain_surface.world_surface_point(Vector2(candidate.x, candidate.z))
			candidate.y = maxf(candidate.y, focus_surface.y + CAMERA_CLEARANCE)
	return candidate


func view_ray_is_clear(position: Vector3, focus: Vector3, terrain_focus: bool = false) -> bool:
	var hit := _terrain_ray(position, focus)
	return hit.is_empty() or (terrain_focus and Vector3(hit.position).distance_to(focus) <= OCCLUSION_END_TOLERANCE)


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
	_desired_position = position
	_desired_focus = target
	if not immediate:
		return
	var safe_focus := _safe_focus(target)
	_camera.global_position = safe_position_for(position, safe_focus, _focus_is_terrain(target))
	_camera_velocity = Vector3.ZERO
	if not _camera.global_position.is_equal_approx(safe_focus):
		_look_at_focus(safe_focus)


func _apply_briefing_orbit() -> void:
	var base_offset := _stage_data.briefing_camera_position - _stage_data.briefing_camera_target
	var rotated := base_offset.rotated(Vector3.UP, deg_to_rad(_briefing_yaw_offset))
	var direction := rotated.normalized()
	var distance := clampf(rotated.length() + _briefing_zoom_offset, 82.0, 152.0)
	_move_to(_stage_data.briefing_camera_target + direction * distance, _stage_data.briefing_camera_target, false)


func _update_follow_target() -> void:
	if _projectile_manager == null:
		return
	var active := _projectile_manager.active_projectiles()
	if active.is_empty():
		return
	var average := Vector3.ZERO
	var fastest: PaintProjectile
	var fastest_speed := -1.0
	var total_speed := 0.0
	for projectile in active:
		average += projectile.global_position
		var speed := projectile.linear_velocity.length()
		total_speed += speed
		if speed > fastest_speed:
			fastest = projectile
			fastest_speed = speed
	average /= float(active.size())
	var fastest_weight := minf(0.35, fastest_speed / maxf(total_speed, 0.001))
	var focus := average.lerp(fastest.global_position, fastest_weight)
	var bounding_radius := 0.0
	for projectile in active:
		bounding_radius = maxf(bounding_radius, projectile.global_position.distance_to(focus))
	var framed_radius := bounding_radius * SPLIT_FRAME_MARGIN
	var required_distance := maxf(FOLLOW_DIRECTION.length(), framed_radius / tan(deg_to_rad(_camera.fov * 0.5)))
	if required_distance > _stage_data.follow_camera_max_distance:
		_follow_wide_latched = true
	elif _follow_wide_latched and bounding_radius * 2.0 < _stage_data.follow_camera_max_distance * FOLLOW_RELEASE_RATIO:
		_follow_wide_latched = false
	if _follow_wide_latched:
		_desired_position = _stage_data.wide_camera_position
		_desired_focus = focus
	else:
		_desired_position = focus + FOLLOW_DIRECTION.normalized() * minf(
			required_distance,
			_stage_data.follow_camera_max_distance
		)
		_desired_focus = focus


func _safe_focus(focus: Vector3) -> Vector3:
	if _terrain_surface == null or not _terrain_surface.contains_world_xz(Vector2(focus.x, focus.z)):
		return focus
	var surface := _terrain_surface.world_surface_point(Vector2(focus.x, focus.z))
	if focus.y <= surface.y + OCCLUSION_END_TOLERANCE:
		return surface + Vector3.UP * OCCLUSION_END_TOLERANCE
	return focus


func _focus_is_terrain(focus: Vector3) -> bool:
	if _terrain_surface == null or not _terrain_surface.contains_world_xz(Vector2(focus.x, focus.z)):
		return false
	var surface := _terrain_surface.world_surface_point(Vector2(focus.x, focus.z))
	return focus.y <= surface.y + OCCLUSION_END_TOLERANCE


func _terrain_ray(from: Vector3, to: Vector3) -> Dictionary:
	if _camera == null or _terrain_surface == null or from.distance_squared_to(to) < 0.0001:
		return {}
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return _camera.get_world_3d().direct_space_state.intersect_ray(query)


func _smooth_damp(current: Vector3, target: Vector3, delta: float) -> Vector3:
	var omega := 2.0 / CORRECTION_SMOOTH_TIME
	var x := omega * maxf(delta, 0.00001)
	var decay := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - target
	var temporary := (_camera_velocity + omega * change) * delta
	_camera_velocity = (_camera_velocity - omega * temporary) * decay
	return target + (change + temporary) * decay


func _look_at_focus(focus: Vector3) -> void:
	var view_direction := (focus - _camera.global_position).normalized()
	var up := Vector3.FORWARD if absf(view_direction.dot(Vector3.UP)) > 0.98 else Vector3.UP
	_camera.look_at(focus, up)


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
