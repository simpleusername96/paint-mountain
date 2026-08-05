extends SceneTree

const CATALOG_BUILDER := preload("res://scripts/build_stage_catalog.gd")
const ROUTE_GRAPH_RESOLVER := preload("res://src/stage_generation/route_graph_resolver.gd")

var _failed := false


func _initialize() -> void:
	var source_catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	_assert(source_catalog != null, "the reviewed source catalog must load")
	if source_catalog == null:
		quit(1)
		return
	var source_stages := source_catalog.ordered_stages()
	_assert(
		source_stages.size() == StageProgressionData.STAGE_COUNT,
		"the materializer needs all thirty reviewed source stages"
	)
	if source_stages.size() != StageProgressionData.STAGE_COUNT:
		quit(1)
		return

	for stage_number in range(1, StageProgressionData.STAGE_COUNT + 1):
		var stage := CATALOG_BUILDER._materialize_stage(
			source_stages[stage_number - 1], stage_number
		)
		_assert(stage != null, "Stage %02d must materialize" % stage_number)
		if stage == null:
			continue
		_assert(
			stage.stage_version == StageGenerationContract.CONTRACT_VERSION,
			"Stage %02d must use the active generation version" % stage_number
		)
		_assert(
			stage.generation_profile.profile_id
					== StageGenerationProfile.profile_id_for_stage(stage.stage_id),
			"Stage %02d must use the versioned profile ID" % stage_number
		)
		_assert(
			stage.mechanism_loadout.size()
					== StageProgressionData.mechanism_count_for(stage_number),
			"Stage %02d must preserve the progression glyph count" % stage_number
		)
		_assert(
			stage.generation_profile.routes.size()
					== StageProgressionData.route_count_for(stage_number),
			"Stage %02d must preserve its route topology" % stage_number
		)
		_assert_slot_contract(stage)
		_assert_loadout_policy(stage)
		var graph := ROUTE_GRAPH_RESOLVER.resolve(
			stage.stage_id, stage.generation_profile, stage.terrain_seed
		)
		_assert(
			graph != null and graph.is_valid(),
			"Stage %02d must retain a valid route graph" % stage_number
		)

	if not _failed:
		print("generation_v8_materialization_test passed")
	quit(1 if _failed else 0)


func _assert_slot_contract(stage: StageData) -> void:
	var slot_kinds := PackedInt32Array()
	for route in stage.generation_profile.routes:
		for slot in route.mechanism_slots():
			slot_kinds.append(int(slot.kind))
	_assert(
		slot_kinds.size() == stage.mechanism_loadout.size(),
		"%s must retain one route anchor per glyph" % stage.stage_id
	)
	for index in range(mini(slot_kinds.size(), stage.mechanism_loadout.size())):
		_assert(
			slot_kinds[index] == int(stage.mechanism_loadout[index].canonical_kind()),
			"%s route anchor %d must match its glyph kind" % [stage.stage_id, index]
		)


func _assert_loadout_policy(stage: StageData) -> void:
	var kinds := PackedInt32Array()
	for mechanism in stage.mechanism_loadout:
		kinds.append(int(mechanism.canonical_kind()))
	match stage.stage_number:
		1:
			_assert(kinds.is_empty(), "Stage 01 must have no glyph")
		2:
			_assert(
				kinds == PackedInt32Array([MechanismData.Kind.BURST]),
				"Stage 02 must teach Burst"
			)
		3:
			_assert(
				kinds == PackedInt32Array([
					MechanismData.Kind.SPLITTER,
					MechanismData.Kind.UPHILL_REBOUND,
				]),
				"Stage 03 must teach Splitter and Uphill Rebound on three routes"
			)
		_:
			if stage.stage_number <= 17:
				for kind in kinds:
					_assert(
						kind == MechanismData.Kind.BURST
								or kind == MechanismData.Kind.UPHILL_REBOUND,
						"%s cannot request Splitter before three-route topology" % stage.stage_id
					)
	for kind in kinds:
		if kind == MechanismData.Kind.SPLITTER:
			_assert(
				stage.generation_profile.routes.size() >= 3,
				"%s Splitter requires at least three routes" % stage.stage_id
			)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
