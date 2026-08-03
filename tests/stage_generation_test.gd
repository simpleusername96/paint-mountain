extends SceneTree

const FIRST_DESCENT: StageData = preload("res://resources/stages/first_descent.tres")
const DEFERRED_STAGES: Array[StageData] = [
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]
var _expected_stage1_roles := PackedInt32Array([StageRouteProfile.Role.PRIMARY])
var _expected_stage1_reversals := PackedInt32Array([0])

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	_assert_true(KeyedStageSampler.fnv1a32("hello") == 1335831723, "keyed generation must use canonical UTF-8 FNV-1a 32-bit hashing")
	_assert_deferred_profiles_resolve()
	var selected_stage := int(_argument_value("stage", "1"))
	var seed_mode := _argument_value("seed", "both")
	_assert_true(selected_stage == 0 or selected_stage == 1, "Task 1.1 focused acceptance supports First Descent only")
	if selected_stage == 0 or selected_stage == 1:
		var stage := FIRST_DESCENT
		var profile := stage.generation_profile
		_assert_true(stage.stage_version == 4, "%s StageData version must be 4" % stage.stage_id)
		_assert_true(profile != null and profile.is_valid(), "%s generation profile must be valid" % stage.stage_id)
		_assert_true(profile.profile_version == 4, "%s profile version must be 4" % stage.stage_id)
		_assert_true(profile.generation_contract != null and profile.generation_contract.is_valid(), "%s must consume the pinned generation contract" % stage.stage_id)
		_assert_true(profile.generation_contract.cell_count == Vector2i(72, 48), "%s grid must be 72 x 48 cells" % stage.stage_id)
		_assert_true(_profile_has_no_legacy_shape_fields(stage), "%s production profile must not contain lobe, shelf, or control-point fields" % stage.stage_id)
		if seed_mode == "both" or seed_mode == "base":
			_run_seed_case(stage, profile.base_seed, "base")
		if seed_mode == "both" or seed_mode == "fallback":
			var fallback_request := _run_seed_case(stage, profile.fallback_seed, "fallback-request")
			if fallback_request != null:
				_run_pinned_fallback_case(stage, fallback_request)
	quit(1 if _failed else 0)


func _argument_value(key: String, fallback: String) -> String:
	var prefix := "--%s=" % key
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback


func _run_seed_case(
		stage: StageData,
		requested_seed: int,
		label: String
) -> GeneratedStageLayout:
	var started := Time.get_ticks_msec()
	var first := SeededStageGenerator.generate(stage.generation_profile, requested_seed, stage)
	var repeated := SeededStageGenerator.generate(stage.generation_profile, requested_seed, stage)
	var elapsed_ms := Time.get_ticks_msec() - started
	_assert_true(first != null, "%s %s seed must generate" % [stage.stage_id, label])
	_assert_true(repeated != null, "%s repeated %s seed must generate" % [stage.stage_id, label])
	if first == null or repeated == null:
		return null

	_assert_layout_contract(stage, requested_seed, first)
	_assert_true(first.terrain_seed == requested_seed, "%s must record requested seed" % stage.stage_id)
	_assert_true(first.accepted_seed == repeated.accepted_seed, "%s accepted seed must repeat" % stage.stage_id)
	_assert_true(first.generation_attempt == repeated.generation_attempt, "%s accepted attempt must repeat" % stage.stage_id)
	_assert_true(first.checksum == repeated.checksum, "%s height checksum must repeat" % stage.stage_id)
	_assert_true(first.eligible_mask_checksum == repeated.eligible_mask_checksum, "%s eligible-mask checksum must repeat" % stage.stage_id)
	_assert_graphs_repeat(stage, first.route_graph, repeated.route_graph)
	_assert_placements_repeat(stage, first, repeated)
	_assert_decorations_repeat(stage, first, repeated)
	print("%s %s: requested=%d accepted=%d attempt=%d checksums=%d/%d footprint=%.6f legacy_eligible=%.6f elapsed_ms=%d" % [
		stage.stage_id, label, requested_seed, first.accepted_seed, first.generation_attempt,
		first.checksum, first.eligible_mask_checksum,
		float(first.metrics.get("route_footprint_ratio", -1.0)),
		float(first.metrics.get("eligible_ratio_after_exclusions", -1.0)), elapsed_ms,
	])
	return first


