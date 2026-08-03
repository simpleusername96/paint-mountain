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
	var faceted := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FACETED)
	_assert_geometry_contract(flat)
	_assert_geometry_contract(ramp)
	_assert_geometry_contract(faceted)
	_assert_exact_topology_queries(faceted)
	_assert_query_cost_is_bounded(faceted)
	_assert_production_contract()
	_assert_scene_contract()
	_assert_shader_contract()
	await _assert_fixture_casts(flat, ramp, faceted)
	if not _failed:
		print("Terrain geometry checks passed: canonical triangle parity, exact plane queries, 7,394 production faces, and deterministic headless casts.")
	quit(1 if _failed else 0)


func _assert_geometry_contract(layout: GeneratedStageLayout) -> void:
	var geometry := TerrainGeometryFactory.build(layout)
	_assert_true(geometry.is_valid(), "terrain geometry must be complete")
	_assert_true(geometry.top_topology == layout.top_topology, "geometry must retain the layout's one canonical top topology")
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
		_assert_true(colors[index].r <= 0.01, "shell vertices must be non-target-classified")
	_assert_outward_winding(geometry, vertices, normals)
	_assert_watertight(vertices)
	_assert_bounds(geometry, vertices)
	_assert_collision_parity(layout, geometry)


func _assert_production_contract() -> void:
	var layout := SeededStageGenerator.generate_structural_sequence(FIRST_DESCENT.generation_profile, FIRST_DESCENT.terrain_seed, FIRST_DESCENT)
	_assert_true(layout != null, "production geometry check requires the accepted stage layout")
	if layout == null:
		return
	_assert_true(layout.top_topology != null and layout.top_topology.is_valid(), "production layout must own canonical top topology")
	_assert_true(layout.top_topology.canonical_vertices_read_only().size() == 73 * 49, "production topology must contain one 73 x 49 vertex array")
	_assert_true(layout.top_topology.canonical_triangle_indices_read_only().size() == 6912 * 3, "production topology must contain one fixed 6,912-triangle index array")
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
	var topology := layout.top_topology
	var canonical_vertices := topology.canonical_vertices_read_only()
	var canonical_indices := topology.canonical_triangle_indices_read_only()
	var render_vertices: PackedVector3Array = geometry.render_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var collision_faces := geometry.top_shape.get_faces()
	_assert_true(canonical_indices.size() == geometry.top_vertex_count, "canonical index corners must match expanded top render corners")
	_assert_true(collision_faces.size() == canonical_indices.size(), "top concave collision must expand every canonical corner exactly once")
	_assert_true(geometry.top_render_source_vertex_indices == canonical_indices, "render source vertex IDs must preserve canonical order exactly")
	_assert_true(geometry.top_render_source_triangle_ids.size() == topology.triangle_count(), "render must retain one source ID per canonical triangle")
	for triangle_id in range(topology.triangle_count()):
		_assert_true(geometry.top_render_source_triangle_ids[triangle_id] == triangle_id, "render source triangle IDs must remain stable and ordered")
	for corner_index in range(canonical_indices.size()):
		var expected := canonical_vertices[canonical_indices[corner_index]]
		_assert_true(render_vertices[corner_index].is_equal_approx(expected), "render corner must equal its canonical source vertex")
		_assert_true(collision_faces[corner_index].is_equal_approx(expected), "collision corner must equal its canonical source vertex")
	_assert_true(geometry.top_shape.backface_collision, "top collider must accept the canonical upward render winding used by Godot physics")
	_assert_true(geometry.skirt_shape.backface_collision, "shell collider must accept backface contacts")


