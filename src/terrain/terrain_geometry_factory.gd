class_name TerrainGeometryFactory
extends RefCounted

const DEFAULT_BASE_Y := -12.0


static func build(layout: GeneratedStageLayout, base_y: float = DEFAULT_BASE_Y) -> TerrainGeometry:
	assert(layout != null and layout.is_valid(), "Terrain geometry requires a valid generated layout.")
	var cell_size_x := layout.local_bounds.size.x / float(layout.cell_count.x)
	var cell_size_z := layout.local_bounds.size.y / float(layout.cell_count.y)
	assert(is_equal_approx(cell_size_x, cell_size_z), "HeightMapShape3D requires square terrain cells.")

	var top_vertices := PackedVector3Array()
	var top_normals := PackedVector3Array()
	var top_uvs := PackedVector2Array()
	_append_top(layout, top_vertices, top_normals, top_uvs)

	var shell_vertices := PackedVector3Array()
	var shell_normals := PackedVector3Array()
	var shell_uvs := PackedVector2Array()
	_append_skirts(layout, base_y, shell_vertices, shell_normals, shell_uvs)
	_append_bottom(layout.local_bounds, base_y, shell_vertices, shell_normals, shell_uvs)

	var render_vertices := top_vertices.duplicate()
	render_vertices.append_array(shell_vertices)
	var render_normals := top_normals.duplicate()
	render_normals.append_array(shell_normals)
	var render_uvs := top_uvs.duplicate()
	render_uvs.append_array(shell_uvs)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = render_vertices
	arrays[Mesh.ARRAY_NORMAL] = render_normals
	arrays[Mesh.ARRAY_TEX_UV] = render_uvs
	var render_mesh := ArrayMesh.new()
	render_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var scaled_heights := PackedFloat32Array()
	scaled_heights.resize(layout.heights.size())
	# The collision node applies one uniform cell-size scale on all axes.
	for index in range(layout.heights.size()):
		scaled_heights[index] = layout.heights[index] / cell_size_x
	var top_shape := HeightMapShape3D.new()
	top_shape.map_width = layout.sample_size().x
	top_shape.map_depth = layout.sample_size().y
	top_shape.map_data = scaled_heights

	var skirt_shape := ConcavePolygonShape3D.new()
	skirt_shape.set_faces(shell_vertices, true)

	var geometry := TerrainGeometry.new()
	geometry.render_mesh = render_mesh
	geometry.top_shape = top_shape
	geometry.skirt_shape = skirt_shape
	geometry.local_bounds = layout.local_bounds
	geometry.cell_size = cell_size_x
	geometry.base_y = base_y
	geometry.top_vertex_count = top_vertices.size()
	geometry.shell_vertex_count = shell_vertices.size()
	geometry.top_triangle_count = layout.cell_count.x * layout.cell_count.y * 2
	geometry.skirt_triangle_count = (layout.cell_count.x + layout.cell_count.y) * 4
	geometry.bottom_triangle_count = 2
	return geometry


static func _append_top(
		layout: GeneratedStageLayout,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array
) -> void:
	var sample_size := layout.sample_size()
	for z_index in range(layout.cell_count.y):
		var z0_ratio := float(z_index) / float(layout.cell_count.y)
		var z1_ratio := float(z_index + 1) / float(layout.cell_count.y)
		var z0 := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, z0_ratio)
		var z1 := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, z1_ratio)
		for x_index in range(layout.cell_count.x):
			var x0_ratio := float(x_index) / float(layout.cell_count.x)
			var x1_ratio := float(x_index + 1) / float(layout.cell_count.x)
			var x0 := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, x0_ratio)
			var x1 := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, x1_ratio)
			var p00 := Vector3(x0, layout.heights[z_index * sample_size.x + x_index], z0)
			var p01 := Vector3(x0, layout.heights[(z_index + 1) * sample_size.x + x_index], z1)
			var p10 := Vector3(x1, layout.heights[z_index * sample_size.x + x_index + 1], z0)
			var p11 := Vector3(x1, layout.heights[(z_index + 1) * sample_size.x + x_index + 1], z1)
			_append_triangle(
				vertices, normals, uvs, p00, p01, p10,
				Vector2(x0_ratio, z0_ratio), Vector2(x0_ratio, z1_ratio), Vector2(x1_ratio, z0_ratio)
			)
			_append_triangle(
				vertices, normals, uvs, p10, p01, p11,
				Vector2(x1_ratio, z0_ratio), Vector2(x0_ratio, z1_ratio), Vector2(x1_ratio, z1_ratio)
			)