func _run_pinned_fallback_case(
		stage: StageData,
		fallback_request: GeneratedStageLayout
) -> void:
	var source_profile := stage.generation_profile
	_assert_true(
		fallback_request.generation_attempt == 0 \
				and fallback_request.accepted_seed == source_profile.fallback_seed,
		"%s fallback seed requested directly must remain deterministic attempt zero" % stage.stage_id
	)
	var fallback_only_profile := source_profile.duplicate(true) as StageGenerationProfile
	_assert_true(fallback_only_profile != null, "%s fallback test profile must duplicate" % stage.stage_id)
	if fallback_only_profile == null:
		return

	# Footprint ratio is a mask-pixel count divided by 512^2, so this exact gate is
	# stable and admits the pinned fallback geometry while rejecting this request's
	# complete derived-attempt sequence.
	var fallback_ratio := float(fallback_request.metrics.get("route_footprint_ratio", -1.0))
	fallback_only_profile.target_ratio_range = Vector2(fallback_ratio, fallback_ratio)
	_assert_true(fallback_only_profile.is_valid(), "%s fallback test profile must remain valid" % stage.stage_id)
	var contract := fallback_only_profile.generation_contract
	_assert_true(
		contract.attempt_count == StageGenerationContract.REQUIRED_ATTEMPT_COUNT,
		"%s fallback test must retain all 32 configured attempts" % stage.stage_id
	)
	for attempt_index in range(contract.attempt_count):
		var derived_seed := int((source_profile.base_seed + attempt_index * contract.attempt_seed_stride) & 0x7fffffff)
		_assert_true(
			derived_seed != fallback_only_profile.fallback_seed,
			"%s fallback seed must not occur inside the derived-attempt sequence" % stage.stage_id
		)

	var started := Time.get_ticks_msec()
	var pinned := SeededStageGenerator.generate(
		fallback_only_profile,
		source_profile.base_seed,
		stage
	)
	var elapsed_ms := Time.get_ticks_msec() - started
	_assert_true(pinned != null, "%s pinned fallback must generate after all derived attempts reject" % stage.stage_id)
	if pinned == null:
		return
	_assert_true(pinned.terrain_seed == source_profile.base_seed, "%s pinned fallback must retain the original request seed" % stage.stage_id)
	_assert_true(pinned.accepted_seed == source_profile.fallback_seed, "%s pinned fallback must record the configured fallback seed" % stage.stage_id)
	_assert_true(pinned.generation_attempt == -1, "%s pinned fallback must record attempt -1" % stage.stage_id)
	_assert_true(pinned.checksum == fallback_request.checksum, "%s pinned fallback geometry must match the direct fallback-seed request" % stage.stage_id)
	_assert_true(pinned.eligible_mask_checksum == fallback_request.eligible_mask_checksum, "%s pinned fallback mask must match the direct fallback-seed request" % stage.stage_id)
	print("%s pinned-fallback: requested=%d accepted=%d attempt=%d footprint=%.6f elapsed_ms=%d" % [
		stage.stage_id,
		pinned.terrain_seed,
		pinned.accepted_seed,
		pinned.generation_attempt,
		float(pinned.metrics.get("route_footprint_ratio", -1.0)),
		elapsed_ms,
	])


