extends SceneTree

const FIXTURE_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const FIRST_DESCENT := preload("res://resources/stages/first_descent.tres")
const TOP_TRIANGLES := 288
const SKIRT_TRIANGLES := 96
const TOTAL_TRIANGLES := 386

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var flat := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	var ramp := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.RAMP)
	_assert_geometry_contract(flat)
	_assert_geometry_contract(ramp)
	_assert_production_contract()
	_assert_scene_contract()
	_assert_shader_contract()
	await _assert_fixture_casts(flat, ramp)
	if not _failed:
		print("Terrain geometry checks passed: production 7,394 triangles, closed normalized edges, top/shell identity, and four fixture casts.")
	quit(1 if _failed else 0)


func _assert_geometry_contract(layout: GeneratedStageLayout) -> void:
	var geometry := TerrainGeometryFactory.build(layout)
	_assert_true(geometry.is_valid(), "terrain geometry must be complete")
	_assert_true(geometry.top_triangle_count == TOP_TRIANGLES, "12 x 12 fixture must have 288 top triangles")
	_assert_true(geometry.skirt_triangle_count == SKIRT_TRIANGLES, "12 x 12 fixture must have 96 skirt triangles")
	_assert_true(geometry.bottom_triangle_count == 2, "fixture must have two bottom triangles")
	_assert_true(geometry.total_triangle_count() == TOTAL_TRIANGLES, "fixture closed shell must have 386 triangles")
	_assert_true(geometry.render_mesh.get_surface_count() == 1, "closed render shell must remain one mesh surface")
	var arrays := geometry.render_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	_assert_true(vertices.size() == TOTAL_TRIANGLES * 3, "render vertex count must match unindexed flat facets")
	_assert_true(normals.size() == vertices.size(), "every flat-facet vertex must have a normal")
	_assert_true(colors.size() == vertices.size(), "every vertex must classify top versus shell")
	for index in range(geometry.top_vertex_count):
		_assert_true(colors[index].r >= 0.99, "top vertices must be paintable-classified")
	for index in range(geometry.top_vertex_count, colors.size()):
		_assert_true(colors[index].r <= 0.01, "shell vertices must be excluded-classified")
	_assert_outward_winding(geometry, vertices, normals)
	_assert_watertight(vertices)
	_assert_bounds(geometry, vertices)
	_assert_collision_parity(layout, geometry)


func _assert_production_contract() -> void:
	var layout := SeededStageGenerator.generate(FIRST_DESCENT.generation_profile, FIRST_DESCENT.terrain_seed, FIRST_DESCENT)
	_assert_true(layout != null, "production geometry check requires the accepted stage layout")
	if layout == null:
		return
	var geometry := TerrainGeometryFactory.build(layout)
	_assert_true(geometry.top_triangle_count == 6912, "production top must contain 6,912 triangles")
	_assert_true(geometry.skirt_triangle_count == 480, "production skirts must contain 480 triangles")
	_assert_true(geometry.bottom_triangle_count == 2, "production bottom must contain two triangles")
	_assert_true(geometry.total_triangle_count() == 7394, "production closed shell must contain exactly 7,394 triangles")
	var vertices: PackedVector3Array = geometry.render_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_assert_watertight(vertices)
	_assert_collision_parity(layout, geometry)


func _assert_scene_contract() -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	var surface := gameplay.get_node_or_null("TerrainSurface") as TerrainSurface
	_assert_true(surface != null, "gameplay scene must own a stable TerrainSurface")
	_assert_true(surface != null and surface.get_node_or_null("TerrainTopBody") is StaticBody3D, "gameplay scene must own TerrainTopBody")
	_assert_true(surface != null and surface.get_node_or_null("TerrainShellBody") is StaticBody3D, "gameplay scene must own TerrainShellBody")
	gameplay.free()


func _assert_shader_contract() -> void:
	var file := FileAccess.open("res://src/paint/terrain_paint.gdshader", FileAccess.READ)
	_assert_true(file != null, "terrain shader must be readable")
	if file == null:
		return
	var source := file.get_as_text()
	_assert_true(not source.contains("unshaded"), "terrain shader must use scene lighting")
	_assert_true(not source.contains("EMISSION"), "terrain shader must not emit light")
	_assert_true(source.contains("0.88") and source.contains("0.24"), "terrain shader must freeze dry and painted roughness")
	_assert_true(source.contains("shadow_tint") and source.contains("dark_rim"), "terrain shader must include shadow tint and restrained paint rim")


func _assert_outward_winding(geometry: TerrainGeometry, vertices: PackedVector3Array, normals: PackedVector3Array) -> void:
	for index in range(0, geometry.top_vertex_count, 3):
		_assert_true(normals[index].y > 0.0, "top triangle winding must face upward")
	var bottom_start := vertices.size() - geometry.bottom_triangle_count * 3
	for index in range(bottom_start, vertices.size(), 3):
		_assert_true(normals[index].y < 0.0, "bottom-cap winding must face downward")


