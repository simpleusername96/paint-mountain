class_name TerrainSurface
extends Node3D

const TOP_SHAPE_ID := &"TerrainTopShape"
const SHELL_OWNER_ID := &"terrain/shell"
const SHELL_SHAPE_ID := &"TerrainShellShape"
const NORMAL_TERRAIN_PHYSICS_MATERIAL := preload(
	"res://resources/physics/normal_terrain_physics_material.tres"
)

var _layout: GeneratedStageLayout
var _geometry: TerrainGeometry
var _playable_top_world_points := PackedVector3Array()


func configure(layout: GeneratedStageLayout) -> void:
	assert(layout != null and layout.is_valid(), "TerrainSurface requires a valid generated layout.")
	_layout = layout
	_geometry = TerrainGeometryFactory.build(layout)
	_playable_top_world_points = _build_playable_top_world_points()
	var terrain_mesh := get_node_or_null("TerrainMesh") as MeshInstance3D
	var top_body := get_node_or_null("TerrainTopBody") as StaticBody3D
	var top_collision := get_node_or_null("TerrainTopBody/CollisionShape3D") as CollisionShape3D
	var shell_body := get_node_or_null("TerrainShellBody") as StaticBody3D
	var shell_collision := get_node_or_null("TerrainShellBody/CollisionShape3D") as CollisionShape3D
	assert(terrain_mesh != null and top_body != null and top_collision != null, "TerrainSurface top nodes are missing.")
	assert(shell_body != null and shell_collision != null, "TerrainSurface shell nodes are missing.")
	terrain_mesh.mesh = _geometry.render_mesh
	top_collision.shape = _geometry.top_shape
	top_collision.scale = Vector3.ONE
	shell_collision.shape = _geometry.skirt_shape
	top_body.set_meta(PlayBoundsSpec.CONTACT_OWNER_META, TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID)
	top_collision.set_meta(PlayBoundsSpec.CONTACT_SHAPE_META, TOP_SHAPE_ID)
	shell_body.set_meta(PlayBoundsSpec.CONTACT_OWNER_META, SHELL_OWNER_ID)
	shell_collision.set_meta(PlayBoundsSpec.CONTACT_SHAPE_META, SHELL_SHAPE_ID)
	top_body.collision_layer = 1
	top_body.collision_mask = 0
	top_body.physics_material_override = NORMAL_TERRAIN_PHYSICS_MATERIAL
	shell_body.collision_layer = 1
	shell_body.collision_mask = 0
	shell_body.physics_material_override = NORMAL_TERRAIN_PHYSICS_MATERIAL


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
	return (global_transform.basis.inverse().transposed() \
			* _layout.normal_at_local(local_reference.x, local_reference.z)).normalized()


func contains_world_xz(world_xz: Vector2, margin: float = 0.0) -> bool:
	if _layout == null:
		return false
	var local_reference := to_local(Vector3(world_xz.x, global_position.y, world_xz.y))
	var local_xz := Vector2(local_reference.x, local_reference.z)
	if not _layout.local_bounds.grow(margin).has_point(local_xz):
		return false
	return not _layout.surface_sample_at_local(local_xz.x, local_xz.y, false).is_empty()


func is_top_collider(object: Object) -> bool:
	return object != null and object == get_node_or_null("TerrainTopBody")


func is_skirt_collider(object: Object) -> bool:
	return object != null and object == get_node_or_null("TerrainShellBody")


func layout_read_only() -> GeneratedStageLayout:
	return _layout


func render_world_aabb() -> AABB:
	if _geometry == null or _geometry.render_mesh == null:
		return AABB()
	return global_transform * _geometry.render_mesh.get_aabb()


## Canonical active-top vertices for exact projection checks. The packed array
## is duplicated so callers cannot mutate TerrainSurface's cached geometry.
func playable_top_world_points() -> PackedVector3Array:
	return _playable_top_world_points.duplicate()


func _build_playable_top_world_points() -> PackedVector3Array:
	if _layout == null or _layout.top_topology == null:
		return PackedVector3Array()
	var topology := _layout.top_topology
	var seen_source_indices: Dictionary = {}
	var result := PackedVector3Array()
	for cell_z in range(_layout.cell_count.y):
		for cell_x in range(_layout.cell_count.x):
			var cell := Vector2i(cell_x, cell_z)
			if not topology.is_cell_active(cell):
				continue
			for triangle_in_cell in range(TerrainTopTopology.TRIANGLES_PER_CELL):
				var indices := topology.triangle_vertex_indices(cell, triangle_in_cell)
				for source_index in [indices.x, indices.y, indices.z]:
					if seen_source_indices.has(source_index):
						continue
					seen_source_indices[source_index] = true
					result.append(to_global(topology.vertex_at(source_index)))
	return result


func classify_top_hit(
		world_point: Vector3,
		predicted_world_normal: Vector3,
		shape_id: StringName = TOP_SHAPE_ID,
		body_shape_index: int = 0
) -> TrajectoryHitIdentity:
	if _layout == null or _layout.top_topology == null:
		return null
	var local_point := to_local(world_point)
	var local_normal := (global_transform.basis.transposed() * predicted_world_normal).normalized()
	var sample := _layout.top_topology.classify_local_hit(local_point, local_normal)
	if sample.is_empty():
		return null
	return TrajectoryHitIdentity.terrain_top(
		shape_id,
		body_shape_index,
		sample.cell,
		sample.triangle,
		sample.barycentric
	)


func classify_top_physics_hit(
		world_point: Vector3,
		shape_id: StringName = TOP_SHAPE_ID,
		body_shape_index: int = 0
) -> TrajectoryHitIdentity:
	# RigidBody contact manifolds at a shared faceted edge can report a blended
	# normal that is not the authored triangle normal. The top collider metadata
	# already proves the owner/shape; classify the canonical triangle from the
	# measured contact XZ and retain only the authoritative height check.
	if _layout == null or _layout.top_topology == null:
		return null
	var local_point := to_local(world_point)
	var sample := _layout.top_topology.surface_sample_at_local(local_point.x, local_point.z, false)
	if sample.is_empty() or absf(float(sample.point.y) - local_point.y) \
			> TerrainTopTopology.HIT_HEIGHT_TOLERANCE:
		return null
	return TrajectoryHitIdentity.terrain_top(
		shape_id,
		body_shape_index,
		sample.cell,
		int(sample.triangle),
		sample.barycentric
	)


static func classify_top_cell_uv(
		shape_id: StringName,
		body_shape_index: int,
		cell: Vector2i,
		local_uv: Vector2
) -> TrajectoryHitIdentity:
	if cell.x < 0 or cell.y < 0:
		return null
	var address := TerrainTopTopology.triangle_barycentric_for_cell_uv(local_uv)
	if address.x < 0.0:
		return null
	return TrajectoryHitIdentity.terrain_top(
		shape_id,
		body_shape_index,
		cell,
		int(address.x),
		Vector3(address.y, address.z, address.w)
	)
