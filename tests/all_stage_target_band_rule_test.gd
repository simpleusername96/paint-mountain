extends SceneTree

const MATERIALIZER := preload("res://src/stage_generation/stage_catalog_materializer.gd")

var _failed := false


func _initialize() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	_assert(catalog != null and catalog.is_valid(), "the v12 catalog must be valid")
	if catalog == null:
		quit(1)
		return
	var introductory_shots := [4, 5, 5, 6, 6, 6]
	var introductory_bands := [
		Vector2(7.0, 11.0), Vector2(9.0, 13.0), Vector2(10.0, 14.0),
		Vector2(6.0, 10.0), Vector2(7.0, 11.0), Vector2(8.0, 12.0),
	]
	var later_patterns := [
		Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1),
		Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, 1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
	]
	var later_bands := [
		Vector2(8.0, 12.0), Vector2(9.0, 13.0), Vector2(7.0, 11.0),
		Vector2(5.0, 9.0), Vector2(7.0, 11.0), Vector2(9.0, 13.0),
		Vector2(6.0, 10.0), Vector2(6.0, 10.0), Vector2(9.0, 13.0),
		Vector2(7.0, 11.0), Vector2(3.0, 7.0), Vector2(1.0, 5.0),
		Vector2(1.0, 5.0), Vector2(0.5, 4.5), Vector2(1.0, 5.0),
		Vector2(1.0, 5.0), Vector2(3.0, 7.0), Vector2(1.0, 5.0),
		Vector2(3.0, 7.0), Vector2(0.5, 4.5), Vector2(4.0, 8.0),
		Vector2(2.0, 6.0), Vector2(2.0, 6.0), Vector2(4.0, 8.0),
	]
	var burst := BallKind.Value.IMPACT_BURST
	var split := BallKind.Value.APEX_SPLIT
	var later_required := [
		[burst], [split], [burst], [split], [burst, split], [burst, split],
		[burst], [split], [burst, split], [split], [burst], [burst, split],
		[burst], [split], [burst], [burst, split], [burst, split], [burst, split],
		[burst], [split], [burst, split], [burst, split], [burst, split], [burst, split],
	]
	for stage_number in range(1, StageProgressionData.STAGE_COUNT + 1):
		var stage_id := StringName("stage_%02d" % stage_number)
		var stage := catalog.get_stage(stage_id)
		_assert(stage != null, "%s must materialize" % stage_id)
		if stage == null:
			continue
		_assert(stage.uses_target_band(), "%s must use target-band scoring" % stage_id)
		_assert(stage.has_valid_rule_contract(), "%s rule contract must validate" % stage_id)
		if stage_number <= 6:
			_assert(stage.maximum_shots == introductory_shots[stage_number - 1],
				"%s introductory shot count must remain exact" % stage_id)
			_assert(_band(stage).is_equal_approx(introductory_bands[stage_number - 1]),
				"%s introductory band must remain exact" % stage_id)
		else:
			var later_index := stage_number - 7
			var expected_shots := 6 if stage_number <= 15 else 7
			var weights: Vector2i = later_patterns[later_index]
			_assert(stage.maximum_shots == expected_shots,
				"%s shot tier must match the resident-safe progression" % stage_id)
			_assert(_band(stage).is_equal_approx(later_bands[later_index]),
				"%s target band must match the explicit chapter table" % stage_id)
			_assert(Vector2i(stage.color_score_rule.green_weight, stage.color_score_rule.red_weight) == weights,
				"%s score pattern must match the explicit chapter table" % stage_id)
			_assert(weights.x != 0 and weights.y != 0,
				"%s both paint colors must directly affect score" % stage_id)
			_assert(stage.ball_deal_profile.required_kinds == later_required[later_index],
				"%s special-kind requirement must be stage-specific" % stage_id)
		for seed_offset in range(16):
			var seed := stage.default_deal_seed + seed_offset
			var deal := BallDealGenerator.generate(
				stage.stage_id, seed, stage.maximum_shots, stage.ball_deal_profile
			)
			var replay := BallDealGenerator.generate(
				stage.stage_id, seed, stage.maximum_shots, stage.ball_deal_profile
			)
			_assert(BallDealGenerator.is_valid_deal(
				deal, stage.maximum_shots, stage.ball_deal_profile
			), "%s seed %d must be structurally valid" % [stage_id, seed_offset])
			_assert(_same_deal(deal, replay),
				"%s seed %d must reproduce exact tokens" % [stage_id, seed_offset])

	if not _failed:
		print("All-stage target-band rules passed: five chapters, 30 profiles, and 480 deterministic deals.")
	quit(1 if _failed else 0)


func _band(stage: StageData) -> Vector2:
	return Vector2(stage.target_band.target_min, stage.target_band.target_max)


func _same_deal(left: Array[BallToken], right: Array[BallToken]) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if not left[index].matches(right[index]):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("All-stage target-band rule check failed: %s" % message)
