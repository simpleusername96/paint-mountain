extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var band := TargetBandData.new()
	band.target_min = 6.0
	band.target_max = 10.0
	_assert(band.contains(6.0) and band.contains(10.0), "target band edges must be inclusive")
	_assert(band.stars_for(8.0) == 3, "band center must award three stars")
	_assert(band.stars_for(7.0) == 2 and band.stars_for(9.0) == 2, "half-width 50 percent boundary must award two stars")
	_assert(band.stars_for(6.5) == 1 and band.stars_for(9.5) == 1, "outer in-band scores must award one star")
	var invalid_band := TargetBandData.new()
	invalid_band.target_max = invalid_band.target_min
	_assert(band.stars_for(5.99) == 0 and not invalid_band.is_valid(), "out-of-band and invalid bands must reject")
	var score := StageScoreSnapshot.new(PaintCoverageSnapshot.new(3.0, 6.0, 9.0), ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.GREEN_ADD_RED_SUBTRACT), band)
	_assert(score.paint_score == 3.0 and not score.in_target_band and score.stars == 0, "score snapshot must compose coverage, rule, and band")
	var negative_score := StageScoreSnapshot.new(PaintCoverageSnapshot.new(4.0, 1.0, 5.0), ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.GREEN_ADD_RED_SUBTRACT), band)
	_assert(negative_score.paint_score == -3.0 and not negative_score.in_target_band and negative_score.stars == 0, "signed score snapshots must preserve below-zero results")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("target_band_result_test failed: %s" % message)
