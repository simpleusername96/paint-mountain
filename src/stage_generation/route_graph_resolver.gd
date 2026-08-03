class_name RouteGraphResolver
extends RefCounted

## Resolves typed route inputs into the immutable route geometry used by production.

const KEYED_STAGE_SAMPLER := preload("res://src/stage_generation/keyed_stage_sampler.gd")


static func resolve(
		stage_id: StringName,
		profile: StageGenerationProfile,
		attempt_seed: int
) -> GeneratedRouteGraph:
	if profile == null or not profile.is_valid() or String(stage_id).is_empty():
		return null
	var contract := profile.generation_contract
	var chains: Array[PackedVector3Array] = []
	var maximum_node_height := -INF
	for route_index in range(profile.routes.size()):
		var route_profile := profile.routes[route_index]
		var chain := PackedVector3Array()
		var height := profile.nominal_peak
		for station_index in range(contract.route_station_z.size()):
			if station_index > 0:
				var edge_index := station_index - 1
				var grade_sign := route_profile.grade_signs[edge_index]
				var draw_range := route_profile.drop_range if grade_sign < 0 else route_profile.rise_range
				var magnitude: float = KEYED_STAGE_SAMPLER.sample_range(
					stage_id,
					attempt_seed,
					"route/%d/edge/%d/grade" % [route_index, edge_index],
					draw_range
				)
				height += float(grade_sign) * magnitude
			var station_t := float(station_index) / float(contract.route_station_z.size() - 1)
			var lateral_offset := 0.0
			if station_index > 0 and station_index < contract.route_station_z.size() - 1:
				lateral_offset = KEYED_STAGE_SAMPLER.sample_range(
					stage_id,
					attempt_seed,
					"route/%d/node/%d/x" % [route_index, station_index],
					route_profile.lateral_bend_range
				)
			var x := _smoothstep01(station_t) * route_profile.endpoint_x + lateral_offset
			if not chain.is_empty() and absf(x - chain[-1].x) > contract.maximum_station_x_delta:
				return null
			chain.append(Vector3(x, height, contract.route_station_z[station_index]))
			maximum_node_height = maxf(maximum_node_height, height)
		chains.append(chain)

	var height_shift := profile.nominal_peak - maximum_node_height
	for route_index in range(chains.size()):
		var shifted := PackedVector3Array()
		for point in chains[route_index]:
			shifted.append(point + Vector3.UP * height_shift)
		chains[route_index] = shifted

	var nodes: Array[GeneratedRouteNode] = []
	var edges: Array[GeneratedRouteEdge] = []
	var summit_id := GeneratedRouteNode.summit_id(stage_id)
	nodes.append(GeneratedRouteNode.new(
		summit_id,
		chains[0][0],
		-1,
		0,
		GeneratedRouteNode.Kind.SUMMIT
	))
	for route_index in range(profile.routes.size()):
		var route_profile := profile.routes[route_index]
		var chain := chains[route_index]
		var pad_edge_index := -1
		var pad_edge_t := -1.0
		if route_profile.mechanism_kind >= 0:
			var split := _pad_split(chain, route_profile.mechanism_pad_t)
			pad_edge_index = int(split.edge_index)
			pad_edge_t = float(split.edge_t)
			if pad_edge_index < 0 or pad_edge_t <= 0.0 or pad_edge_t >= 1.0:
				return null
		var from_node_id := summit_id
		var resolved_edge_index := 0
		for original_edge_index in range(chain.size() - 1):
			var station_index := original_edge_index + 1
			var to_node_id := GeneratedRouteNode.route_node_id(stage_id, route_index, station_index)
			var to_kind := GeneratedRouteNode.Kind.EXIT \
					if station_index == chain.size() - 1 else GeneratedRouteNode.Kind.CORRIDOR
			if original_edge_index == pad_edge_index:
				var pad_id := GeneratedRouteNode.pad_id(
					stage_id, route_index, original_edge_index, route_profile.mechanism_kind
				)
				var pad_position := chain[original_edge_index].lerp(chain[station_index], pad_edge_t)
				nodes.append(GeneratedRouteNode.new(
					pad_id,
					pad_position,
					route_index,
					station_index,
					GeneratedRouteNode.Kind.PAD,
					route_profile.mechanism_kind,
					route_profile.mechanism_pad_radius
				))
				edges.append(GeneratedRouteEdge.new(
					GeneratedRouteEdge.stable_id(stage_id, route_index, original_edge_index, &"a"),
					from_node_id,
					pad_id,
					route_index,
					resolved_edge_index,
					route_profile.role,
					route_profile.width
				))
				resolved_edge_index += 1
				edges.append(GeneratedRouteEdge.new(
					GeneratedRouteEdge.stable_id(stage_id, route_index, original_edge_index, &"b"),
					pad_id,
					to_node_id,
					route_index,
					resolved_edge_index,
					route_profile.role,
					route_profile.width
				))
				resolved_edge_index += 1
			else:
				edges.append(GeneratedRouteEdge.new(
					GeneratedRouteEdge.stable_id(stage_id, route_index, original_edge_index),
					from_node_id,
					to_node_id,
					route_index,
					resolved_edge_index,
					route_profile.role,
					route_profile.width
				))
				resolved_edge_index += 1
			nodes.append(GeneratedRouteNode.new(
				to_node_id,
				chain[station_index],
				route_index,
				station_index,
				to_kind
			))
			from_node_id = to_node_id

	var graph := GeneratedRouteGraph.new(nodes, edges)
	if not graph.is_valid() or not _pads_do_not_overlap(graph):
		return null
	return graph


static func _pad_split(chain: PackedVector3Array, normalized_arc_position: float) -> Dictionary:
	var edge_lengths := PackedFloat32Array()
	var total_length := 0.0
	for edge_index in range(chain.size() - 1):
		var length := Vector2(chain[edge_index].x, chain[edge_index].z).distance_to(
			Vector2(chain[edge_index + 1].x, chain[edge_index + 1].z)
		)
		edge_lengths.append(length)
		total_length += length
	var requested_length := clampf(normalized_arc_position, 0.0, 1.0) * total_length
	var traversed := 0.0
	for edge_index in range(edge_lengths.size()):
		var cumulative_end := traversed + edge_lengths[edge_index]
		if cumulative_end >= requested_length:
			return {
				"edge_index": edge_index,
				"edge_t": (requested_length - traversed) / maxf(edge_lengths[edge_index], 0.000001),
			}
		traversed = cumulative_end
	return {"edge_index": -1, "edge_t": -1.0}


static func _pads_do_not_overlap(graph: GeneratedRouteGraph) -> bool:
	var pads := graph.pad_nodes()
	for first_index in range(pads.size()):
		for second_index in range(first_index + 1, pads.size()):
			var first := pads[first_index]
			var second := pads[second_index]
			var distance := Vector2(first.position.x, first.position.z).distance_to(
				Vector2(second.position.x, second.position.z)
			)
			if distance < first.pad_radius + second.pad_radius:
				return false
	return true


static func _smoothstep01(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)
