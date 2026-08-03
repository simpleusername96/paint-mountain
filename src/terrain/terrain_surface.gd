class_name TerrainSurface
extends Node3D

var _layout: GeneratedStageLayout
var _geometry: TerrainGeometry


func configure(layout: GeneratedStageLayout) -> void:
	assert(layout != null and layout.is_valid(), "TerrainSurface requires a valid generated layout.")
	_layout = layout
	_geometry = TerrainGeometryFactory.build(layout)
	var terrain_mesh := get_node_or_null("TerrainMesh") as MeshInstance3D
	var top_body := get_node_or_null("TerrainTopBody") as StaticBody3D
	var top_collision := get_node_or_null("TerrainTopBody/CollisionShape3D") as CollisionShape3D
	var shell_body := get_node_or_null("TerrainShellBody") as StaticBody3D
	var shell_collision := get_node_or_null("TerrainShellBody/CollisionShape3D") as CollisionShape3D
	assert(terrain_mesh != null and top_body != null and top_collision != null, "TerrainSurface top nodes are missing.")
	assert(shell_body != null and shell_collision != null, "TerrainSurface shell nodes are missing.")
	terrain_mesh.mesh = _geometry.render_mesh
	top_collision.shape = _geometry.top_shape
	top_collision.scale = Vector3.ONE * _geometry.cell_size
	shell_collision.shape = _geometry.skirt_shape
	top_body.collision_layer = 1
	top_body.collision_mask = 0
	shell_body.collision_layer = 1
	shell_body.collision_mask = 0


func world_surface_point(world_xz: Vector2) -> Vector3:
	if _layout == null:
		return Vector3(world_xz.x, global_position.y, world_xz.y)
	var local_reference := to_local(Vector3(world_xz.x, global_position.y, world_xz.y))
	return to_global(Vector3(
		local_reference.x,
		_layout.height_at_local(local_reference.x, local_reference.z),
		local_reference.z
	))


func world_surface_normal(world_xz: Vector2) -> Vector3:
	if _layout == null:
		return Vector3.UP
	var local_reference := to_local(Vector3(world_xz.x, global_position.y, world_xz.y))
	return (global_transform.basis * _layout.normal_at_local(local_reference.x, local_reference.z)).normalized()


func contains_world_xz(world_xz: Vector2, margin: float = 0.0) -> bool:
	if _layout == null:
		return false
	var local_reference := to_local(Vector3(world_xz.x, global_position.y, world_xz.y))
	return _layout.local_bounds.grow(margin).has_point(Vector2(local_reference.x, local_reference.z))


func is_top_collider(object: Object) -> bool:
	return object != null and object == get_node_or_null("TerrainTopBody")


func is_skirt_collider(object: Object) -> bool:
	return object != null and object == get_node_or_null("TerrainShellBody")


func layout_read_only() -> GeneratedStageLayout:
	return _layout
