extends SceneTree

const CATALOG_BUILDER := preload("res://scripts/build_stage_catalog.gd")
const ROUTE_GRAPH_RESOLVER := preload("res://src/stage_generation/route_graph_resolver.gd")

var _failed := false


func _initialize() -> void:
	var stage1_routes: Array[StageRouteProfile] = CATALOG_BUILDER._intro_routes(
		1, StageProgressionData.route_width_for(1)
	)
	var stage2_routes: Array[StageRouteProfile] = CATALOG_BUILDER._intro_routes(
		2, StageProgressionData.route_width_for(2)
	)
	var stage3_routes: Array[StageRouteProfile] = CATALOG_BUILDER._intro_routes(
		3, StageProgressionData.route_width_for(3)
	)
	_assert(stage1_routes.size() == 1, "Stage 01 must keep one simple route")
	_assert(stage2_routes.size() == 1, "Stage 02 must keep one simple route")
	_assert(stage3_routes.size() == 3, "Stage 03 must teach Splitter with three routes")
	_assert(
		StageProgressionData.route_count_for(1) == 1
				and StageProgressionData.route_count_for(2) == 1
				and StageProgressionData.route_count_for(3) == 3
				and StageProgressionData.route_count_for(4) == 1,
		"the progression contract must expose only Stage 03 as the early three-route tutorial"
	)

	var stage := StageCatalog.get_stage(&"stage_03").duplicate(true) as StageData
	stage.mechanism_loadout = CATALOG_BUILDER._materialize_mechanisms(
		stage.mechanism_loadout, 3
	)
	var profile := stage.generation_profile.duplicate(true) as StageGenerationProfile
	profile.base_seed = StageProgressionData.requested_seed_for(3)
	profile.fallback_seed = StageProgressionData.candidate_seed_for(3, 31)
	profile.accepted_height_range.x = profile.nominal_peak - 12.0
	profile.route_width = StageProgressionData.route_width_for(3)
	profile.routes = stage3_routes
	_assert(profile.is_valid(), "the Stage 03 tutorial routes must form a valid generation profile")
	var graph := ROUTE_GRAPH_RESOLVER.resolve(stage.stage_id, profile, profile.base_seed)
	_assert(graph != null and graph.is_valid(), "the Stage 03 tutorial routes must resolve to a valid graph")
	if graph != null:
		_assert(graph.route_count() == 3, "the resolved Stage 03 graph must retain all three routes")
		_assert(
			graph.route_index_for_role(StageRouteProfile.Role.SAFE) >= 0
					and graph.route_index_for_role(StageRouteProfile.Role.SPLITTER) >= 0
					and graph.route_index_for_role(StageRouteProfile.Role.BUMPER) >= 0,
			"Stage 03 must expose distinct SAFE, SPLITTER, and uphill-rebound route roles"
		)
		var splitter_pad := graph.pad_node_for_kind(MechanismData.Kind.SPLITTER)
		var uphill_pad := graph.pad_node_for_kind(MechanismData.Kind.UPHILL_REBOUND)
		_assert(
			splitter_pad != null
					and graph.route_role(splitter_pad.route_index) == StageRouteProfile.Role.SPLITTER,
			"the Splitter glyph anchor must live on the SPLITTER route"
		)
		_assert(
			uphill_pad != null
					and graph.route_role(uphill_pad.route_index) == StageRouteProfile.Role.BUMPER,
			"the Uphill Rebound glyph anchor must live on its dedicated route"
		)

	stage.generation_profile = profile
	stage.terrain_seed = profile.base_seed
	var layout := SeededStageGenerator.generate(profile, stage.terrain_seed, stage)
	_assert(
		layout != null and layout.is_valid(),
		"the persisted Stage 03 candidate must admit the three-route glyph contract"
	)
	if layout != null:
		_assert(
			layout.accepted_seed == StageProgressionData.requested_seed_for(3),
			"Stage 03 must use its newly persisted accepted seed without runtime search"
		)
		_assert(
			layout.mechanism_placements.size() == stage.mechanism_loadout.size(),
			"Stage 03 must place its complete glyph loadout"
		)
		for placement in layout.mechanism_placements:
			if placement.mechanism_data.canonical_kind() == MechanismData.Kind.SPLITTER:
				_assert(
					placement.splitter_route_targets.size() == 3,
					"Stage 03 Splitter must retain three route witnesses"
				)

	if not _failed:
		print("Stage 03 glyph route contract passed")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
