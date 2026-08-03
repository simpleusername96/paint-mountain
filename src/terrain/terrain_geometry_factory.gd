class_name TerrainGeometryFactory
extends RefCounted

const DEFAULT_BASE_Y := -12.0
const MINIMUM_SKIRT_HEIGHT := 8.0


static func build(layout: GeneratedStageLayout, base_y: float = DEFAULT_BASE_Y) -> TerrainGeometry:
	assert(layout != null and layout.is_valid(), "Terrain geometry requires a valid generated layout.")
	var topology := layout.top_topology
	assert(topology != null and topology.is_valid(), "Terrain geometry requires canonical top topology.")

	var top_vertices := PackedVector3Array()
	var top_normals := PackedVector3Array()
	var top_uvs := PackedVector2Array()
	var top_colors := PackedColorArray()
	var top_source_vertices := PackedInt32Array()
	var top_source_triangles := PackedInt32Array()
	_append_top(
		topology,
		top_vertices,
		top_normals,
		top_uvs,
		top_colors,
		top_source_vertices,
		top_source_triangles
	)

	var shell_vertices := PackedVector3Array()
	var shell_normals := PackedVector3Array()
	var shell_uvs := PackedVector2Array()
	var shell_colors := PackedColorArray()
	_append_skirts(topology, base_y, shell_vertices, shell_normals, shell_uvs, shell_colors)
	_append_bottom(topology, base_y, shell_vertices, shell_normals, shell_uvs, shell_colors)

	var render_vertices := top_vertices.duplicate()
	render_vertices.append_array(shell_vertices)
	var render_normals := top_normals.duplicate()
	render_normals.append_array(shell_normals)
	var render_uvs := top_uvs.duplicate()
	render_uvs.append_array(shell_uvs)
	var render_colors := top_colors.duplicate()
	render_colors.append_array(shell_colors)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = render_vertices
	arrays[Mesh.ARRAY_NORMAL] = render_normals
	arrays[Mesh.ARRAY_TEX_UV] = render_uvs
	arrays[Mesh.ARRAY_COLOR] = render_colors
	var render_mesh := ArrayMesh.new()
	render_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var top_shape := ConcavePolygonShape3D.new()
	# Godot's concave face convention treats the frozen upward render winding as
	# a back face for physics queries, so collision must explicitly accept it.
	top_shape.backface_collision = true
	top_shape.set_faces(topology.expanded_triangle_faces())
	var skirt_shape := ConcavePolygonShape3D.new()
	skirt_shape.backface_collision = true
	skirt_shape.set_faces(shell_vertices)

	var geometry := TerrainGeometry.new()
	geometry.render_mesh = render_mesh
	geometry.top_shape = top_shape
	geometry.skirt_shape = skirt_shape
	geometry.top_topology = topology
	geometry.local_bounds = topology.local_bounds
	geometry.base_y = base_y
	geometry.top_vertex_count = top_vertices.size()
	geometry.shell_vertex_count = shell_vertices.size()
	geometry.top_triangle_count = topology.triangle_count()
	geometry.skirt_triangle_count = topology.boundary_vertex_indices_read_only().size() * 2
	geometry.bottom_triangle_count = 2
	geometry.top_render_source_vertex_indices = top_source_vertices
	geometry.top_render_source_triangle_ids = top_source_triangles
	return geometry


static func _append_top(
		topology: TerrainTopTopology,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array,
		colors: PackedColorArray,
		source_vertex_indices: PackedInt32Array,
		source_triangle_ids: PackedInt32Array
) -> void:
	var canonical_vertices := topology.canonical_vertices_read_only()
	var canonical_indices := topology.canonical_triangle_indices_read_only()
	for source_triangle_id in range(topology.triangle_count()):
		var corner_offset := source_triangle_id * 3
		var index_a := canonical_indices[corner_offset]
		var index_b := canonical_indices[corner_offset + 1]
		var index_c := canonical_indices[corner_offset + 2]
		var a := canonical_vertices[index_a]
		var b := canonical_vertices[index_b]
		var c := canonical_vertices[index_c]
		_append_triangle(
			vertices,
			normals,
			uvs,
			colors,
			a,
			b,
			c,
			_uv_for(topology.local_bounds, a),
			_uv_for(topology.local_bounds, b),
			_uv_for(topology.local_bounds, c)
		)
		source_vertex_indices.append_array(PackedInt32Array([index_a, index_b, index_c]))
		source_triangle_ids.append(source_triangle_id)


static func _append_skirts(
		topology: TerrainTopTopology,
		base_y: float,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array,
		colors: PackedColorArray
) -> void:
	var boundary := topology.boundary_vertex_indices_read_only()
	for edge_index in range(boundary.size()):
		var top_a := topology.vertex_at(boundary[edge_index])
		var top_b := topology.vertex_at(boundary[(edge_index + 1) % boundary.size()])
		assert(
			minf(top_a.y, top_b.y) - base_y >= MINIMUM_SKIRT_HEIGHT,
			"Terrain boundary must retain the minimum visible skirt height."
		)
		_append_wall_quad(top_a, top_b, base_y, vertices, normals, uvs, colors)


static func _append_wall_quad(
		top_a: Vector3,
		top_b: Vector3,
		base_y: float,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array,
		colors: PackedColorArray
) -> void:
	var bottom_a := Vector3(top_a.x, base_y, top_a.z)
	var bottom_b := Vector3(top_b.x, base_y, top_b.z)
	_append_triangle(
		vertices, normals, uvs, colors,
		top_a, top_b, bottom_a, Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, false
	)
	_append_triangle(
		vertices, normals, uvs, colors,
		top_b, bottom_b, bottom_a, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN, false
	)


static func _append_bottom(
		topology: TerrainTopTopology,
		base_y: float,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array,
		colors: PackedColorArray
) -> void:
	var corners := topology.boundary_corner_indices_read_only()
	var north_west_source := topology.vertex_at(corners[0])
	var north_east_source := topology.vertex_at(corners[1])
	var south_east_source := topology.vertex_at(corners[2])
	var south_west_source := topology.vertex_at(corners[3])
	var north_west := Vector3(north_west_source.x, base_y, north_west_source.z)
	var north_east := Vector3(north_east_source.x, base_y, north_east_source.z)
	var south_east := Vector3(south_east_source.x, base_y, south_east_source.z)
	var south_west := Vector3(south_west_source.x, base_y, south_west_source.z)
	_append_triangle(
		vertices, normals, uvs, colors,
		north_west, north_east, south_east, Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, false
	)
	_append_triangle(
		vertices, normals, uvs, colors,
		north_west, south_east, south_west, Vector2.ZERO, Vector2.ONE, Vector2.DOWN, false
	)


static func _append_triangle(
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array,
		colors: PackedColorArray,
		a: Vector3,
		b: Vector3,
		c: Vector3,
		uv_a: Vector2,
		uv_b: Vector2,
		uv_c: Vector2,
		paintable: bool = true
) -> void:
	var normal := (b - a).cross(c - a).normalized()
	vertices.append_array(PackedVector3Array([a, b, c]))
	normals.append_array(PackedVector3Array([normal, normal, normal]))
	uvs.append_array(PackedVector2Array([uv_a, uv_b, uv_c]))
	var classification := Color.WHITE if paintable else Color.BLACK
	colors.append_array(PackedColorArray([classification, classification, classification]))


static func _uv_for(bounds: Rect2, vertex: Vector3) -> Vector2:
	return Vector2(
		(vertex.x - bounds.position.x) / bounds.size.x,
		(vertex.z - bounds.position.y) / bounds.size.y
	)
