extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var coverage := PaintCoverageSnapshot.new(4.0, 7.0, 11.0, 91)
	var expected := [11.0, 3.0, -3.0, 7.0, 4.0]
	for pattern in ColorScoreRuleData.Pattern.values():
		_assert(is_equal_approx(ColorScoreRuleData.from_pattern(pattern).score(coverage), expected[pattern]), "pattern %s must retain its signed score" % pattern)
	_assert(coverage.total_percent == 11.0 and coverage.checksum == 91, "coverage must retain physical channels and checksum")
	_assert(ColorScoreRuleData.new().is_valid(), "default score rule must be valid")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("color_score_rule_test failed: %s" % message)
