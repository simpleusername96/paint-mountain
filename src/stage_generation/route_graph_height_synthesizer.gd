class_name RouteGraphHeightSynthesizer
extends RefCounted

## Produces the sole one-height-per-XZ sample field from a resolved graph.

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
	var ordered_edges := graph.edges
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
				Vector2(local_x, local_z), graph, ordered_edges, ordered_pads, contract, noise
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
		edges: Array[GeneratedRouteEdge],
		pads: Array[GeneratedRouteNode],
		contract: StageGenerationContract,
		noise: FastNoiseLite
) -> float:
	var raw_mass := 0.0
	var has_mass := false
	var folded_floor := 0.0
	var has_floor := false
	var carve_weight := 0.0
	var nearest_distance := INF
	var nearest_core_radius := 0.0
	for edge in edges:
		var sample := _edge_sample(point, graph, edge)
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
		if distance < core_radius + contract.bank_blend_distance:
			folded_floor = _smooth_min(folded_floor, route_height, contract.smooth_min_k) \
					if has_floor else route_height
			has_floor = true
			carve_weight = maxf(
				carve_weight,
				1.0 - _smoothstep01((distance - core_radius) / contract.bank_blend_distance)
			)
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

	var edge_blend := _smoothstep01(
		_edge_distance(contract.local_bounds, point) / contract.outer_band_width
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
