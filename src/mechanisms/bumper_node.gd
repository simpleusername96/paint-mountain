class_name BumperNode
extends GimmickBase


func _apply_effect(projectile: PaintProjectile) -> void:
	var world_direction := global_basis * data.impulse_direction.normalized()
	projectile.apply_central_impulse(world_direction * data.impulse_strength)


func _build_visual(parent: Node3D) -> void:
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.7
	base_mesh.bottom_radius = 1.9
	base_mesh.height = 0.65
	base_mesh.radial_segments = 16
	base_mesh.material = _material(Color(0.17, 0.2, 0.25, 1.0), 0.38)
	var base := MeshInstance3D.new()
	base.mesh = base_mesh
	parent.add_child(base)

	var pad_mesh := CylinderMesh.new()
	pad_mesh.top_radius = 1.3
	pad_mesh.bottom_radius = 1.3
	pad_mesh.height = 0.5
	pad_mesh.radial_segments = 16
	pad_mesh.material = _material(Color(0.9, 0.93, 0.96, 1.0), 0.24)
	var pad := MeshInstance3D.new()
	pad.position.y = 0.55
	pad.mesh = pad_mesh
	parent.add_child(pad)

	var direction_mesh := CylinderMesh.new()
	direction_mesh.top_radius = 0.12
	direction_mesh.bottom_radius = 0.2
	direction_mesh.height = 3.2
	direction_mesh.radial_segments = 8
	direction_mesh.material = _material(Color(0.04, 0.42, 1.0, 1.0), 0.18, 0.25)
	var direction_marker := MeshInstance3D.new()
	direction_marker.position = Vector3(0.0, 1.55, -1.1)
	direction_marker.rotation_degrees.x = 58.0
	direction_marker.mesh = direction_mesh
	parent.add_child(direction_marker)
