class_name RouteGraphMountainSynthesizer
extends RefCounted

## Builds the sampled surface and the connected cell footprint that determines
## which triangles physically exist. The footprint, not camera framing, gives
## the mountain its irregular silhouette and exposed support faces. Noise may
## move the outer contour, but it must never carve cavities through the mass.

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
	var solid_cells := _solidify_row_spans(cells, contract.cell_count)
	assert(
		_has_solid_mass_contract(solid_cells, contract.cell_count),
		"Mountain footprint must be one row-solid mass joined to the rear wall."
	)
	return solid_cells


## Converts route-support islands into one solid mountain body. Each depth row
## keeps its generated irregular left/right contour, while every cell between
## those contours is filled. Empty rows between occupied rows are interpolated
## so branching routes cannot create a tunnel or a disconnected slice.
static func _solidify_row_spans(
		seed_cells: PackedByteArray,
		cell_count: Vector2i
) -> PackedByteArray:
	var left_edges := PackedInt32Array()
	var right_edges := PackedInt32Array()
	left_edges.resize(cell_count.y)
	right_edges.resize(cell_count.y)
	left_edges.fill(-1)
	right_edges.fill(-1)
	for cell_z in range(cell_count.y):
		for cell_x in range(cell_count.x):
			if seed_cells[cell_z * cell_count.x + cell_x] == 0:
				continue
			if left_edges[cell_z] < 0:
				left_edges[cell_z] = cell_x
			right_edges[cell_z] = cell_x

	var original_left := left_edges.duplicate()
	var original_right := right_edges.duplicate()
	var first_row := -1
	var last_row := -1
	for cell_z in range(cell_count.y):
		if original_left[cell_z] < 0:
			continue
		if first_row < 0:
			first_row = cell_z
		last_row = cell_z
	if first_row < 0:
		return seed_cells.duplicate()

	for cell_z in range(first_row, last_row + 1):
		if original_left[cell_z] >= 0:
			continue
		var previous_row := cell_z - 1
		while previous_row >= first_row and original_left[previous_row] < 0:
			previous_row -= 1
		var next_row := cell_z + 1
		while next_row <= last_row and original_left[next_row] < 0:
			next_row += 1
		var row_t := float(cell_z - previous_row) / float(next_row - previous_row)
		left_edges[cell_z] = roundi(lerpf(
			float(original_left[previous_row]), float(original_left[next_row]), row_t
		))
		right_edges[cell_z] = roundi(lerpf(
			float(original_right[previous_row]), float(original_right[next_row]), row_t
		))

	# Adjacent occupied rows overlap by at least one cell. This makes the row
	# spans a single 4-connected body even under an extreme seeded bend.
	for cell_z in range(first_row + 1, last_row + 1):
		if left_edges[cell_z] > right_edges[cell_z - 1]:
			left_edges[cell_z] = right_edges[cell_z - 1]
		if right_edges[cell_z] < left_edges[cell_z - 1]:
			right_edges[cell_z] = left_edges[cell_z - 1]

	var solid_cells := PackedByteArray()
	solid_cells.resize(seed_cells.size())
	for cell_z in range(first_row, last_row + 1):
		for cell_x in range(left_edges[cell_z], right_edges[cell_z] + 1):
			solid_cells[cell_z * cell_count.x + cell_x] = 1
	return solid_cells


static func _has_solid_mass_contract(
		cells: PackedByteArray,
		cell_count: Vector2i
) -> bool:
	if cells.size() != cell_count.x * cell_count.y:
		return false
	var saw_occupied_row := false
	var saw_gap_after_mass := false
	var previous_left := -1
	var previous_right := -1
	for cell_z in range(cell_count.y):
		var left := -1
		var right := -1
		var inside_span := false
		var span_ended := false
		for cell_x in range(cell_count.x):
			var active := cells[cell_z * cell_count.x + cell_x] != 0
			if active:
				if span_ended:
					return false
				if left < 0:
					left = cell_x
				right = cell_x
				inside_span = true
			elif inside_span:
				span_ended = true
		if left < 0:
			if saw_occupied_row:
				saw_gap_after_mass = true
			continue
		if saw_gap_after_mass:
			return false
		if not saw_occupied_row and cell_z != 0:
			return false
		if previous_left >= 0 and (left > previous_right or right < previous_left):
			return false
		saw_occupied_row = true
		previous_left = left
		previous_right = right
	return saw_occupied_row