func _assert_exact_topology_queries(layout: GeneratedStageLayout) -> void:
	var topology := layout.top_topology
	var canonical_indices := topology.canonical_triangle_indices_read_only()
	var canonical_vertices := topology.canonical_vertices_read_only()
	var row_width := layout.sample_size().x
	var original_vertex := topology.vertex_at(0)
	canonical_vertices[0] += Vector3.ONE
	canonical_indices[0] = canonical_indices[0] + 1
	_assert_true(topology.vertex_at(0).is_equal_approx(original_vertex), "returned canonical vertices must be detached read-only copies")
	_assert_true(topology.triangle_vertex_indices(Vector2i.ZERO, 0).x == 0, "returned canonical indices must be detached read-only copies")
	canonical_indices = topology.canonical_triangle_indices_read_only()
	_assert_true(
		canonical_indices.slice(0, 6) == PackedInt32Array([0, row_width, 1, 1, row_width, row_width + 1]),
		"cell zero must freeze the P00/P01/P10 then P10/P01/P11 diagonal"
	)
	for cell_z in range(layout.cell_count.y):
		for cell_x in range(layout.cell_count.x):
			var cell := Vector2i(cell_x, cell_z)
			var p00 := cell_z * row_width + cell_x
			var p01 := (cell_z + 1) * row_width + cell_x
			var p10 := cell_z * row_width + cell_x + 1
			var p11 := (cell_z + 1) * row_width + cell_x + 1
			_assert_true(topology.triangle_vertex_indices(cell, 0) == Vector3i(p00, p01, p10), "every cell triangle zero must retain P00/P01/P10")
			_assert_true(topology.triangle_vertex_indices(cell, 1) == Vector3i(p10, p01, p11), "every cell triangle one must retain P10/P01/P11")
			_assert_true(topology.source_triangle_id(cell, 0) == (cell_z * layout.cell_count.x + cell_x) * 2, "triangle zero source ID must remain row-major")
			_assert_true(topology.source_triangle_id(cell, 1) == (cell_z * layout.cell_count.x + cell_x) * 2 + 1, "triangle one source ID must remain row-major")
	var query_cell := Vector2i(6, 5)
	var triangle_zero_xz := _cell_local_xz(layout, query_cell, Vector2(0.20, 0.30))
	var triangle_one_xz := _cell_local_xz(layout, query_cell, Vector2(0.75, 0.55))
	var triangle_zero := topology.surface_sample_at_local(triangle_zero_xz.x, triangle_zero_xz.y, false)
	var triangle_one := topology.surface_sample_at_local(triangle_one_xz.x, triangle_one_xz.y, false)
	_assert_true(triangle_zero.triangle == 0, "u+v below one must select canonical triangle zero")
	_assert_true(triangle_one.triangle == 1, "u+v above one must select canonical triangle one")
	for sample in [triangle_zero, triangle_one]:
		var source: Vector3i = sample.source_vertex_indices
		var barycentric: Vector3 = sample.barycentric
		var expected := topology.vertex_at(source.x) * barycentric.x \
				+ topology.vertex_at(source.y) * barycentric.y \
				+ topology.vertex_at(source.z) * barycentric.z
		_assert_true(sample.point.is_equal_approx(expected), "surface point must reconstruct from its exact canonical plane")
		_assert_true(sample.normal.is_equal_approx(topology.triangle_normal(sample.cell, sample.triangle)), "surface normal must be the exact canonical face normal")
	var old_bilinear := _bilinear_height(layout, triangle_zero_xz)
	_assert_true(absf(float(triangle_zero.point.y) - old_bilinear) > 0.05, "faceted fixture must prove exact triangle height replaced bilinear interpolation")
	var outer := topology.surface_sample_at_local(layout.local_bounds.end.x, layout.local_bounds.end.y, false)
	_assert_true(outer.cell == layout.cell_count - Vector2i.ONE and outer.triangle == 1, "outer maximum must clamp to the final cell and final triangle")


