extends SceneTree

const MATERIALIZER := preload("res://src/stage_generation/stage_catalog_materializer.gd")

var _failed := false


func _initialize() -> void:
	for stage_number in range(1, 7):
		var source := StageCatalog.get_stage(StringName("stage_%02d" % stage_number))
		var stage := MATERIALIZER.materialize_stage(source, stage_number) as StageData
		_assert(stage != null, "prototype stage %d must materialize" % stage_number)
		if stage == null:
			continue
		_assert(stage.uses_target_band(), "prototype stage %d must use target-band rule" % stage_number)
		_assert(stage.has_valid_rule_contract(), "prototype stage %d rule must validate" % stage_number)
		_assert(stage.maximum_shots == [4, 5, 5, 6, 6, 6][stage_number - 1], "prototype shot count must match contract")
		var expected_band: Vector2 = [
			Vector2(7.0, 11.0), Vector2(9.0, 13.0), Vector2(10.0, 14.0),
			Vector2(6.0, 10.0), Vector2(7.0, 11.0), Vector2(8.0, 12.0),
		][stage_number - 1]
		_assert(is_equal_approx(stage.target_band.target_min, expected_band.x), "prototype target minimum must match")
		_assert(is_equal_approx(stage.target_band.target_max, expected_band.y), "prototype target maximum must match")
		for seed_offset in range(16):
			var deal := BallDealGenerator.generate(
				stage.stage_id,
				stage.default_deal_seed + seed_offset,
				stage.maximum_shots,
				stage.ball_deal_profile
			)
			_assert(BallDealGenerator.is_valid_deal(deal, stage.maximum_shots, stage.ball_deal_profile), "prototype seed %d/%d must be structurally valid" % [stage_number, seed_offset])

	var legacy_source := StageCatalog.get_stage(&"stage_07")
	var legacy := MATERIALIZER.materialize_stage(legacy_source, 7) as StageData
	_assert(legacy != null and not legacy.uses_target_band(), "stage 07 must retain the legacy rule")
	_assert(legacy != null and legacy.has_valid_rule_contract(), "legacy rule contract must remain valid")

	if not _failed:
		print("prototype_stage_rule_test passed: six profiles, 96 structural seeds, legacy boundary")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Prototype stage rule check failed: %s" % message)
