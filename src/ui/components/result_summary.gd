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


func set_facts(text: String, accessible_text: String = "") -> void:
	%Facts.text = text
	%Facts.accessibility_name = accessible_text if not accessible_text.is_empty() else text


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


func set_compact(compact: bool, density: float = 1.0) -> void:
	var resolved_density := maxf(density, 1.0)
	score_scale.set_compact(compact, resolved_density)
	%Facts.visible = true
	%Verdict.add_theme_font_size_override(
		&"font_size", roundi(22.0 * resolved_density) if compact else 30
	)
	%Value.add_theme_font_size_override(
		&"font_size", roundi(36.0 * resolved_density) if compact else 64
	)
	%Facts.add_theme_font_size_override(
		&"font_size", roundi(14.0 * resolved_density) if compact else 16
	)
	custom_minimum_size = Vector2(440.0, 188.0 * resolved_density) \
			if compact else Vector2(440.0, 230.0)
