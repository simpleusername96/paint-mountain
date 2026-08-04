class_name RouteGraphMountainSynthesizer
extends RefCounted

## Builds the sampled surface and the connected cell footprint that determines
## which triangles physically exist. The footprint, not camera framing, gives
## the mountain its irregular silhouette and exposed support faces.

const HEIGHT_FIELD_BUILDER := preload(
	"res://src/stage_generation/route_graph_height_synthesizer.gd"
)
const KEYED_STAGE_SAMPLER := preload(
	"res://src/stage_generation/keyed_stage_sampler.gd"
)


static func build(
		stage_id: StringName,
		profile: StageGenerationProfile,
		graph: GeneratedRouteGraph,
		attempt_seed: int
) -> Dictionary:
	var heights: PackedFloat32Array = HEIGHT_FIELD_BUILDER.build(
		stage_id, profile, graph, attempt_seed
	)
	var footprint := _build_footprint(stage_id, profile, graph, attempt_seed)
	return {
		"heights": heights,
		"footprint": footprint,
	}


static func route_footprint_ratio(
		graph: GeneratedRouteGraph,
		contract: StageGenerationContract
) -> float:
	return HEIGHT_FIELD_BUILDER.route_footprint_ratio(graph, contract)


static func _build_footprint(
		stage_id: StringName,
		profile: StageGenerationProfile,
		graph: GeneratedRouteGraph,
		attempt_seed: int
) -> PackedByteArray:
	var contract := profile.generation_contract
	var cells := PackedByteArray()
	cells.resize(contract.cell_count.x * contract.cell_count.y)
	var contour_noise := FastNoiseLite.new()
	contour_noise.seed = KEYED_STAGE_SAMPLER.fnv1a32(
		"paint_mountain:%s:v4:%d:footprint" % [String(stage_id), attempt_seed]
	) & 0x7fffffff
	contour_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	contour_noise.frequency = 0.055

	var cell_size := contract.local_bounds.size / Vector2(contract.cell_count)
	for cell_z in range(contract.cell_count.y):
		for cell_x in range(contract.cell_count.x):
			var center := contract.local_bounds.position + Vector2(
				(float(cell_x) + 0.5) * cell_size.x,
				(float(cell_z) + 0.5) * cell_size.y
			)
			var nearest := graph.nearest_edge(center)
			var edge := nearest.get("edge") as GeneratedRouteEdge
			var included := false
			if edge != null:
				var base_radius := edge.width * 0.5 + contract.support_distance * 0.82
				var irregularity := contour_noise.get_noise_2d(center.x, center.y) * 4.5
				included = float(nearest.get("distance", INF)) <= base_radius + irregularity
			if not included:
				for pad in graph.pad_nodes():
					var pad_radius := pad.pad_radius + contract.support_distance * 0.72
					if center.distance_to(Vector2(pad.position.x, pad.position.z)) <= pad_radius:
						included = true
						break
			if included:
				cells[cell_z * contract.cell_count.x + cell_x] = 1
	return cells
