class_name ResultSummary
extends VBoxContainer

@onready var score_scale: ScoreScale = %ScoreScale


func _ready() -> void:
	score_scale.set_preset(ScoreScale.Preset.HORIZONTAL_SUMMARY)
	score_scale.set_world_mode(true)
	score_scale.get_node("MetricIcon").hide()
	score_scale.get_node("CurrentValue").hide()


func set_verdict(verdict: String, value: String) -> void:
	%Verdict.text = verdict
	%Value.text = value
	accessibility_name = "%s · %s" % [verdict, value]


func set_facts(text: String) -> void:
	%Facts.text = text


func set_timeout_visible(visible: bool) -> void:
	%TimeoutClock.visible = visible


func configure_coverage(target: float, value: float) -> void:
	score_scale.configure_coverage(target)
	score_scale.update_coverage(value)


func configure_target_band(
		target_band: TargetBandData,
		rule: ColorScoreRuleData,
		coverage: PaintCoverageSnapshot,
		score: float
) -> void:
	score_scale.configure_target_band(target_band, rule)
	score_scale.update_target_band(coverage, score, rule.red_weight, rule.green_weight)


func set_compact(compact: bool) -> void:
	score_scale.set_compact(compact)
	%Facts.visible = not compact
	%Verdict.add_theme_font_size_override(&"font_size", 24 if compact else 30)
	%Value.add_theme_font_size_override(&"font_size", 44 if compact else 64)
	custom_minimum_size = Vector2(360.0, 174.0) if compact else Vector2(440.0, 230.0)