func _assert_layout_contract(stage: StageData, requested_seed: int, layout: GeneratedStageLayout) -> void:
	var profile := stage.generation_profile
	_assert_true(layout.is_valid(), "%s layout must satisfy its typed shape contract" % stage.stage_id)
	_assert_true(layout.profile_version == 4 and layout.layout_version == 4, "%s layout must record version 4" % stage.stage_id)
	_assert_true(layout.cell_count == Vector2i(72, 48), "%s layout grid must be 72 x 48" % stage.stage_id)
	_assert_true(layout.heights.size() == 73 * 49, "%s layout must contain 73 x 49 samples" % stage.stage_id)
	_assert_true(layout.route_graph != null and layout.route_graph.is_valid(), "%s must own one valid immutable route graph" % stage.stage_id)
	_assert_true(_graph_roles(layout.route_graph) == _expected_stage1_roles, "%s route roles must match the frozen profile" % stage.stage_id)
	_assert_true(_graph_reversals(layout.route_graph) == _expected_stage1_reversals, "%s route reversals must match the frozen progression" % stage.stage_id)
	_assert_true(int(layout.metrics.get("top_triangles", 0)) == 6912, "%s top mesh must contain 6,912 triangles" % stage.stage_id)
	_assert_true(float(layout.metrics.get("p95_route_slope", INF)) <= profile.route_core_p95_slope_max, "%s p95 route slope must pass its frozen v4 gate" % stage.stage_id)
	var maximum_height := float(layout.metrics.get("maximum_height", -INF))
	_assert_true(maximum_height >= profile.accepted_height_range.x and maximum_height <= profile.accepted_height_range.y, "%s maximum height must stay in profile range" % stage.stage_id)
	var footprint_ratio := float(layout.metrics.get("route_footprint_ratio", -1.0))
	_assert_true(footprint_ratio >= profile.target_ratio_range.x and footprint_ratio <= profile.target_ratio_range.y, "%s route footprint ratio must stay in the frozen target band" % stage.stage_id)
	_assert_true(layout.eligible_mask.size() == 512 * 512, "%s eligible mask must be 512 x 512" % stage.stage_id)
	_assert_true(layout.eligible_mask_checksum != 0, "%s eligible mask checksum must be populated" % stage.stage_id)
	_assert_true(_accepted_seed_belongs_to_sequence(profile, requested_seed, layout), "%s accepted seed must belong to the 32 attempts or pinned fallback" % stage.stage_id)
	_assert_graph_contract(stage, profile, layout.route_graph, layout.accepted_seed)
	_assert_edges_are_zero(stage, layout)
	_assert_true(absf(layout.height_at_local(70.0, 0.0)) <= 0.01, "%s bounded route support must return to zero away from its only route" % stage.stage_id)


func _accepted_seed_belongs_to_sequence(profile: StageGenerationProfile, requested_seed: int, layout: GeneratedStageLayout) -> bool:
	if layout.generation_attempt == -1:
		return layout.accepted_seed == profile.fallback_seed
	var contract := profile.generation_contract
	if layout.generation_attempt < 0 or layout.generation_attempt >= contract.attempt_count:
		return false
	return layout.accepted_seed == int((requested_seed + layout.generation_attempt * contract.attempt_seed_stride) & 0x7fffffff)


func _assert_edges_are_zero(stage: StageData, layout: GeneratedStageLayout) -> void:
	var size := layout.sample_size()
	for x in range(size.x):
		_assert_true(layout.heights[x] <= 0.01, "%s north edge must reach the shell base" % stage.stage_id)
		_assert_true(layout.heights[(size.y - 1) * size.x + x] <= 0.01, "%s south edge must reach the shell base" % stage.stage_id)
	for z in range(size.y):
		_assert_true(layout.heights[z * size.x] <= 0.01, "%s west edge must reach the shell base" % stage.stage_id)
		_assert_true(layout.heights[z * size.x + size.x - 1] <= 0.01, "%s east edge must reach the shell base" % stage.stage_id)


