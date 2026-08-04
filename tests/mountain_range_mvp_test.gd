extends SceneTree

const STAGES: Array[StageData] = [
	preload("res://resources/stages/first_descent.tres"),
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]
const MINIMUM_FOOTPRINT_RATIO := 0.35
const MAXIMUM_FOOTPRINT_RATIO := 0.80
const MINIMUM_BACKBONE_HEIGHT_RATIO := 0.65

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	for stage in STAGES:
		_assert_stage(stage)
	if not _failed:
		print("Mountain range MVP passed: three row-solid masses, central backbones, closed shared geometry, and complete mechanism placement.")
	quit(1 if _failed else 0)


func _assert_stage(stage: StageData) -> void:
	var resolved_graph := RouteGraphResolver.resolve(
		stage.stage_id,
		stage.generation_profile,
		stage.terrain_seed
	)
	_assert_true(resolved_graph != null, "%s route graph must resolve" % stage.stage_id)
	if resolved_graph != null:
		for route_index in range(resolved_graph.route_count()):
			_assert_true(
				resolved_graph.route_reversal_count(route_index) \
						== stage.generation_profile.routes[route_index].reversal_count(),
				"%s route %d must preserve its authored ascent/descent count" % [
					stage.stage_id, route_index,
				]
			)
	var layout := SeededStageGenerator.generate(
		stage.generation_profile,
		stage.terrain_seed,
		stage
	)
	_assert_true(layout != null, "%s must generate from its persisted seed" % stage.stage_id)
	if layout == null:
		return
	_assert_true(stage.stage_version == 5, "%s StageData must use generation v5" % stage.stage_id)
	_assert_true(layout.is_valid(), "%s layout must satisfy the v5 structural contract" % stage.stage_id)
	_assert_true(
		layout.route_graph.route_count() == stage.stage_number,
		"%s route count must increase with stage level" % stage.stage_id
	)
	_assert_row_solid_footprint(stage, layout)
	_assert_backbone(stage, layout)

	var geometry := TerrainGeometryFactory.build(layout)
	_assert_true(geometry.is_valid(), "%s must build complete shared geometry" % stage.stage_id)
	_assert_true(
		geometry.top_shape.get_faces().size() == geometry.top_vertex_count,
		"%s collision and rendered top corners must match" % stage.stage_id
	)
	_assert_watertight(stage, geometry)
	_assert_true(
		layout.mechanism_placements.size() == stage.mechanism_loadout.size(),
		"%s must place every configured mechanism" % stage.stage_id
	)
	print("%s: cells=%d top_triangles=%d shell_triangles=%d mechanisms=%d backbone=%.3f" % [
		stage.stage_id,
		_active_cell_count(layout.footprint_cells_read_only()),
		geometry.top_triangle_count,
		geometry.skirt_triangle_count,
		layout.mechanism_placements.size(),
		layout.height_at_local(0.0, -24.0) \
				/ maxf(float(layout.metrics.get("maximum_height", 0.0)), 0.001),
	])


func _assert_row_solid_footprint(stage: StageData, layout: GeneratedStageLayout) -> void:
	var cells := layout.footprint_cells_read_only()
	var size := layout.cell_count
	var active_count := _active_cell_count(cells)
	var ratio := float(active_count) / float(cells.size())
	_assert_true(
		ratio >= MINIMUM_FOOTPRINT_RATIO and ratio <= MAXIMUM_FOOTPRINT_RATIO,
		"%s footprint must be substantial without reverting to a full slab" % stage.stage_id
	)
	var saw_mass := false
	var saw_gap_after_mass := false
	var previous_left := -1
	var previous_right := -1
	var minimum_span := size.x
	var maximum_span := 0
	for z in range(size.y):
		var left := -1
		var right := -1
		var ended := false
		for x in range(size.x):
			var active := cells[z * size.x + x] != 0
			if active:
				_assert_true(not ended, "%s footprint row %d must contain one span" % [stage.stage_id, z])
				if left < 0:
					left = x
				right = x
			elif left >= 0:
				ended = true
		if left < 0:
			if saw_mass:
				saw_gap_after_mass = true
			continue
		_assert_true(not saw_gap_after_mass, "%s footprint cannot restart after an empty row" % stage.stage_id)
		if not saw_mass:
			_assert_true(z == 0, "%s footprint must join the rear wall" % stage.stage_id)
		if previous_left >= 0:
			_assert_true(
				left <= previous_right and right >= previous_left,
				"%s adjacent footprint rows must overlap" % stage.stage_id
			)
		saw_mass = true
		minimum_span = mini(minimum_span, right - left + 1)
		maximum_span = maxi(maximum_span, right - left + 1)
		previous_left = left
		previous_right = right
	_assert_true(saw_mass, "%s footprint must contain terrain" % stage.stage_id)
	_assert_true(
		maximum_span - minimum_span >= 4,
		"%s footprint must taper instead of forming a rectangular slab" % stage.stage_id
	)


func _assert_backbone(stage: StageData, layout: GeneratedStageLayout) -> void:
	var maximum_height := float(layout.metrics.get("maximum_height", 0.0))
	var center_height := layout.height_at_local(0.0, -24.0)
	_assert_true(maximum_height > 0.0, "%s must have positive mountain height" % stage.stage_id)
	_assert_true(
		center_height / maxf(maximum_height, 0.001) >= MINIMUM_BACKBONE_HEIGHT_RATIO,
		"%s central backbone must remain high instead of becoming a basin" % stage.stage_id
	)


func _assert_watertight(stage: StageData, geometry: TerrainGeometry) -> void:
	var vertices: PackedVector3Array = geometry.render_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var edge_counts: Dictionary = {}
	for index in range(0, vertices.size(), 3):
		_count_edge(edge_counts, vertices[index], vertices[index + 1])
		_count_edge(edge_counts, vertices[index + 1], vertices[index + 2])
		_count_edge(edge_counts, vertices[index + 2], vertices[index])
	var invalid_count := 0
	for count in edge_counts.values():
		if int(count) != 2:
			invalid_count += 1
	_assert_true(
		invalid_count == 0,
		"%s closed mesh must give every edge exactly two owning triangles; invalid=%d" % [
			stage.stage_id, invalid_count,
		]
	)


func _count_edge(counts: Dictionary, a: Vector3, b: Vector3) -> void:
	var first := _point_key(a)
	var second := _point_key(b)
	var key := "%s|%s" % [first, second] if first < second else "%s|%s" % [second, first]
	counts[key] = int(counts.get(key, 0)) + 1


func _point_key(point: Vector3) -> String:
	return "%d,%d,%d" % [
		roundi(point.x * 1000.0),
		roundi(point.y * 1000.0),
		roundi(point.z * 1000.0),
	]


func _active_cell_count(cells: PackedByteArray) -> int:
	var count := 0
	for value in cells:
		if value != 0:
			count += 1
	return count


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Mountain range MVP check failed: %s" % message)
