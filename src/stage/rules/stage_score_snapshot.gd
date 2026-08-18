class_name StageScoreSnapshot
extends RefCounted

var coverage: PaintCoverageSnapshot
var paint_score: float
var in_target_band: bool
var stars: int
var center_error: float


func _init(coverage_snapshot: PaintCoverageSnapshot, rule: ColorScoreRuleData, target_band: TargetBandData) -> void:
	coverage = coverage_snapshot
	paint_score = rule.score(coverage_snapshot)
	in_target_band = target_band.contains(paint_score)
	stars = target_band.stars_for(paint_score)
	center_error = absf(paint_score - target_band.center())


func is_valid() -> bool:
	return coverage != null and coverage.is_valid() and stars >= 0 and stars <= 3
