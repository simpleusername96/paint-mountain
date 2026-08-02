class_name TerrainMeshFactory
extends RefCounted

const WIDTH := 180.0
const DEPTH := 120.0
const X_SEGMENTS := 56
const Z_SEGMENTS := 38


static func build_from_layout(layout: GeneratedStageLayout) -> ArrayMesh:
	assert(layout != null and layout.is_valid(), "Terrain mesh requires a valid generated layout.")
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var size := layout.sample_size()
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
			var p00 := Vector3(x0, layout.heights[z_index * size.x + x_index], z0)
			var p01 := Vector3(x0, layout.heights[(z_index + 1) * size.x + x_index], z1)
			var p10 := Vector3(x1, layout.heights[z_index * size.x + x_index + 1], z0)
			var p11 := Vector3(x1, layout.heights[(z_index + 1) * size.x + x_index + 1], z1)
			_append_triangle(
				vertices, normals, uvs,
				p00, p01, p10,
				Vector2(x0_ratio, z0_ratio), Vector2(x0_ratio, z1_ratio), Vector2(x1_ratio, z0_ratio)
			)
			_append_triangle(
				vertices, normals, uvs,
				p10, p01, p11,
				Vector2(x1_ratio, z0_ratio), Vector2(x0_ratio, z1_ratio), Vector2(x1_ratio, z1_ratio)
			)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func build(stage_index: int = 0) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for z_index in range(Z_SEGMENTS):
		var z0_ratio := float(z_index) / float(Z_SEGMENTS)
		var z1_ratio := float(z_index + 1) / float(Z_SEGMENTS)
		var z0 := lerpf(-DEPTH * 0.5, DEPTH * 0.5, z0_ratio)
		var z1 := lerpf(-DEPTH * 0.5, DEPTH * 0.5, z1_ratio)
		for x_index in range(X_SEGMENTS):
			var x0_ratio := float(x_index) / float(X_SEGMENTS)
			var x1_ratio := float(x_index + 1) / float(X_SEGMENTS)
			var x0 := lerpf(-WIDTH * 0.5, WIDTH * 0.5, x0_ratio)
			var x1 := lerpf(-WIDTH * 0.5, WIDTH * 0.5, x1_ratio)
			var p00 := Vector3(x0, height_at(stage_index, x0, z0), z0)
			var p01 := Vector3(x0, height_at(stage_index, x0, z1), z1)
			var p10 := Vector3(x1, height_at(stage_index, x1, z0), z0)
			var p11 := Vector3(x1, height_at(stage_index, x1, z1), z1)
			_append_triangle(
				vertices, normals, uvs,
				p00, p01, p10,
				Vector2(x0_ratio, z0_ratio), Vector2(x0_ratio, z1_ratio), Vector2(x1_ratio, z0_ratio)
			)
			_append_triangle(
				vertices, normals, uvs,
				p10, p01, p11,
				Vector2(x1_ratio, z0_ratio), Vector2(x0_ratio, z1_ratio), Vector2(x1_ratio, z1_ratio)
			)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func height_at(stage_index: int, x: float, z: float) -> float:
	match stage_index:
		1:
			return _burst_basin_height(x, z)
		2:
			return _split_ridge_height(x, z)
		_:
			return _first_descent_height(x, z)


static func _first_descent_height(x: float, z: float) -> float:
	var broad_peak := 62.0 * exp(-pow((x + 8.0) / 57.0, 2.0) - pow((z + 14.0) / 52.0, 2.0))
	var left_ridge := 24.0 * exp(-pow((x + 58.0) / 25.0, 2.0) - pow((z - 2.0) / 45.0, 2.0))
	var right_ridge := 28.0 * exp(-pow((x - 53.0) / 30.0, 2.0) - pow((z + 1.0) / 44.0, 2.0))
	var valley := 13.0 * exp(-pow((x - 12.0) / 17.0, 2.0) - pow((z + 3.0) / 49.0, 2.0))
	return _finish_height(broad_peak + left_ridge + right_ridge - valley, x, z)


static func _burst_basin_height(x: float, z: float) -> float:
	var summit := 74.0 * exp(-pow((x - 16.0) / 45.0, 2.0) - pow((z + 18.0) / 42.0, 2.0))
	var left_wall := 45.0 * exp(-pow((x + 55.0) / 28.0, 2.0) - pow((z + 1.0) / 49.0, 2.0))
	var basin_rim := 35.0 * exp(-pow((x - 55.0) / 30.0, 2.0) - pow((z - 8.0) / 46.0, 2.0))
	var basin := 24.0 * exp(-pow((x - 10.0) / 34.0, 2.0) - pow((z - 18.0) / 22.0, 2.0))
	return _finish_height(summit + left_wall + basin_rim - basin, x, z)


static func _split_ridge_height(x: float, z: float) -> float:
	var center_peak := 69.0 * exp(-pow(x / 47.0, 2.0) - pow((z + 18.0) / 45.0, 2.0))
	var left_peak := 43.0 * exp(-pow((x + 60.0) / 29.0, 2.0) - pow(z / 48.0, 2.0))
	var right_peak := 47.0 * exp(-pow((x - 58.0) / 28.0, 2.0) - pow((z + 2.0) / 47.0, 2.0))
	var channel_left := 19.0 * exp(-pow((x + 24.0) / 10.0, 2.0) - pow((z - 2.0) / 55.0, 2.0))
	var channel_right := 17.0 * exp(-pow((x - 26.0) / 11.0, 2.0) - pow((z + 3.0) / 55.0, 2.0))
	return _finish_height(center_peak + left_peak + right_peak - channel_left - channel_right, x, z)


static func _finish_height(raw_height: float, x: float, z: float) -> float:
	var facets := 1.35 * sin(x * 0.15) + 0.95 * cos((x + z) * 0.12)
	var x_falloff := clampf(1.0 - pow(absf(x) / (WIDTH * 0.54), 3.0), 0.0, 1.0)
	var z_falloff := clampf(1.0 - pow(absf(z) / (DEPTH * 0.51), 2.0), 0.0, 1.0)
	return maxf(0.0, (raw_height + facets) * x_falloff * z_falloff)


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
