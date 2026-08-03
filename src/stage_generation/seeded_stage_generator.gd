class_name SeededStageGenerator
extends RefCounted

const ROUTE_GRAPH_RESOLVER := preload("res://src/stage_generation/route_graph_resolver.gd")
const ROUTE_GRAPH_HEIGHT_SYNTHESIZER := preload("res://src/stage_generation/route_graph_height_synthesizer.gd")
const DECORATION_MODEL_CYCLE: Array[StringName] = [
	&"tree_pineSmallA", &"tree_pineSmallB", &"rock_smallA", &"tree_pineTallA", &"rock_largeA",
]


static func generate(
		profile: StageGenerationProfile,
		terrain_seed: int = 0,
		stage_data: StageData = null
) -> GeneratedStageLayout:
	if profile == null or not profile.is_valid():
		push_error("Stage generation profile is invalid.")
		return null
	var contract := profile.generation_contract
	var stage_id := stage_data.stage_id if stage_data != null else StringName(
		String(profile.profile_id).trim_suffix("_v4")
	)
	var requested_seed := terrain_seed if terrain_seed != 0 else profile.base_seed
	for attempt_index in range(contract.attempt_count):
		var attempt_seed := int((requested_seed + attempt_index * contract.attempt_seed_stride) & 0x7fffffff)
		var layout := _build_attempt(stage_id, profile, requested_seed, attempt_seed, attempt_index)
		if _validate(profile, layout) and _finalize_layout(profile, stage_data, layout):
			return layout
	var fallback := _build_attempt(stage_id, profile, requested_seed, profile.fallback_seed, -1)
	if _validate(profile, fallback) and _finalize_layout(profile, stage_data, fallback):
		push_warning("Stage generation used validated fallback seed %d for %s." % [profile.fallback_seed, profile.profile_id])
		return fallback
	var failure_metrics := fallback.metrics if fallback != null else {"rejection": "route_graph"}
	push_error("Stage generation failed every deterministic attempt and fallback for %s: %s" % [profile.profile_id, str(failure_metrics)])
	return null


static func _build_attempt(
		stage_id: StringName,
		profile: StageGenerationProfile,
		requested_seed: int,
		attempt_seed: int,
		attempt_index: int
) -> GeneratedStageLayout:
	var graph: GeneratedRouteGraph = ROUTE_GRAPH_RESOLVER.resolve(stage_id, profile, attempt_seed)
	if graph == null:
		return null
	var contract := profile.generation_contract
	var heights: PackedFloat32Array = ROUTE_GRAPH_HEIGHT_SYNTHESIZER.build(stage_id, profile, graph, attempt_seed)

	var layout := GeneratedStageLayout.new()
	layout.profile_id = profile.profile_id
	layout.profile_version = profile.profile_version
	layout.layout_version = contract.layout_version
	layout.terrain_seed = requested_seed
	layout.accepted_seed = attempt_seed
	layout.generation_attempt = attempt_index
	layout.cell_count = contract.cell_count
	layout.local_bounds = contract.local_bounds
	layout.heights = heights
	layout.route_graph = graph
	layout.checksum = _height_checksum(heights)
	return layout


static func _validate(profile: StageGenerationProfile, layout: GeneratedStageLayout) -> bool:
	if layout == null or not layout.is_valid():
		return false
	var maximum_height := 0.0
	for height in layout.heights:
		if not is_finite(height):
			layout.metrics = {"rejection": "non_finite_height"}
			return false
		maximum_height = maxf(maximum_height, height)
	layout.metrics = {"maximum_height": maximum_height}
	if maximum_height < profile.accepted_height_range.x or maximum_height > profile.accepted_height_range.y:
		layout.metrics["rejection"] = "maximum_height"
		return false
	if not _validate_edges(layout):
		layout.metrics["rejection"] = "edge_height"
		return false
	if not _validate_routes(profile, layout):
		return false
	if not _validate_pads(layout):
		layout.metrics["rejection"] = "mechanism_pad"
		return false
	var footprint_ratio: float = ROUTE_GRAPH_HEIGHT_SYNTHESIZER.route_footprint_ratio(
		layout.route_graph, profile.generation_contract
	)
	layout.metrics["route_footprint_ratio"] = footprint_ratio
	if footprint_ratio < profile.target_ratio_range.x or footprint_ratio > profile.target_ratio_range.y:
		layout.metrics["rejection"] = "route_footprint_ratio"
		return false
	layout.metrics["top_triangles"] = profile.generation_contract.top_triangle_count
	return true


static func _validate_edges(layout: GeneratedStageLayout) -> bool:
	var size := layout.sample_size()
	for x in range(size.x):
		if layout.heights[x] > 0.01 or layout.heights[(size.y - 1) * size.x + x] > 0.01:
			return false
	for z in range(size.y):
		if layout.heights[z * size.x] > 0.01 or layout.heights[z * size.x + size.x - 1] > 0.01:
			return false
	return true