func _assert_watertight(vertices: PackedVector3Array) -> void:
	var edge_counts: Dictionary = {}
	var bottom_start := vertices.size() - 6
	for index in range(0, vertices.size(), 3):
		for edge in [[vertices[index], vertices[index + 1]], [vertices[index + 1], vertices[index + 2]], [vertices[index + 2], vertices[index]]]:
			if index >= bottom_start and _is_axis_aligned_boundary_edge(edge[0], edge[1]):
				_count_segmented_edge(edge_counts, edge[0], edge[1])
			else:
				_count_edge(edge_counts, edge[0], edge[1])
	var invalid_count := 0
	for count in edge_counts.values():
		if int(count) != 2:
			invalid_count += 1
	_assert_true(invalid_count == 0, "every normalized closed-shell edge must belong to exactly two faces; invalid=%d" % invalid_count)


func _is_axis_aligned_boundary_edge(a: Vector3, b: Vector3) -> bool:
	return is_equal_approx(a.y, b.y) and (is_equal_approx(a.x, b.x) or is_equal_approx(a.z, b.z))


func _count_segmented_edge(counts: Dictionary, a: Vector3, b: Vector3) -> void:
	var segment_count := roundi(a.distance_to(b) / 2.5)
	for index in range(segment_count):
		_count_edge(counts, a.lerp(b, float(index) / float(segment_count)), a.lerp(b, float(index + 1) / float(segment_count)))


func _count_edge(counts: Dictionary, a: Vector3, b: Vector3) -> void:
	var first := _quantized_key(a)
	var second := _quantized_key(b)
	var key := "%s|%s" % [first, second] if first < second else "%s|%s" % [second, first]
	counts[key] = int(counts.get(key, 0)) + 1


func _quantized_key(point: Vector3) -> String:
	return "%d,%d,%d" % [roundi(point.x * 1000.0), roundi(point.y * 1000.0), roundi(point.z * 1000.0)]


func _assert_bounds(geometry: TerrainGeometry, vertices: PackedVector3Array) -> void:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for vertex in vertices:
		minimum = minimum.min(vertex)
		maximum = maximum.max(vertex)
	_assert_true(is_equal_approx(minimum.x, geometry.local_bounds.position.x), "render minimum X must match local bounds")
	_assert_true(is_equal_approx(maximum.x, geometry.local_bounds.end.x), "render maximum X must match local bounds")
	_assert_true(is_equal_approx(minimum.z, geometry.local_bounds.position.y), "render minimum Z must match local bounds")
	_assert_true(is_equal_approx(maximum.z, geometry.local_bounds.end.y), "render maximum Z must match local bounds")
	_assert_true(is_equal_approx(minimum.y, geometry.base_y), "render shell must reach the frozen base Y")


func _assert_collision_parity(layout: GeneratedStageLayout, geometry: TerrainGeometry) -> void:
	_assert_true(geometry.top_shape.map_width == layout.sample_size().x, "heightmap width must match layout samples")
	_assert_true(geometry.top_shape.map_depth == layout.sample_size().y, "heightmap depth must match layout samples")
	var collision_heights := geometry.top_shape.map_data
	for index in range(layout.heights.size()):
		_assert_true(absf(collision_heights[index] * geometry.cell_size - layout.heights[index]) <= 0.01, "render and collision height samples must match within 0.01 m")
	_assert_true(geometry.skirt_shape.backface_collision, "shell collider must accept backface contacts")


func _assert_fixture_casts(flat: GeneratedStageLayout, ramp: GeneratedStageLayout) -> void:
	var flat_surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	root.add_child(flat_surface)
	flat_surface.configure(flat)
	await physics_frame
	await physics_frame
	var flat_top := await _cast_collider(Vector3(0, 10, 0), Vector3(0, -100, 0))
	_assert_true(flat_surface.is_top_collider(flat_top), "flat vertical cast must classify TerrainTopBody")
	var flat_graze := await _cast_collider(Vector3(-10, 1, 0), Vector3(80, -20, 0))
	_assert_true(flat_surface.is_top_collider(flat_graze), "flat graze cast must classify TerrainTopBody")
	var flat_skirt := await _cast_collider(Vector3(20, -4, 0), Vector3(-100, 0, 0))
	_assert_true(flat_surface.is_skirt_collider(flat_skirt), "flat skirt cast must classify TerrainShellBody")
	flat_surface.queue_free()
	await physics_frame

	var ramp_surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	root.add_child(ramp_surface)
	ramp_surface.configure(ramp)
	await physics_frame
	await physics_frame
	var ramp_y := TerrainTestFixtureFactory.ramp_height(0.0)
	var ramp_top := await _cast_collider(Vector3(0, ramp_y + 10, 0), Vector3(0, -100, 0))
	_assert_true(ramp_surface.is_top_collider(ramp_top), "35-degree ramp cast must classify TerrainTopBody")
	ramp_surface.queue_free()
	await physics_frame


func _cast_collider(start: Vector3, motion: Vector3) -> Object:
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, start)
	query.motion = motion
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var space := root.get_world_3d().direct_space_state
	var fractions := space.cast_motion(query)
	if fractions.is_empty() or fractions[0] >= 1.0:
		return null
	query.transform.origin = start + motion * minf(float(fractions[1]) + 0.002, 1.0)
	var hits := space.intersect_shape(query, 8)
	return hits[0].collider if not hits.is_empty() else null


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Terrain geometry check failed: %s" % message)