func _assert_placements_repeat(stage: StageData, first: GeneratedStageLayout, repeated: GeneratedStageLayout) -> void:
	_assert_true(first.mechanism_placements.size() == stage.mechanism_loadout.size(), "%s mechanism loadout must be fully placed" % stage.stage_id)
	_assert_true(repeated.mechanism_placements.size() == first.mechanism_placements.size(), "%s placement count must repeat" % stage.stage_id)
	for index in range(first.mechanism_placements.size()):
		var a := first.mechanism_placements[index]
		var b := repeated.mechanism_placements[index]
		_assert_true(a.route_index == b.route_index and a.route_role == b.route_role, "%s placement ownership must repeat" % stage.stage_id)
		_assert_true(a.local_transform.is_equal_approx(b.local_transform), "%s placement transform must repeat" % stage.stage_id)
		_assert_true(a.downstream_tangent.is_equal_approx(b.downstream_tangent), "%s placement tangent must repeat" % stage.stage_id)


func _assert_decorations_repeat(stage: StageData, first: GeneratedStageLayout, repeated: GeneratedStageLayout) -> void:
	var expected_count: int = [10, 14, 18][stage.stage_number - 1]
	_assert_true(first.decoration_placements.size() == expected_count, "%s decoration count must match" % stage.stage_id)
	_assert_true(repeated.decoration_placements.size() == expected_count, "%s repeated decoration count must match" % stage.stage_id)
	for index in range(mini(first.decoration_placements.size(), repeated.decoration_placements.size())):
		var a := first.decoration_placements[index]
		var b := repeated.decoration_placements[index]
		_assert_true(a.model_id == b.model_id and a.local_xz.is_equal_approx(b.local_xz), "%s decoration placement must repeat" % stage.stage_id)
		_assert_true(is_equal_approx(a.yaw_degrees, b.yaw_degrees) and is_equal_approx(a.uniform_scale, b.uniform_scale), "%s decoration transform must repeat" % stage.stage_id)


func _profile_has_no_legacy_shape_fields(stage: StageData) -> bool:
	var path := stage.generation_profile.resource_path
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	for forbidden in ["control_points", "lobe_", "mechanism_shelf", "route_spines", "station_x_jitter"]:
		if text.contains(forbidden):
			return false
	return true


func _assert_deferred_profiles_resolve() -> void:
	for stage in DEFERRED_STAGES:
		var profile := stage.generation_profile
		_assert_true(stage.stage_version == 4 and profile != null and profile.is_valid(), "%s deferred Phase 2 resources must remain schema-valid v4" % stage.stage_id)
		var graph := RouteGraphResolver.resolve(stage.stage_id, profile, profile.base_seed)
		_assert_true(graph != null and graph.is_valid(), "%s frozen graph input must resolve without claiming Phase 2 acceptance" % stage.stage_id)


func _graph_roles(graph: GeneratedRouteGraph) -> PackedInt32Array:
	var roles := PackedInt32Array()
	for route_index in range(graph.route_count()):
		roles.append(graph.route_role(route_index))
	return roles


func _graph_reversals(graph: GeneratedRouteGraph) -> PackedInt32Array:
	var reversals := PackedInt32Array()
	for route_index in range(graph.route_count()):
		reversals.append(graph.route_reversal_count(route_index))
	return reversals