static func _append_skirts(
		layout: GeneratedStageLayout,
		base_y: float,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array
) -> void:
	var bounds := layout.local_bounds
	var size := layout.sample_size()
	for x_index in range(layout.cell_count.x):
		var x0 := lerpf(bounds.position.x, bounds.end.x, float(x_index) / float(layout.cell_count.x))
		var x1 := lerpf(bounds.position.x, bounds.end.x, float(x_index + 1) / float(layout.cell_count.x))
		var north_a := Vector3(x0, layout.heights[x_index], bounds.position.y)
		var north_b := Vector3(x1, layout.heights[x_index + 1], bounds.position.y)
		_append_wall_quad(north_a, north_b, base_y, false, vertices, normals, uvs)
		var south_offset := (size.y - 1) * size.x
		var south_a := Vector3(x0, layout.heights[south_offset + x_index], bounds.end.y)
		var south_b := Vector3(x1, layout.heights[south_offset + x_index + 1], bounds.end.y)
		_append_wall_quad(south_a, south_b, base_y, true, vertices, normals, uvs)
	for z_index in range(layout.cell_count.y):
		var z0 := lerpf(bounds.position.y, bounds.end.y, float(z_index) / float(layout.cell_count.y))
		var z1 := lerpf(bounds.position.y, bounds.end.y, float(z_index + 1) / float(layout.cell_count.y))
		var west_a := Vector3(bounds.position.x, layout.heights[z_index * size.x], z0)
		var west_b := Vector3(bounds.position.x, layout.heights[(z_index + 1) * size.x], z1)
		_append_wall_quad(west_a, west_b, base_y, true, vertices, normals, uvs)
		var east_a := Vector3(bounds.end.x, layout.heights[z_index * size.x + size.x - 1], z0)
		var east_b := Vector3(bounds.end.x, layout.heights[(z_index + 1) * size.x + size.x - 1], z1)
		_append_wall_quad(east_a, east_b, base_y, false, vertices, normals, uvs)


static func _append_wall_quad(
		top_a: Vector3,
		top_b: Vector3,
		base_y: float,
		reverse: bool,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array
) -> void:
	var bottom_a := Vector3(top_a.x, base_y, top_a.z)
	var bottom_b := Vector3(top_b.x, base_y, top_b.z)
	if reverse:
		_append_triangle(vertices, normals, uvs, top_a, bottom_a, top_b, Vector2.ZERO, Vector2.DOWN, Vector2.RIGHT)
		_append_triangle(vertices, normals, uvs, top_b, bottom_a, bottom_b, Vector2.RIGHT, Vector2.DOWN, Vector2.ONE)
	else:
		_append_triangle(vertices, normals, uvs, top_a, top_b, bottom_a, Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN)
		_append_triangle(vertices, normals, uvs, top_b, bottom_b, bottom_a, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN)


static func _append_bottom(
		bounds: Rect2,
		base_y: float,
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array
) -> void:
	var north_west := Vector3(bounds.position.x, base_y, bounds.position.y)
	var north_east := Vector3(bounds.end.x, base_y, bounds.position.y)
	var south_east := Vector3(bounds.end.x, base_y, bounds.end.y)
	var south_west := Vector3(bounds.position.x, base_y, bounds.end.y)
	_append_triangle(vertices, normals, uvs, north_west, north_east, south_east, Vector2.ZERO, Vector2.RIGHT, Vector2.ONE)
	_append_triangle(vertices, normals, uvs, north_west, south_east, south_west, Vector2.ZERO, Vector2.ONE, Vector2.DOWN)


static func _append_triangle(
		vertices: PackedVector3Array,
		normals: PackedVector3Array,
		uvs: PackedVector2Array,
		a: Vector3,
		b: Vector3,
		c: Vector3,
		uv_a: Vector2,
		uv_b: Vector2,
		uv_c: Vector2
) -> void:
	var normal := (b - a).cross(c - a).normalized()
	vertices.append_array(PackedVector3Array([a, b, c]))
	normals.append_array(PackedVector3Array([normal, normal, normal]))
	uvs.append_array(PackedVector2Array([uv_a, uv_b, uv_c]))
