class_name MountainHeightFieldBuilder
extends RefCounted

## Internal height-field helper for RouteGraphMountainSynthesizer. It does not
## decide which cells physically exist and is not a terrain owner.

const KEYED_STAGE_SAMPLER := preload("res://src/stage_generation/keyed_stage_sampler.gd")


static func build(
		stage_id: StringName,
		profile: StageGenerationProfile,
		graph: GeneratedRouteGraph,
		attempt_seed: int
) -> PackedFloat32Array:
	var contract := profile.generation_contract
	var noise := FastNoiseLite.new()
	noise.seed = KEYED_STAGE_SAMPLER.fnv1a32(
		"paint_mountain:%s:v4:%d:noise/seed" % [String(stage_id), attempt_seed]
	) & 0x7fffffff
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = contract.noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = contract.noise_octaves
	noise.fractal_lacunarity = contract.noise_lacunarity
	noise.fractal_gain = contract.noise_gain
	var ordered_pads := graph.pad_nodes()

	var sample_size := contract.cell_count + Vector2i.ONE
	var heights := PackedFloat32Array()
	heights.resize(sample_size.x * sample_size.y)
	for z_index in range(sample_size.y):
		var local_z := lerpf(
			contract.local_bounds.position.y,
			contract.local_bounds.end.y,
			float(z_index) / float(contract.cell_count.y)
		)
		for x_index in range(sample_size.x):
			var local_x := lerpf(
				contract.local_bounds.position.x,
				contract.local_bounds.end.x,
				float(x_index) / float(contract.cell_count.x)
			)
			heights[z_index * sample_size.x + x_index] = _height_at(
				Vector2(local_x, local_z), graph, ordered_pads, contract, noise
			)
	return heights


static func route_footprint_ratio(
		graph: GeneratedRouteGraph,
		contract: StageGenerationContract
) -> float:
	var edge_starts := PackedVector2Array()
	var edge_deltas := PackedVector2Array()
	var footprint_radii := PackedFloat32Array()
	for edge in graph.edges:
		var from := graph.node_by_id(edge.from_node_id).position
		var to := graph.node_by_id(edge.to_node_id).position
		var start := Vector2(from.x, from.z)
		edge_starts.append(start)
		edge_deltas.append(Vector2(to.x, to.z) - start)
		footprint_radii.append(edge.width * 0.5 + contract.target_shoulder_distance)
	var pad_positions := PackedVector2Array()
	var pad_radii := PackedFloat32Array()
	for pad in graph.pad_nodes():
		pad_positions.append(Vector2(pad.position.x, pad.position.z))
		pad_radii.append(pad.pad_radius + 4.0)
	var count := 0
	for pixel_y in range(contract.mask_size):
		var local_z := lerpf(
			contract.local_bounds.position.y,
			contract.local_bounds.end.y,
			(float(pixel_y) + 0.5) / float(contract.mask_size)
		)
		for pixel_x in range(contract.mask_size):
			var local_x := lerpf(
				contract.local_bounds.position.x,
				contract.local_bounds.end.x,
				(float(pixel_x) + 0.5) / float(contract.mask_size)
			)
			var point := Vector2(local_x, local_z)
			if _edge_distance(contract.local_bounds, point) < contract.outer_band_width:
				continue
			var included := false
			for edge_index in range(edge_starts.size()):
				var delta := edge_deltas[edge_index]
				var t := clampf(
					(point - edge_starts[edge_index]).dot(delta) \
							/ maxf(delta.length_squared(), 0.000001),
					0.0,
					1.0
				)
				var closest := edge_starts[edge_index] + delta * t
				if point.distance_squared_to(closest) <= footprint_radii[edge_index] * footprint_radii[edge_index]:
					included = true
					break
			if not included:
				for pad_index in range(pad_positions.size()):
					if point.distance_squared_to(pad_positions[pad_index]) <= \
							pad_radii[pad_index] * pad_radii[pad_index]:
						included = true
						break
			if included:
				count += 1
	return float(count) / float(contract.mask_size * contract.mask_size)