static func _validate_routes(profile: StageGenerationProfile, layout: GeneratedStageLayout) -> bool:
	var graph := layout.route_graph
	if graph.route_count() != profile.routes.size():
		layout.metrics["rejection"] = "route_count"
		return false
	var maximum_node_height := -INF
	for node in graph.nodes:
		maximum_node_height = maxf(maximum_node_height, node.position.y)
	if not is_equal_approx(maximum_node_height, profile.nominal_peak):
		layout.metrics["rejection"] = "graph_peak"
		return false
	var all_slopes := PackedFloat32Array()
	var reversal_counts := PackedInt32Array()
	for route_index in range(graph.route_count()):
		if graph.route_role(route_index) != profile.routes[route_index].role:
			layout.metrics["rejection"] = "route_role"
			return false
		var reversals := graph.route_reversal_count(route_index)
		reversal_counts.append(reversals)
		if reversals != profile.routes[route_index].reversal_count():
			layout.metrics["rejection"] = "route_reversals"
			return false
		for point in graph.route_nodes(route_index):
			var edge_distance := minf(
				minf(point.position.x - layout.local_bounds.position.x, layout.local_bounds.end.x - point.position.x),
				minf(point.position.z - layout.local_bounds.position.y, layout.local_bounds.end.y - point.position.z)
			)
			if edge_distance < profile.generation_contract.outer_band_width:
				layout.metrics["rejection"] = "route_edge_clearance"
				return false
		for edge in graph.route_edges(route_index):
			var start := graph.node_by_id(edge.from_node_id).position
			var finish := graph.node_by_id(edge.to_node_id).position
			var horizontal_distance := Vector2(start.x, start.z).distance_to(Vector2(finish.x, finish.z))
			all_slopes.append(rad_to_deg(atan(absf(finish.y - start.y) / maxf(horizontal_distance, 0.001))))
	if all_slopes.is_empty():
		layout.metrics["rejection"] = "route_slope_samples"
		return false
	all_slopes.sort()
	var p95_index := clampi(floori(float(all_slopes.size() - 1) * 0.95), 0, all_slopes.size() - 1)
	var maximum_slope := all_slopes[-1]
	var p95_slope := all_slopes[p95_index]
	layout.metrics["route_reversals"] = reversal_counts
	layout.metrics["maximum_route_slope"] = maximum_slope
	layout.metrics["p95_route_slope"] = p95_slope
	if p95_slope > profile.route_core_p95_slope_max:
		layout.metrics["rejection"] = "route_core_p95_slope"
		return false
	return true


static func _validate_pads(layout: GeneratedStageLayout) -> bool:
	for pad in layout.route_graph.pad_nodes():
		var center := pad.position
		# Stay inside the fixed 65% flat core after temporary bilinear grid sampling.
		var radius := pad.pad_radius * 0.30
		for sample_index in range(17):
			var point := Vector2(center.x, center.z)
			if sample_index > 0:
				var angle := TAU * float(sample_index - 1) / 16.0
				point += Vector2(cos(angle), sin(angle)) * radius
			var slope := _local_slope_degrees(layout, point, 0.25)
			if slope > 8.0:
				return false
	return true


static func _finalize_layout(
		profile: StageGenerationProfile,
		stage_data: StageData,
		layout: GeneratedStageLayout
) -> bool:
	if stage_data != null:
		if not stage_data.mechanism_loadout.is_empty():
			layout.mechanism_placements = MechanismPlacementGenerator.generate(stage_data, layout)
			if layout.mechanism_placements.size() != stage_data.mechanism_loadout.size():
				layout.metrics["rejection"] = "mechanism_placement"
				return false
		layout.decoration_placements = _generate_decorations(stage_data, layout)
		if layout.decoration_placements.size() != _decoration_count(stage_data.stage_number):
			layout.metrics["rejection"] = "decoration_placement"
			return false
	var contract := profile.generation_contract
	var eligible_result := _build_eligible_mask(layout, contract)
	layout.eligible_mask = eligible_result.bytes
	layout.metrics["eligible_ratio"] = float(eligible_result.count) / float(contract.mask_size * contract.mask_size)
	_exclude_footprints(layout, contract.mask_size)
	var eligible_count := 0
	for byte in layout.eligible_mask:
		if byte >= 128:
			eligible_count += 1
	var eligible_ratio := float(eligible_count) / float(contract.mask_size * contract.mask_size)
	layout.metrics["eligible_ratio_after_exclusions"] = eligible_ratio
	layout.eligible_mask_checksum = _byte_checksum(layout.eligible_mask)
	return true