func _assert_query_cost_is_bounded(layout: GeneratedStageLayout) -> void:
	var started := Time.get_ticks_msec()
	var checksum := 0.0
	for pixel_y in range(512):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, (float(pixel_y) + 0.5) / 512.0)
		for pixel_x in range(512):
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, (float(pixel_x) + 0.5) / 512.0)
			checksum += float(layout.surface_sample_at_local(local_x, local_z).point.y)
	var elapsed_ms := Time.get_ticks_msec() - started
	_assert_true(is_finite(checksum), "full 512-square exact-query pass must remain finite")
	_assert_true(elapsed_ms < 5000, "surface queries must use cached topology validity instead of rescanning every vertex")
	print("Canonical 512x512 query pass: %d ms" % elapsed_ms)


func _cell_local_xz(layout: GeneratedStageLayout, cell: Vector2i, local_uv: Vector2) -> Vector2:
	var cell_size := layout.local_bounds.size / Vector2(layout.cell_count)
	return layout.local_bounds.position + Vector2(cell) * cell_size + local_uv * cell_size


func _bilinear_height(layout: GeneratedStageLayout, local_xz: Vector2) -> float:
	var normalized := (local_xz - layout.local_bounds.position) / layout.local_bounds.size
	var grid := normalized * Vector2(layout.cell_count)
	var cell := Vector2i(floori(grid.x), floori(grid.y))
	var uv := grid - Vector2(cell)
	var row_width := layout.sample_size().x
	var p00 := layout.heights[cell.y * row_width + cell.x]
	var p10 := layout.heights[cell.y * row_width + cell.x + 1]
	var p01 := layout.heights[(cell.y + 1) * row_width + cell.x]
	var p11 := layout.heights[(cell.y + 1) * row_width + cell.x + 1]
	return lerpf(lerpf(p00, p10, uv.x), lerpf(p01, p11, uv.x), uv.y)


func _assert_fixture_casts(
		flat: GeneratedStageLayout,
		ramp: GeneratedStageLayout,
		faceted: GeneratedStageLayout
) -> void:
	var flat_surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	root.add_child(flat_surface)
	flat_surface.configure(flat)
	await physics_frame
	await physics_frame
	_assert_true(
		flat_surface.get_node("TerrainTopBody").get_meta(ContainmentSpec.CONTACT_OWNER_META) == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		"top body must publish its stable contact owner ID"
	)
	_assert_true(
		flat_surface.get_node("TerrainTopBody/CollisionShape3D").get_meta(ContainmentSpec.CONTACT_SHAPE_META) == TerrainSurface.TOP_SHAPE_ID,
		"top shape must publish its stable contact shape ID"
	)
	_assert_true(
		flat_surface.get_node("TerrainShellBody").get_meta(ContainmentSpec.CONTACT_OWNER_META) == TerrainSurface.SHELL_OWNER_ID,
		"shell body must publish its stable contact owner ID"
	)
	_assert_true(
		flat_surface.get_node("TerrainShellBody/CollisionShape3D").get_meta(ContainmentSpec.CONTACT_SHAPE_META) == TerrainSurface.SHELL_SHAPE_ID,
		"shell shape must publish its stable contact shape ID"
	)
	var flat_top := await _cast_collider(Vector3(0, 10, 0), Vector3(0, -100, 0))
	_assert_true(flat_surface.is_top_collider(flat_top), "flat vertical cast must classify TerrainTopBody")
	var flat_graze := await _cast_collider(Vector3(-10, 1, 0), Vector3(80, -20, 0))
	_assert_true(flat_surface.is_top_collider(flat_graze), "flat graze cast must classify TerrainTopBody")
	var flat_skirt := await _cast_collider(Vector3(20, -4, 0), Vector3(-100, 0, 0))
	_assert_true(flat_surface.is_skirt_collider(flat_skirt), "flat skirt cast must classify TerrainShellBody")
	_assert_exact_ray(
		flat_surface,
		flat,
		_cell_local_xz(flat, Vector2i(4, 7), Vector2(0.40, 0.60)),
		"flat diagonal edge"
	)
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
	_assert_exact_ray(
		ramp_surface,
		ramp,
		_cell_local_xz(ramp, Vector2i(8, 3), Vector2(0.23, 0.31)),
		"ramp interior"
	)
	ramp_surface.queue_free()
	await physics_frame

	var faceted_surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	root.add_child(faceted_surface)
	faceted_surface.configure(faceted)
	await physics_frame
	await physics_frame
	var triangle_zero_xz := _cell_local_xz(faceted, Vector2i(6, 5), Vector2(0.20, 0.30))
	var triangle_one_xz := _cell_local_xz(faceted, Vector2i(6, 5), Vector2(0.75, 0.55))
	_assert_exact_ray(faceted_surface, faceted, triangle_zero_xz, "faceted triangle zero")
	_assert_exact_ray(faceted_surface, faceted, triangle_one_xz, "faceted triangle one")
	_assert_hit_rejection(faceted_surface, faceted, triangle_zero_xz)
	faceted_surface.queue_free()
	await physics_frame


