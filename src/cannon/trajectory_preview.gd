class_name TrajectoryPreview
extends Node3D

const SAMPLE_STEP_SECONDS := 0.18
const MAXIMUM_PREVIEW_SECONDS := 7.2
const MAXIMUM_DOTS := 40

@export_flags_3d_physics var collision_mask: int = 1

var first_collision_position: Vector3 = Vector3.ZERO
var has_first_collision: bool = false
var _cannon: CannonController
var _dots: Array[MeshInstance3D] = []
var _impact_marker: MeshInstance3D
var _projectile_shape: SphereShape3D


func _ready() -> void:
	_build_visuals()


func configure(cannon: CannonController) -> void:
	_cannon = cannon
	_projectile_shape = SphereShape3D.new()
	_projectile_shape.radius = _cannon.projectile_data.radius
	if not _cannon.aim_changed.is_connected(_on_aim_changed):
		_cannon.aim_changed.connect(_on_aim_changed)
	call_deferred("refresh")


func visible_sample_count() -> int:
	var result := 0
	for dot in _dots:
		if dot.visible:
			result += 1
	return result


func refresh() -> void:
	if _cannon == null or not is_inside_tree():
		return
	var gravity := _gravity_vector()
	var samples := CannonBallistics.sample_unobstructed(
		_cannon.get_launch_origin(),
		_cannon.get_launch_velocity(),
		gravity,
		SAMPLE_STEP_SECONDS,
		MAXIMUM_PREVIEW_SECONDS,
		_cannon.projectile_data.linear_damp + float(ProjectSettings.get_setting("physics/3d/default_linear_damp", 0.1))
	)
	var visible_count := 0
	has_first_collision = false
	var space_state := get_world_3d().direct_space_state
	for sample_index in range(1, samples.size()):
		var previous := samples[sample_index - 1]
		var current := samples[sample_index]
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _projectile_shape
		query.transform = Transform3D(Basis.IDENTITY, previous)
		query.motion = current - previous
		query.collision_mask = collision_mask
		query.collide_with_areas = true
		var collision := space_state.cast_motion(query)
		var display_position := current
		if not collision.is_empty() and collision[0] < 1.0:
			display_position = previous + query.motion * float(collision[0])
			first_collision_position = display_position
			has_first_collision = true
		_set_dot(visible_count, display_position)
		visible_count += 1
		if has_first_collision or visible_count >= MAXIMUM_DOTS:
			break
	for dot_index in range(visible_count, _dots.size()):
		_dots[dot_index].visible = false
	_impact_marker.visible = has_first_collision
	if has_first_collision:
		_impact_marker.global_position = first_collision_position


func _on_aim_changed(_yaw: float, _elevation: float, _power: float) -> void:
	refresh()


func _set_dot(index: int, world_position: Vector3) -> void:
	if index >= _dots.size():
		return
	var dot := _dots[index]
	dot.visible = true
	dot.global_position = world_position


func _build_visuals() -> void:
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.18
	dot_mesh.height = 0.36
	dot_mesh.radial_segments = 8
	dot_mesh.rings = 4
	var dot_material := StandardMaterial3D.new()
	dot_material.albedo_color = Color(0.08, 0.46, 1.0, 0.86)
	dot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot_mesh.material = dot_material
	for index in range(MAXIMUM_DOTS):
		var dot := MeshInstance3D.new()
		dot.name = "TrajectoryDot%02d" % index
		dot.mesh = dot_mesh
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.visible = false
		add_child(dot)
		_dots.append(dot)
	var marker_mesh := TorusMesh.new()
	marker_mesh.inner_radius = 0.45
	marker_mesh.outer_radius = 0.62
	marker_mesh.rings = 12
	marker_mesh.ring_segments = 8
	marker_mesh.material = dot_material
	_impact_marker = MeshInstance3D.new()
	_impact_marker.name = "ImpactMarker"
	_impact_marker.mesh = marker_mesh
	_impact_marker.rotation.x = PI * 0.5
	_impact_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_impact_marker.visible = false
	add_child(_impact_marker)


func _gravity_vector() -> Vector3:
	var magnitude := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var direction := Vector3(ProjectSettings.get_setting("physics/3d/default_gravity_vector", Vector3.DOWN))
	return direction.normalized() * magnitude