static func _build_eligible_mask(
		layout: GeneratedStageLayout,
		contract: StageGenerationContract
) -> Dictionary:
	var mask := PackedByteArray()
	mask.resize(contract.mask_size * contract.mask_size)
	var sample_size := layout.sample_size()
	var normal_y := PackedFloat32Array()
	normal_y.resize(layout.heights.size())
	var step_x := layout.local_bounds.size.x / float(layout.cell_count.x)
	var step_z := layout.local_bounds.size.y / float(layout.cell_count.y)
	for z_index in range(sample_size.y):
		var back := maxi(z_index - 1, 0)
		var front := mini(z_index + 1, sample_size.y - 1)
		for x_index in range(sample_size.x):
			var left := maxi(x_index - 1, 0)
			var right := mini(x_index + 1, sample_size.x - 1)
			var dx := (layout.heights[z_index * sample_size.x + right] - layout.heights[z_index * sample_size.x + left]) \
					/ maxf(float(right - left) * step_x, step_x)
			var dz := (layout.heights[front * sample_size.x + x_index] - layout.heights[back * sample_size.x + x_index]) \
					/ maxf(float(front - back) * step_z, step_z)
			normal_y[z_index * sample_size.x + x_index] = Vector3(-dx, 1.0, -dz).normalized().y
	var count := 0
	for pixel_y in range(contract.mask_size):
		var normalized_y := (float(pixel_y) + 0.5) / float(contract.mask_size)
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, normalized_y)
		var grid_z := normalized_y * float(layout.cell_count.y)
		var z0 := mini(floori(grid_z), layout.cell_count.y)
		var z1 := mini(z0 + 1, layout.cell_count.y)
		var tz := grid_z - float(z0)
		for pixel_x in range(contract.mask_size):
			var normalized_x := (float(pixel_x) + 0.5) / float(contract.mask_size)
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, normalized_x)
			var edge_distance := minf(
				minf(local_x - layout.local_bounds.position.x, layout.local_bounds.end.x - local_x),
				minf(local_z - layout.local_bounds.position.y, layout.local_bounds.end.y - local_z)
			)
			if edge_distance < 2.5:
				continue
			var grid_x := normalized_x * float(layout.cell_count.x)
			var x0 := mini(floori(grid_x), layout.cell_count.x)
			var x1 := mini(x0 + 1, layout.cell_count.x)
			var tx := grid_x - float(x0)
			var top_height := lerpf(layout.heights[z0 * sample_size.x + x0], layout.heights[z0 * sample_size.x + x1], tx)
			var bottom_height := lerpf(layout.heights[z1 * sample_size.x + x0], layout.heights[z1 * sample_size.x + x1], tx)
			if lerpf(top_height, bottom_height, tz) < 4.0:
				continue
			var top_normal_y := lerpf(normal_y[z0 * sample_size.x + x0], normal_y[z0 * sample_size.x + x1], tx)
			var bottom_normal_y := lerpf(normal_y[z1 * sample_size.x + x0], normal_y[z1 * sample_size.x + x1], tx)
			if lerpf(top_normal_y, bottom_normal_y, tz) < cos(deg_to_rad(75.0)):
				continue
			mask[pixel_y * contract.mask_size + pixel_x] = 255
			count += 1
	return {"bytes": mask, "count": count}


static func _exclude_footprints(layout: GeneratedStageLayout, mask_size: int) -> void:
	for placement in layout.mechanism_placements:
		_clear_mask_circle(layout, placement.local_xz, _mechanism_exclusion_radius(placement.mechanism_data.kind), mask_size)
	for decoration in layout.decoration_placements:
		_clear_mask_circle(layout, decoration.local_xz, _decoration_footprint_radius(decoration), mask_size)


static func _clear_mask_circle(
		layout: GeneratedStageLayout,
		center: Vector2,
		radius: float,
		mask_size: int
) -> void:
	var minimum_u := (center.x - radius - layout.local_bounds.position.x) / layout.local_bounds.size.x
	var maximum_u := (center.x + radius - layout.local_bounds.position.x) / layout.local_bounds.size.x
	var minimum_v := (center.y - radius - layout.local_bounds.position.y) / layout.local_bounds.size.y
	var maximum_v := (center.y + radius - layout.local_bounds.position.y) / layout.local_bounds.size.y
	var minimum_x := clampi(floori(minimum_u * mask_size - 0.5), 0, mask_size - 1)
	var maximum_x := clampi(ceili(maximum_u * mask_size - 0.5), 0, mask_size - 1)
	var minimum_y := clampi(floori(minimum_v * mask_size - 0.5), 0, mask_size - 1)
	var maximum_y := clampi(ceili(maximum_v * mask_size - 0.5), 0, mask_size - 1)
	for pixel_y in range(minimum_y, maximum_y + 1):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, (float(pixel_y) + 0.5) / float(mask_size))
		for pixel_x in range(minimum_x, maximum_x + 1):
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, (float(pixel_x) + 0.5) / float(mask_size))
			if center.distance_squared_to(Vector2(local_x, local_z)) <= radius * radius:
				layout.eligible_mask[pixel_y * mask_size + pixel_x] = 0


