class_name ApronGeometryFactory
extends RefCounted

const LOOP_VERTEX_COUNT := 8


static func build(
		spec: ContainmentSpec,
		terrain_world_bounds: Rect2,
		terrain_world_join_y: float
) -> ApronGeometry:
	assert(spec != null and spec.is_valid(), "Apron geometry requires a valid containment specification.")
	assert(
		spec.supports_terrain_join(terrain_world_bounds, terrain_world_join_y),
		"Apron geometry requires a terrain boundary that matches the visible top join."
	)

	var outer_top := _rectangle_loop(spec.apron_xz_bounds, spec.apron_minimum_y)
	var inner_top := _rectangle_loop(terrain_world_bounds, terrain_world_join_y)
	# A half-depth inset closes the volume without making its rear side coplanar
	# with either the backstop front or the terrain's rear join edge.
	var bottom_inset := spec.rear_transition_depth * 0.5
	var outer_bottom_bounds := spec.apron_xz_bounds.grow(-bottom_inset)
	assert(outer_bottom_bounds.encloses(terrain_world_bounds), "The inset apron bottom must still enclose the terrain join.")
	var outer_bottom := _rectangle_loop(outer_bottom_bounds, spec.apron_bottom_y())

	var faces := PackedVector3Array()
	var normals := PackedVector3Array()
	# The mountain intersects one uninterrupted platform. Leaving a terrain-sized
	# hole here exposes the mountain's structural closure shell to the player and
	# makes a distant 3D mass read as a dark open slab.
	_append_filled_rectangle(
		spec.apron_xz_bounds,
		spec.apron_minimum_y,
		Vector3.UP,
		faces,
		normals
	)
	var top_vertex_count := faces.size()
	_append_wall(outer_top, outer_bottom, true, faces, normals)
	_append_filled_rectangle(
		outer_bottom_bounds,
		spec.apron_bottom_y(),
		Vector3.DOWN,
		faces,
		normals
	)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)

	var geometry := ApronGeometry.new()
	geometry.render_mesh = mesh
	geometry.collision_shape = shape
	geometry.collision_faces = faces
	geometry.top_vertex_count = top_vertex_count
	geometry.top_triangle_count = top_vertex_count / 3
	geometry.total_triangle_count = faces.size() / 3
	geometry.top_xz_bounds = _xz_bounds(outer_top)
	geometry.minimum_top_y = _minimum_y(faces, top_vertex_count)
	geometry.terrain_join_gap = _maximum_loop_gap(
		inner_top,
		_rectangle_loop(terrain_world_bounds, terrain_world_join_y)
	)
	assert(geometry.is_valid(), "Generated apron geometry must be complete.")
	return geometry


static func _append_filled_rectangle(
		bounds: Rect2,
		height: float,
		direction: Vector3,
		faces: PackedVector3Array,
		normals: PackedVector3Array
) -> void:
	var p00 := Vector3(bounds.position.x, height, bounds.position.y)
	var p01 := Vector3(bounds.position.x, height, bounds.end.y)
	var p10 := Vector3(bounds.end.x, height, bounds.position.y)
	var p11 := Vector3(bounds.end.x, height, bounds.end.y)
	_append_triangle_facing(p00, p01, p10, direction, faces, normals)
	_append_triangle_facing(p10, p01, p11, direction, faces, normals)


static func _rectangle_loop(bounds: Rect2, height: float) -> PackedVector3Array:
	var center := bounds.get_center()
	return PackedVector3Array([
		Vector3(bounds.position.x, height, bounds.position.y),
		Vector3(center.x, height, bounds.position.y),
		Vector3(bounds.end.x, height, bounds.position.y),
		Vector3(bounds.end.x, height, center.y),
		Vector3(bounds.end.x, height, bounds.end.y),
		Vector3(center.x, height, bounds.end.y),
		Vector3(bounds.position.x, height, bounds.end.y),
		Vector3(bounds.position.x, height, center.y),
	])


static func _append_ring(
		outer: PackedVector3Array,
		inner: PackedVector3Array,
		direction: Vector3,
		faces: PackedVector3Array,
		normals: PackedVector3Array
) -> void:
	for index in range(LOOP_VERTEX_COUNT):
		var next := (index + 1) % LOOP_VERTEX_COUNT
		_append_triangle_facing(outer[index], outer[next], inner[next], direction, faces, normals)
		_append_triangle_facing(outer[index], inner[next], inner[index], direction, faces, normals)


static func _append_wall(
		top: PackedVector3Array,
		bottom: PackedVector3Array,
		outward: bool,
		faces: PackedVector3Array,
		normals: PackedVector3Array
) -> void:
	for index in range(LOOP_VERTEX_COUNT):
		var next := (index + 1) % LOOP_VERTEX_COUNT
		var direction := _horizontal_outward(top[index], top[next])
		if not outward:
			direction = -direction
		_append_triangle_facing(top[index], bottom[index], top[next], direction, faces, normals)
		_append_triangle_facing(top[next], bottom[index], bottom[next], direction, faces, normals)


static func _append_triangle_facing(
		a: Vector3,
		b: Vector3,
		c: Vector3,
		direction: Vector3,
		faces: PackedVector3Array,
		normals: PackedVector3Array
) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot(direction) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	faces.append_array(PackedVector3Array([a, b, c]))
	normals.append_array(PackedVector3Array([normal, normal, normal]))


static func _horizontal_outward(a: Vector3, b: Vector3) -> Vector3:
	var tangent := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	return Vector3(-tangent.z, 0.0, tangent.x)


static func _xz_bounds(points: PackedVector3Array) -> Rect2:
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for point in points:
		minimum = minimum.min(Vector2(point.x, point.z))
		maximum = maximum.max(Vector2(point.x, point.z))
	return Rect2(minimum, maximum - minimum)


static func _minimum_y(points: PackedVector3Array, count: int) -> float:
	var result := INF
	for index in range(count):
		result = minf(result, points[index].y)
	return result


static func _maximum_loop_gap(first: PackedVector3Array, second: PackedVector3Array) -> float:
	var maximum := 0.0
	for index in range(mini(first.size(), second.size())):
		maximum = maxf(maximum, first[index].distance_to(second[index]))
	return maximum
