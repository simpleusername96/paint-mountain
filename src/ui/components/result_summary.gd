class_name ResultSummary
extends VBoxContainer

@onready var score_scale: ScoreScale = %ScoreScale

var _target_band_mode := false


func _ready() -> void:
	score_scale.set_preset(ScoreScale.Preset.HORIZONTAL_SUMMARY)
	score_scale.set_world_mode(true)
	score_scale.set_header_visible(false)


func set_verdict(verdict: String, value: String) -> void:
	%Verdict.text = verdict
	%Value.text = value
	accessibility_name = "%s · %s" % [verdict, value]


func set_stage_number(stage_number: int) -> void:
	%Stage.text = "%s %02d" % [tr("hud.stage"), maxi(stage_number, 1)]


func set_facts(
		_star_count: int,
		previous_best: float,
		include_previous_best: bool,
		elapsed_seconds: float,
		shots_used: int,
		accessible_text: String
) -> void:
	%PreviousBest.visible = include_previous_best
	%PreviousBestValue.text = "%.1f%%" % previous_best
	%Elapsed.visible = elapsed_seconds >= 0.0
	%ElapsedValue.text = _format_duration(elapsed_seconds)
	%Shots.visible = shots_used >= 0
	%ShotsValue.text = "%d" % shots_used
	%Facts.accessibility_name = accessible_text


func set_gap(text: String) -> void:
	%Gap.text = text
	%Gap.visible = not _target_band_mode and not text.is_empty()


func set_timeout_visible(visible: bool) -> void:
	%TimeoutClock.visible = visible


func configure_coverage(target: float, value: float) -> void:
	_target_band_mode = false
	%ValueRow.show()
	%Target.text = "· %s %.1f%%" % [tr("hud.target"), target]
	%Contributions.hide()
	score_scale.configure_coverage(target)
	score_scale.update_coverage(value)


func configure_target_band(
		target_band: TargetBandData,
		rule: ColorScoreRuleData,
		coverage: PaintCoverageSnapshot,
		score: float
) -> void:
	_target_band_mode = true
	%ValueRow.hide()
	%Gap.hide()
	%RedContribution.text = _format_signed(rule.red_weight * coverage.red_percent)
	%GreenContribution.text = _format_signed(rule.green_weight * coverage.green_percent)
	%RedContribution.add_theme_color_override(
		&"font_color", score_scale.get_theme_color(&"red", &"ScoreScale"))
	%GreenContribution.add_theme_color_override(
		&"font_color", score_scale.get_theme_color(&"green", &"ScoreScale"))
	%Contributions.show()
	score_scale.configure_target_band(target_band, rule)
	score_scale.update_target_band(coverage, score, rule.red_weight, rule.green_weight)


func set_compact(compact: bool, density: float = 1.0) -> void:
	var resolved_density := maxf(density, 1.0)
	score_scale.set_compact(compact, resolved_density)
	%Facts.visible = true
	%Verdict.add_theme_font_size_override(
		&"font_size", roundi(28.0 * resolved_density) if compact else 42
	)
	%Stage.add_theme_font_size_override(
		&"font_size", roundi(14.0 * resolved_density) if compact else 18
	)
	%Value.add_theme_font_size_override(
		&"font_size", roundi(36.0 * resolved_density) if compact else 64
	)
	%Target.add_theme_font_size_override(
		&"font_size", roundi(14.0 * resolved_density) if compact else 18
	)
	for contribution in [%RedContribution, %GreenContribution]:
		(contribution as Label).add_theme_font_size_override(
			&"font_size", roundi(14.0 * resolved_density) if compact else 18
		)
	for fact_value in [%PreviousBestValue, %ElapsedValue, %ShotsValue]:
		(fact_value as Label).add_theme_font_size_override(
				&"font_size", roundi(14.0 * resolved_density) if compact else 16
		)
	%Gap.add_theme_font_size_override(
		&"font_size", roundi(16.0 * resolved_density) if compact else 20
	)
	%Spacer.custom_minimum_size = Vector2(
		0.0, (24.0 if compact else 96.0) * resolved_density
	)
	custom_minimum_size = Vector2(300.0, 252.0 * resolved_density) \
			if compact else Vector2(440.0, 408.0)


func _format_signed(value: float) -> String:
	return "%s%.1f" % ["+" if value >= 0.0 else "−", absf(value)]


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(roundi(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
