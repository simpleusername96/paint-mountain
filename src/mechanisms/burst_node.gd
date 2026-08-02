class_name BurstNode
extends GimmickBase


func _apply_effect(_projectile: PaintProjectile) -> void:
	_paint_system.queue_stamp(
		&"burst",
		global_position - Vector3.UP * 0.8,
		data.burst_radius,
		data.burst_paint_amount,
		true
	)
	_paint_system.flush_pending()


func _build_visual(parent: Node3D) -> void:
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 1.55
	pedestal_mesh.bottom_radius = 1.8
	pedestal_mesh.height = 0.7
	pedestal_mesh.radial_segments = 16
	pedestal_mesh.material = _material(Color(0.16, 0.19, 0.24, 1.0), 0.32)
	var pedestal := MeshInstance3D.new()
	pedestal.mesh = pedestal_mesh
	parent.add_child(pedestal)

	var core_mesh := SphereMesh.new()
	core_mesh.radius = 1.05
	core_mesh.height = 2.1
	core_mesh.radial_segments = 16
	core_mesh.rings = 8
	core_mesh.material = _material(Color(0.08, 0.55, 1.0, 1.0), 0.2, 0.24)
	var core := MeshInstance3D.new()
	core.position.y = 0.85
	core.mesh = core_mesh
	parent.add_child(core)

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.25
	ring_mesh.outer_radius = 1.55
	ring_mesh.rings = 18
	ring_mesh.ring_segments = 8
	ring_mesh.material = _material(Color(0.9, 0.94, 0.98, 1.0), 0.45)
	var ring := MeshInstance3D.new()
	ring.position.y = 0.6
	ring.mesh = ring_mesh
	parent.add_child(ring)