func _assert_exact_ray(
		surface: TerrainSurface,
		layout: GeneratedStageLayout,
		local_xz: Vector2,
		label: String
) -> void:
	var expected := layout.surface_sample_at_local(local_xz.x, local_xz.y, false)
	var expected_world_point := surface.to_global(expected.point)
	var query := PhysicsRayQueryParameters3D.create(
		expected_world_point + Vector3.UP * 10.0,
		expected_world_point + Vector3.DOWN * 10.0,
		1
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
	_assert_true(not hit.is_empty(), "%s ray must hit the canonical top" % label)
	if hit.is_empty():
		return
	_assert_true(surface.is_top_collider(hit.collider), "%s ray must return TerrainTopBody" % label)
	_assert_true((hit.position as Vector3).distance_to(expected_world_point) <= 0.01, "%s engine ray must agree with the exact triangle plane within 0.01 m" % label)
	var identity := surface.classify_top_hit(hit.position, hit.normal, TerrainSurface.TOP_SHAPE_ID, 0)
	_assert_true(identity != null, "%s ray must produce a valid exact triangle identity" % label)
	if identity != null:
		_assert_true(identity.terrain_cell == expected.cell, "%s identity must retain the expected cell" % label)
		_assert_true(identity.terrain_triangle == expected.triangle, "%s identity must retain the expected triangle" % label)
		_assert_true(identity.barycentric.distance_to(expected.barycentric) <= 0.01, "%s identity must retain reconstructed barycentrics" % label)


func _assert_hit_rejection(
		surface: TerrainSurface,
		layout: GeneratedStageLayout,
		local_xz: Vector2
) -> void:
	var sample := layout.surface_sample_at_local(local_xz.x, local_xz.y, false)
	var world_point := surface.to_global(sample.point)
	var world_normal := (surface.global_transform.basis.inverse().transposed() * (sample.normal as Vector3)).normalized()
	_assert_true(
		surface.classify_top_hit(world_point, world_normal, TerrainSurface.TOP_SHAPE_ID, 0) != null,
		"exact point and face normal must classify"
	)
	var wrong_height_point := surface.to_global(sample.point + Vector3.UP * 0.051)
	_assert_true(
		surface.classify_top_hit(wrong_height_point, world_normal, TerrainSurface.TOP_SHAPE_ID, 0) == null,
		"top classification must reject reconstructed Y beyond 0.05 m"
	)
	var other_local_normal := layout.top_topology.triangle_normal(sample.cell, 1 - int(sample.triangle))
	var other_world_normal := (surface.global_transform.basis.inverse().transposed() * other_local_normal).normalized()
	_assert_true(
		rad_to_deg(acos(clampf(world_normal.dot(other_world_normal), -1.0, 1.0))) > 1.0,
		"faceted rejection fixture must expose distinguishable triangle normals"
	)
	_assert_true(
		surface.classify_top_hit(world_point, other_world_normal, TerrainSurface.TOP_SHAPE_ID, 0) == null,
		"top classification must reject a normal from the wrong triangle"
	)


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
