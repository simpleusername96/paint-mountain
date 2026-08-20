class_name ResultPanel
extends Control

signal retry_requested
signal next_requested
signal stages_requested
signal retry_same_deal_requested
signal new_deal_requested

@onready var _summary: ResultSummary = %Summary
@onready var _retry: ActionControl = %Retry
@onready var _next: ActionControl = %Next
@onready var _stages: ActionControl = %Stages
@onready var _retry_same_deal: ActionControl = %RetrySameDeal
@onready var _new_deal: ActionControl = %NewDeal

var _final_coverage := 0.0
var _star_count := 0
var _previous_best := 0.0
var _elapsed_seconds := -1.0
var _shots_used := -1
var _finish_reason: StringName = &"manual"
var _target_coverage := 0.0
var _target_result_active := false
var _target_clear := false
var _target_score := 0.0
var _target_band: TargetBandData
var _score_rule: ColorScoreRuleData
var _target_coverage_snapshot := PaintCoverageSnapshot.new()
var _has_next := false


func _ready() -> void:
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	_next.pressed.connect(func() -> void: next_requested.emit())
	_stages.pressed.connect(func() -> void: stages_requested.emit())
	_retry_same_deal.pressed.connect(func() -> void: retry_same_deal_requested.emit())
	_new_deal.pressed.connect(func() -> void: new_deal_requested.emit())
	_refresh_actions()


func configure_has_next(has_next: bool) -> void:
	_has_next = has_next
	_next.disabled = not has_next
	_refresh_actions()


func configure_target(target_coverage: float) -> void:
	_target_coverage = clampf(target_coverage, 0.0, 100.0)
	_refresh_copy()


func configure_target_band_model(target_band: TargetBandData, score_rule: ColorScoreRuleData) -> void:
	_target_band = target_band
	_score_rule = score_rule


func show_coverage_result(
		final_coverage: float,
		star_count: int,
		best_coverage: float,
		elapsed_seconds: float = -1.0,
		shots_used: int = -1,
		finish_reason: StringName = &"manual"
) -> void:
	_target_result_active = false
	_final_coverage = clampf(final_coverage, 0.0, 100.0)
	_star_count = clampi(star_count, 0, 3)
	_previous_best = clampf(best_coverage, 0.0, 100.0)
	_elapsed_seconds = elapsed_seconds
	_shots_used = shots_used
	_finish_reason = finish_reason
	_refresh_copy()
	_refresh_actions()


func show_target_band_result(
		clear: bool, score: float, target_band: TargetBandData, star_count: int,
		coverage: PaintCoverageSnapshot, elapsed_seconds: float = -1.0, shots_used: int = -1,
		finish_reason: StringName = &"manual"
) -> void:
	_target_result_active = true
	_target_clear = clear
	_target_score = score
	_target_band = target_band
	_target_coverage_snapshot = coverage
	_finish_reason = finish_reason
	_star_count = clampi(star_count, 0, 3)
	_elapsed_seconds = elapsed_seconds
	_shots_used = shots_used
	_refresh_copy()
	_refresh_actions()


func refresh_locale() -> void:
	_refresh_copy()
	_refresh_actions()


func set_compact(compact: bool, density: float = 1.0) -> void:
	var resolved_density := maxf(density, 1.0)
	custom_minimum_size = Vector2(360.0, 276.0) if compact else Vector2(496.0, 560.0)
	_summary.set_compact(compact, resolved_density)
	var action_size := Vector2(150.0, 44.0) * resolved_density \
			if compact else Vector2(136.0, 48.0)
	for action in [_retry, _next, _stages, _retry_same_deal, _new_deal]:
		action.custom_minimum_size = action_size
		action.add_theme_font_size_override(
			&"font_size", roundi(17.0 * resolved_density) if compact else 17
		)
	%Margin.add_theme_constant_override(
		&"margin_left", roundi(14.0 * resolved_density) if compact else 24
	)
	%Margin.add_theme_constant_override(
		&"margin_top", roundi(12.0 * resolved_density) if compact else 22
	)
	%Margin.add_theme_constant_override(
		&"margin_right", roundi(14.0 * resolved_density) if compact else 24
	)
	%Margin.add_theme_constant_override(
		&"margin_bottom", roundi(12.0 * resolved_density) if compact else 22
	)


func focus_retry() -> void:
	if _target_result_active:
		(_next if _target_clear and _has_next else _retry_same_deal).grab_focus()
	else:
		(_next if _has_next else _retry).grab_focus()


func _refresh_copy() -> void:
	if not is_node_ready():
		return
	_summary.set_timeout_visible(_finish_reason == &"timeout")
	if _target_result_active:
		var verdict := tr("result.clear") if _target_clear else tr("result.failed")
		_summary.set_verdict(verdict, "%.1f" % _target_score)
		if _target_band != null and _score_rule != null:
			_summary.configure_target_band(
				_target_band, _score_rule, _target_coverage_snapshot, _target_score
			)
		_summary.set_facts(
			"%s · %s" % [_stars_text(), _metadata_text()],
			_accessible_facts(false)
		)
		return
	var verdict := tr("result.time_expired") if _finish_reason == &"timeout" \
			else tr("result.completed")
	_summary.set_verdict(verdict, "%.1f%%" % _final_coverage)
	_summary.configure_coverage(_target_coverage, _final_coverage)
	_summary.set_facts(
		"%s · ↑ %.1f%% · %s" % [_stars_text(), _previous_best, _metadata_text()],
		_accessible_facts(true)
	)


func _refresh_actions() -> void:
	if not is_node_ready():
		return
	_retry.configure("ui.retry")
	_next.configure("ui.next")
	_stages.configure("ui.stages")
	_retry_same_deal.configure("ui.same_deal")
	_new_deal.configure("ui.new_deal")
	_retry.visible = not _target_result_active
	_next.visible = _has_next and (not _target_result_active or _target_clear)
	_retry_same_deal.visible = _target_result_active
	_new_deal.visible = _target_result_active
	_set_primary(_retry, not _target_result_active and not _has_next)
	_set_primary(_next, _has_next and (not _target_result_active or _target_clear))
	_set_primary(_retry_same_deal, _target_result_active and (not _target_clear or not _has_next))
	_set_primary(_new_deal, false)
	_set_primary(_stages, false)


func _set_primary(action: ActionControl, primary: bool) -> void:
	action.theme_type_variation = &"ActionControl" if primary else &"WorldQuietButton"


func _stars_text() -> String:
	return "★".repeat(_star_count) + "☆".repeat(maxi(0, 3 - _star_count))


func _metadata_text() -> String:
	var facts: Array[String] = []
	if _elapsed_seconds >= 0.0:
		facts.append("◷ %s" % _format_duration(_elapsed_seconds))
	if _shots_used >= 0:
		facts.append("◉ %d" % _shots_used)
	return " · ".join(facts)


func _accessible_facts(include_previous_best: bool) -> String:
	var facts: Array[String] = ["%s %s" % [tr("result.grade"), _stars_text()]]
	if include_previous_best:
		facts.append("%s %.1f%%" % [tr("result.previous_best"), _previous_best])
	if _elapsed_seconds >= 0.0:
		facts.append("%s %s" % [tr("result.elapsed"), _format_duration(_elapsed_seconds)])
	if _shots_used >= 0:
		facts.append("%s %d" % [tr("result.shots_used"), _shots_used])
	return "; ".join(facts)


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(roundi(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