static func _height_at(
		point: Vector2,
		graph: GeneratedRouteGraph,
		pads: Array[GeneratedRouteNode],
		contract: StageGenerationContract,
		noise: FastNoiseLite
) -> float:
	# Wide route envelopes overlap several consecutive graph segments. Distance
	# follows the nearest segment, while height follows the route's monotonic-Z
	# cross-section. Decoupling them prevents distant parts of the same chain
	# from introducing a false wall without changing its geometric footprint.
	var nearest_edge_by_route: Dictionary = {}
	var nearest_sample_by_route: Dictionary = {}
	for route_index in range(graph.route_count()):
		var route_edges := graph.route_edges(route_index)
		var closest_edge: GeneratedRouteEdge
		var closest_sample: Dictionary = {}
		for candidate_edge in route_edges:
			var candidate_sample := _edge_sample(point, graph, candidate_edge)
			if closest_sample.is_empty() \
					or float(candidate_sample.distance) < float(closest_sample.distance) \
					or (is_equal_approx(float(candidate_sample.distance), float(closest_sample.distance)) \
							and candidate_edge.edge_index < closest_edge.edge_index):
				closest_edge = candidate_edge
				closest_sample = candidate_sample
		var height_edge := _edge_for_route_z(point.y, graph, route_edges)
		if closest_edge != null and height_edge != null:
			var height_sample := _cross_section_sample(point, graph, height_edge)
			closest_sample["height"] = height_sample.height
			nearest_edge_by_route[route_index] = closest_edge
			nearest_sample_by_route[route_index] = closest_sample

	var raw_mass := 0.0
	var has_mass := false
	var folded_floor := 0.0
	var has_floor := false
	var carve_weight := 0.0
	var nearest_distance := INF
	var nearest_core_radius := 0.0
	var cell_size := contract.local_bounds.size / Vector2(contract.cell_count)
	var target_triangle_guard := cell_size.length() + 0.01
	for route_index in range(graph.route_count()):
		var edge: GeneratedRouteEdge = nearest_edge_by_route.get(route_index)
		if edge == null:
			continue
		var sample: Dictionary = nearest_sample_by_route[route_index]
		var distance := float(sample.distance)
		var core_radius := edge.width * 0.5
		if distance >= core_radius + contract.support_distance:
			continue
		var route_height := float(sample.height)
		var bank := contract.bank_height * _smoothstep01(
			(distance - core_radius) / contract.bank_blend_distance
		)
		var falloff := 1.0 - _smoothstep01(
			(distance - (core_radius + contract.target_shoulder_distance)) \
					/ (contract.support_distance - contract.target_shoulder_distance)
		)
		var support := maxf(0.0, falloff * (route_height + bank))
		if support > 0.0:
			raw_mass = _smooth_max(raw_mass, support, contract.smooth_max_k) if has_mass else support
			has_mass = true
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_core_radius = core_radius
		if distance <= core_radius + contract.target_shoulder_distance + target_triangle_guard:
			folded_floor = _smooth_min(folded_floor, route_height, contract.smooth_min_k) \
					if has_floor else route_height
			has_floor = true
			carve_weight = 1.0
	var terraced := lerpf(
		raw_mass,
		roundf(raw_mass / contract.terrace_step) * contract.terrace_step,
		contract.terrace_blend
	)
	var height := lerpf(terraced, folded_floor, carve_weight) if has_floor else terraced
	for pad in pads:
		var distance_to_pad := point.distance_to(Vector2(pad.position.x, pad.position.z))
		var pad_weight := 1.0 - _smoothstep01(
			(distance_to_pad - 0.65 * pad.pad_radius) / (0.35 * pad.pad_radius)
		)
		height = lerpf(height, pad.position.y, pad_weight)

	if has_mass:
		var noise_weight := _smoothstep01(
			(nearest_distance - (nearest_core_radius + contract.target_shoulder_distance)) \
					/ (contract.support_distance - contract.target_shoulder_distance)
		) * clampf(raw_mass / contract.terrace_step, 0.0, 1.0)
		height += noise.get_noise_2d(point.x, point.y) * contract.noise_amplitude * noise_weight

	# Finish the non-target edge falloff one triangle diagonal before the target
	# band begins, so a target-classified triangle never straddles that cliff.
	var edge_falloff_width := maxf(
		contract.outer_band_width - target_triangle_guard,
		0.001
	)
	var edge_blend := _smoothstep01(
		_edge_distance(contract.local_bounds, point) / edge_falloff_width
	)
	return maxf(0.0, height * edge_blend)


static func _edge_sample(
		point: Vector2,
		graph: GeneratedRouteGraph,
		edge: GeneratedRouteEdge
) -> Dictionary:
	var from := graph.node_by_id(edge.from_node_id).position
	var to := graph.node_by_id(edge.to_node_id).position
	var from_xz := Vector2(from.x, from.z)
	var to_xz := Vector2(to.x, to.z)
	var delta := to_xz - from_xz
	var t := clampf((point - from_xz).dot(delta) / maxf(delta.length_squared(), 0.000001), 0.0, 1.0)
	return {
		"distance": point.distance_to(from_xz.lerp(to_xz, t)),
		"height": lerpf(from.y, to.y, t),
	}


static func _edge_for_route_z(
		local_z: float,
		graph: GeneratedRouteGraph,
		route_edges: Array[GeneratedRouteEdge]
) -> GeneratedRouteEdge:
	if route_edges.is_empty():
		return null
	for edge in route_edges:
		var finish := graph.node_by_id(edge.to_node_id).position
		if local_z <= finish.z:
			return edge
	return route_edges[-1]


static func _cross_section_sample(
		point: Vector2,
		graph: GeneratedRouteGraph,
		edge: GeneratedRouteEdge
) -> Dictionary:
	var from := graph.node_by_id(edge.from_node_id).position
	var to := graph.node_by_id(edge.to_node_id).position
	var t := clampf((point.y - from.z) / maxf(to.z - from.z, 0.000001), 0.0, 1.0)
	var center := Vector2(lerpf(from.x, to.x, t), lerpf(from.z, to.z, t))
	return {
		"distance": point.distance_to(center),
		"height": lerpf(from.y, to.y, t),
	}


static func _smoothstep01(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


static func _smooth_max(a: float, b: float, k: float) -> float:
	return maxf(a, b) + pow(maxf(k - absf(a - b), 0.0), 2.0) / (4.0 * k)


static func _smooth_min(a: float, b: float, k: float) -> float:
	return minf(a, b) - pow(maxf(k - absf(a - b), 0.0), 2.0) / (4.0 * k)


static func _edge_distance(bounds: Rect2, point: Vector2) -> float:
	return minf(
		minf(point.x - bounds.position.x, bounds.end.x - point.x),
		minf(point.y - bounds.position.y, bounds.end.y - point.y)
	)