static func _generate_decorations(stage_data: StageData, layout: GeneratedStageLayout) -> Array[DecorationPlacement]:
	var candidates: Array[Vector2] = []
	var sample_size := layout.sample_size()
	for z_index in range(2, sample_size.y - 2):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, float(z_index) / float(layout.cell_count.y))
		for x_index in range(2, sample_size.x - 2):
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, float(x_index) / float(layout.cell_count.x))
			if layout.height_at_local(local_x, local_z) < 4.0:
				continue
			if layout.normal_at_local(local_x, local_z).y < cos(deg_to_rad(42.0)):
				continue
			var route_distance := layout.route_graph.nearest_edge(Vector2(local_x, local_z))
			var route_edge := route_distance.edge as GeneratedRouteEdge
			if route_edge != null and float(route_distance.distance) < 0.75 * route_edge.width + 1.0:
				continue
			var local_xz := Vector2(local_x, local_z)
			var mechanism_clear := true
			for mechanism in layout.mechanism_placements:
				if local_xz.distance_to(mechanism.local_xz) < _mechanism_exclusion_radius(mechanism.mechanism_data.kind) + 5.0:
					mechanism_clear = false
					break
			if mechanism_clear:
				candidates.append(local_xz)
	var rng := RandomNumberGenerator.new()
	rng.seed = int((layout.accepted_seed ^ 0x5A17D3C1) & 0x7fffffff)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary
	var result: Array[DecorationPlacement] = []
	var requested_count := _decoration_count(stage_data.stage_number)
	for candidate in candidates:
		var separated := true
		for existing in result:
			if candidate.distance_to(existing.local_xz) < 4.0:
				separated = false
				break
		if not separated:
			continue
		var model_id := DECORATION_MODEL_CYCLE[result.size() % DECORATION_MODEL_CYCLE.size()]
		var is_tree := String(model_id).begins_with("tree_")
		var scale_value := rng.randf_range(3.0, 4.5) if is_tree else rng.randf_range(2.0, 3.2)
		result.append(DecorationPlacement.new(model_id, candidate, rng.randf_range(0.0, 360.0), scale_value))
		if result.size() >= requested_count:
			break
	return result


static func _edge_distance(bounds: Rect2, point: Vector2) -> float:
	return minf(
		minf(point.x - bounds.position.x, bounds.end.x - point.x),
		minf(point.y - bounds.position.y, bounds.end.y - point.y)
	)


static func _local_slope_degrees(layout: GeneratedStageLayout, point: Vector2, step: float) -> float:
	var left := layout.height_at_local(point.x - step, point.y)
	var right := layout.height_at_local(point.x + step, point.y)
	var back := layout.height_at_local(point.x, point.y - step)
	var front := layout.height_at_local(point.x, point.y + step)
	var normal := Vector3(left - right, 2.0 * step, back - front).normalized()
	return rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))


static func _mechanism_exclusion_radius(kind: MechanismData.Kind) -> float:
	match kind:
		MechanismData.Kind.BURST:
			return 2.8
		MechanismData.Kind.SPLITTER:
			return 2.75
		_:
			return 2.9


static func _decoration_footprint_radius(decoration: DecorationPlacement) -> float:
	var base_radius := 0.35
	if decoration.model_id == &"tree_pineTallA":
		base_radius = 0.45
	elif decoration.model_id == &"rock_smallA":
		base_radius = 0.40
	elif decoration.model_id == &"rock_largeA":
		base_radius = 0.80
	return base_radius * decoration.uniform_scale + 0.5


static func _decoration_count(stage_number: int) -> int:
	match stage_number:
		2:
			return 14
		3:
			return 18
		_:
			return 10


static func _height_checksum(heights: PackedFloat32Array) -> int:
	var hash: int = 2166136261
	for height in heights:
		var quantized := roundi(height * 1000.0)
		for shift in [0, 8, 16, 24]:
			hash = hash ^ ((quantized >> shift) & 0xff)
			hash = int((hash * 16777619) & 0xffffffff)
	return hash


static func _byte_checksum(bytes: PackedByteArray) -> int:
	var hash: int = 2166136261
	for byte in bytes:
		hash = hash ^ byte
		hash = int((hash * 16777619) & 0xffffffff)
	return hash
