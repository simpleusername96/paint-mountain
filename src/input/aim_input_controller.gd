class_name AimInputController
extends Node3D

const RAY_LENGTH := 500.0
const COLLISION_MASK := 1 | 4
const KEYBOARD_ANGLE_STEP := 0.5
const KEYBOARD_POWER_STEP := 2.0
const WHEEL_POWER_STEP := 1.0

var _camera: Camera3D
var _cannon: CannonController
var _stage_controller: StageController
var _committed_target := Vector3.INF
var _committed_collider: CollisionObject3D
var _target_marker: MeshInstance3D
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D


func _ready() -> void:
	_build_marker()


func configure(camera: Camera3D, cannon: CannonController, stage_controller: StageController) -> void:
	_camera = camera
	_cannon = cannon
	_stage_controller = stage_controller
	_target_marker.visible = false
	_cannon.aim_changed.connect(_on_aim_changed)


func adjust_power(delta_percent: float) -> void:
	if not _can_accept_input():
		return
	_cannon.set_aim(_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent + delta_percent)
	_resolve_committed_target()


func commit_screen_position(screen_position: Vector2) -> bool:
	if not _can_accept_input():
		return false
	var hit := _raycast(screen_position)
	if hit.is_empty():
		_set_invalid_target()
		return false
	var collider := hit.get("collider") as CollisionObject3D
	var hit_position: Vector3 = hit.position
	var mechanism := collider.get_parent() as GimmickBase if collider != null else null
	var target := mechanism.global_position if mechanism != null else hit_position + Vector3(hit.normal) * _cannon.projectile_data.radius
	_committed_target = target
	_committed_collider = mechanism.mechanism_body() if mechanism != null else null
	_target_marker.global_position = hit_position
	_target_marker.visible = true
	return _resolve_committed_target()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_accept_input():
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			commit_screen_position(motion.position)
	elif event is InputEventMouseButton and event.pressed:
		var mouse_button := event as InputEventMouseButton
		match mouse_button.button_index:
			MOUSE_BUTTON_LEFT:
				commit_screen_position(mouse_button.position)
			MOUSE_BUTTON_WHEEL_UP:
				adjust_power(WHEEL_POWER_STEP)
			MOUSE_BUTTON_WHEEL_DOWN:
				adjust_power(-WHEEL_POWER_STEP)
	elif event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		match key.physical_keycode:
			KEY_A:
				_apply_angle_fallback(-KEYBOARD_ANGLE_STEP, 0.0)
			KEY_D:
				_apply_angle_fallback(KEYBOARD_ANGLE_STEP, 0.0)
			KEY_W:
				_apply_angle_fallback(0.0, KEYBOARD_ANGLE_STEP)
			KEY_S:
				_apply_angle_fallback(0.0, -KEYBOARD_ANGLE_STEP)
			KEY_MINUS:
				adjust_power(-KEYBOARD_POWER_STEP)
			KEY_EQUAL:
				adjust_power(KEYBOARD_POWER_STEP)
			KEY_SPACE:
				if not key.echo:
					_stage_controller.request_fire()


func _resolve_committed_target() -> bool:
	if _committed_target == Vector3.INF:
		return _cannon.is_aim_valid()
	if _committed_collider != null and not is_instance_valid(_committed_collider):
		_set_invalid_target()
		return false
	var solution := ImpactTargetSolver.solve(
		get_world_3d().direct_space_state,
		_cannon.get_launch_origin(),
		_committed_target,
		_cannon.projectile_data,
		_cannon.power_percent,
		_committed_collider,
		_cannon
	)
	if not bool(solution.valid):
		_set_invalid_target(false)
		return false
	_cannon.set_solved_aim(float(solution.yaw), float(solution.elevation), float(solution.power))
	_target_marker.material_override = _valid_material
	return true


func _apply_angle_fallback(yaw_delta: float, elevation_delta: float) -> void:
	_committed_target = Vector3.INF
	_committed_collider = null
	_target_marker.visible = false
	_cannon.set_aim(
		_cannon.yaw_degrees + yaw_delta,
		_cannon.elevation_degrees + elevation_delta,
		_cannon.power_percent
	)


func _on_aim_changed(_yaw: float, _elevation: float, _power: float) -> void:
	if _target_marker != null:
		_target_marker.material_override = _valid_material if _cannon.is_aim_valid() else _invalid_material


func _raycast(screen_position: Vector2) -> Dictionary:
	if _camera == null:
		return {}
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var end := origin + direction * RAY_LENGTH
	# Selection gives a visible mechanism priority over the terrain shelf beneath it.
	var mechanism_query := PhysicsRayQueryParameters3D.create(origin, end, 8)
	mechanism_query.collide_with_areas = false
	mechanism_query.collide_with_bodies = true
	var mechanism_hit := get_world_3d().direct_space_state.intersect_ray(mechanism_query)
	if not mechanism_hit.is_empty():
		return mechanism_hit
	var terrain_query := PhysicsRayQueryParameters3D.create(origin, end, 1)
	terrain_query.collide_with_areas = false
	terrain_query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(terrain_query)


func _set_invalid_target(hide_marker: bool = true) -> void:
	_cannon.set_aim_valid(false)
	_target_marker.material_override = _invalid_material
	if hide_marker:
		_target_marker.visible = false


func _can_accept_input() -> bool:
	return _camera != null and _cannon != null and _stage_controller != null \
			and _cannon.input_enabled and _stage_controller.current_state == StageController.State.AIMING


func _build_marker() -> void:
	_valid_material = _marker_material(Color(0.03, 0.47, 1.0, 0.9))
	_invalid_material = _marker_material(Color(0.84, 0.27, 0.27, 0.9))
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.82
	mesh.outer_radius = 1.2
	mesh.rings = 20
	mesh.ring_segments = 10
	_target_marker = MeshInstance3D.new()
	_target_marker.name = "AimTargetMarker"
	_target_marker.mesh = mesh
	_target_marker.rotation.x = PI * 0.5
	_target_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_target_marker.material_override = _valid_material
	_target_marker.visible = false
	add_child(_target_marker)


func _marker_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	return material
