class_name SplitterNode
extends GimmickBase

const MAXIMUM_SPLIT_GENERATION := 1

var _route_target_bands: Array[PackedVector3Array] = []


func configure_route_target_bands(target_bands: Array[PackedVector3Array]) -> void:
	_route_target_bands = target_bands.duplicate(true)


func _effect_can_activate(projectile: PaintProjectile) -> bool:
	return projectile.split_generation < MAXIMUM_SPLIT_GENERATION


func _apply_effect(projectile: PaintProjectile) -> void:
	var incoming_velocity := projectile.linear_velocity
	var speed := maxf(incoming_velocity.length() * data.child_speed_multiplier, 14.0)
	# The splitter redirects children back down the visible face of the mountain.
	# A small inherited lateral component keeps different valid approaches distinct.
	var inherited_lateral := global_basis.x * incoming_velocity.dot(global_basis.x) * 0.08
	var base_direction := (global_basis.z + Vector3.DOWN * 0.18 + inherited_lateral).normalized()
	var available_slots := ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES - _projectile_manager.active_count()
	var spawn_count := mini(data.child_count, maxi(0, available_slots))
	var child_payload := projectile.remaining_payload * data.child_payload_ratio
	var origin := projectile.global_position + Vector3.UP * 0.5
	var target_band := 1
	if incoming_velocity.y < data.route_band_velocity_y_thresholds.x:
		target_band = 2
	elif incoming_velocity.y < data.route_band_velocity_y_thresholds.y:
		target_band = 0
	for child_index in range(spawn_count):
		var ratio := 0.5 if spawn_count == 1 else float(child_index) / float(spawn_count - 1)
		var angle := deg_to_rad(lerpf(-data.fan_angle_degrees * 0.5, data.fan_angle_degrees * 0.5, ratio))
		var direction := base_direction.rotated(Vector3.UP, angle)
		if target_band < _route_target_bands.size() and child_index < _route_target_bands[target_band].size():
			# The generated layout supplies destinations only; the splitter retains
			# ownership of child count, payload, speed, and one-generation limits.
			direction = (_route_target_bands[target_band][child_index] - origin + Vector3.UP * data.child_target_lift).normalized()
		_projectile_manager.spawn_projectile(
			projectile.projectile_data,
			origin + direction * 0.8,
			direction * maxf(speed, data.child_minimum_route_speed),
			child_payload,
			projectile.split_generation + 1
		)
	projectile.deactivate(&"split")


func _build_visual(parent: Node3D) -> void:
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 1.75
	body_mesh.bottom_radius = 1.75
	body_mesh.height = 0.65
	body_mesh.radial_segments = 3
	body_mesh.material = _material(Color(0.82, 0.86, 0.92, 1.0), 0.32)
	var body := MeshInstance3D.new()
	body.position.y = 0.35
	body.rotation.y = PI * 0.5
	body.mesh = body_mesh
	parent.add_child(body)

	for angle_degrees in [-28.0, 0.0, 28.0]:
		var outlet_mesh := CylinderMesh.new()
		outlet_mesh.top_radius = 0.18
		outlet_mesh.bottom_radius = 0.28
		outlet_mesh.height = 2.5
		outlet_mesh.radial_segments = 10
		outlet_mesh.material = _material(Color(0.05, 0.42, 1.0, 1.0), 0.18, 0.28)
		var outlet := MeshInstance3D.new()
		outlet.position = Vector3(sin(deg_to_rad(angle_degrees)) * 0.8, 0.75, -0.8)
		outlet.rotation_degrees = Vector3(90.0, 0.0, angle_degrees)
		outlet.mesh = outlet_mesh
		parent.add_child(outlet)