func _assert_graph_contract(
		stage: StageData,
		profile: StageGenerationProfile,
		graph: GeneratedRouteGraph,
		attempt_seed: int
) -> void:
	var maximum_node_height := -INF
	for node in graph.nodes:
		maximum_node_height = maxf(maximum_node_height, node.position.y)
	_assert_true(is_equal_approx(maximum_node_height, profile.nominal_peak), "%s graph maximum must equal nominal peak" % stage.stage_id)
	_assert_true(graph.route_count() == profile.routes.size(), "%s graph route count must match typed inputs" % stage.stage_id)
	for route_index in range(graph.route_count()):
		var route_nodes := graph.route_nodes(route_index)
		_assert_true(route_nodes[0].kind == GeneratedRouteNode.Kind.SUMMIT, "%s every route must begin at the shared summit" % stage.stage_id)
		_assert_true(route_nodes[-1].kind == GeneratedRouteNode.Kind.EXIT, "%s every route must end at a typed exit" % stage.stage_id)
		_assert_true(is_equal_approx(route_nodes[0].position.z, -44.0) and is_equal_approx(route_nodes[-1].position.z, 44.0), "%s route station endpoints must be frozen" % stage.stage_id)
		_assert_true(is_equal_approx(route_nodes[-1].position.x, profile.routes[route_index].endpoint_x), "%s route endpoint X must match the profile" % stage.stage_id)
		_assert_true(route_nodes.size() == profile.generation_contract.route_station_z.size(), "%s unpadded Stage 1 route must contain every fixed station exactly once" % stage.stage_id)
		for station_index in range(route_nodes.size()):
			var node := route_nodes[station_index]
			var station_t := float(station_index) / float(route_nodes.size() - 1)
			var expected_x := _smoothstep01(station_t) * profile.routes[route_index].endpoint_x
			if station_index > 0 and station_index < route_nodes.size() - 1:
				expected_x += KeyedStageSampler.sample_range(
					stage.stage_id,
					attempt_seed,
					"route/%d/node/%d/x" % [route_index, station_index],
					profile.routes[route_index].lateral_bend_range
				)
			_assert_true(is_equal_approx(node.position.z, profile.generation_contract.route_station_z[station_index]), "%s station Z must match the fixed contract" % stage.stage_id)
			_assert_true(is_equal_approx(node.position.x, expected_x), "%s station X must use its keyed field sample" % stage.stage_id)
		var route_edges := graph.route_edges(route_index)
		for edge_index in range(route_edges.size()):
			var edge := route_edges[edge_index]
			var from := graph.node_by_id(edge.from_node_id).position
			var to := graph.node_by_id(edge.to_node_id).position
			_assert_true(absf(to.x - from.x) <= profile.generation_contract.maximum_station_x_delta + 0.001, "%s consecutive route X change must be <= 18 m" % stage.stage_id)
			var expected_drop := KeyedStageSampler.sample_range(
				stage.stage_id,
				attempt_seed,
				"route/%d/edge/%d/grade" % [route_index, edge_index],
				profile.routes[route_index].drop_range
			)
			_assert_true(is_equal_approx(from.y - to.y, expected_drop), "%s Stage 1 edge height must use its keyed drop sample" % stage.stage_id)
			_assert_true(edge.id == GeneratedRouteEdge.stable_id(stage.stage_id, route_index, edge_index), "%s unsplit edge IDs must remain stable and ordered" % stage.stage_id)
	var expected_pad_count := stage.mechanism_loadout.size()
	_assert_true(graph.pad_nodes().size() == expected_pad_count, "%s pad count must equal mechanism loadout" % stage.stage_id)


func _smoothstep01(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _assert_graphs_repeat(
		stage: StageData,
		first: GeneratedRouteGraph,
		repeated: GeneratedRouteGraph
) -> void:
	_assert_true(first.nodes.size() == repeated.nodes.size() and first.edges.size() == repeated.edges.size(), "%s graph shape must repeat" % stage.stage_id)
	for index in range(mini(first.nodes.size(), repeated.nodes.size())):
		var a := first.nodes[index]
		var b := repeated.nodes[index]
		_assert_true(a.id == b.id and a.position.is_equal_approx(b.position), "%s graph node identity and position must repeat" % stage.stage_id)
	for index in range(mini(first.edges.size(), repeated.edges.size())):
		var a := first.edges[index]
		var b := repeated.edges[index]
		_assert_true(a.id == b.id and a.from_node_id == b.from_node_id and a.to_node_id == b.to_node_id, "%s graph edge identity must repeat" % stage.stage_id)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage generation check failed: %s" % message)
