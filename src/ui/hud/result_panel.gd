class_name ResultPanel
extends PanelContainer

signal retry_requested
signal next_requested
signal stages_requested
signal retry_same_deal_requested
signal new_deal_requested

@onready var title: Label = %Title
@onready var stars: Label = %Stars
@onready var coverage: Label = %Coverage
@onready var target: Label = %Target
@onready var color_breakdown: Label = %ColorBreakdown
@onready var previous_best: Label = %PreviousBest
@onready var metadata: Label = %Metadata

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
var _target_min := 0.0
var _target_max := 0.0
var _target_red := 0.0
var _target_green := 0.0


func _ready() -> void:
	%Retry.pressed.connect(func() -> void: retry_requested.emit())
	%Next.pressed.connect(func() -> void: next_requested.emit())
	%Stages.pressed.connect(func() -> void: stages_requested.emit())
	%RetrySameDeal.pressed.connect(func() -> void: retry_same_deal_requested.emit())
	%NewDeal.pressed.connect(func() -> void: new_deal_requested.emit())


func configure_has_next(has_next: bool) -> void:
	%Next.disabled = not has_next


func configure_target(target_coverage: float) -> void:
	_target_coverage = clampf(target_coverage, 0.0, 100.0)
	_refresh_copy()


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
	%Retry.visible = true
	%Next.visible = true
	previous_best.visible = true
	%RetrySameDeal.visible = false
	%NewDeal.visible = false


func show_target_band_result(
		clear: bool, score: float, target_band: TargetBandData, star_count: int,
		coverage: PaintCoverageSnapshot, elapsed_seconds: float = -1.0, shots_used: int = -1,
		finish_reason: StringName = &"manual"
) -> void:
	_target_result_active = true
	_target_clear = clear
	_target_score = score
	_target_min = target_band.target_min
	_target_max = target_band.target_max
	_target_red = coverage.red_percent
	_target_green = coverage.green_percent
	_finish_reason = finish_reason
	_star_count = clampi(star_count, 0, 3)
	_elapsed_seconds = elapsed_seconds
	_shots_used = shots_used
	_refresh_copy()
	previous_best.visible = false
	%Retry.visible = false
	%Next.visible = clear
	%RetrySameDeal.visible = true
	%NewDeal.visible = true


func refresh_locale() -> void:
	_refresh_copy()


func focus_retry() -> void:
	(%RetrySameDeal if _target_result_active else %Retry).grab_focus()


func _refresh_copy() -> void:
	if _target_result_active:
		title.text = tr("result.clear") if _target_clear else tr("result.failed")
		%TimeoutClock.visible = _finish_reason == &"timeout"
		coverage.text = "%s %.1f" % [tr("result.score"), _target_score]
		target.text = "%s %.1f–%.1f" % [tr("result.band"), _target_min, _target_max]
		color_breakdown.text = "R %.1f%%  ·  G %.1f%%" % [_target_red, _target_green]
		color_breakdown.visible = true
		stars.text = "%s  %s" % [
			tr("result.grade"),
			"★".repeat(_star_count) + "☆".repeat(maxi(0, 3 - _star_count)),
		]
		var target_lines: Array[String] = []
		if _elapsed_seconds >= 0.0:
			target_lines.append("%s  %s" % [tr("result.elapsed"), _format_duration(_elapsed_seconds)])
		if _shots_used >= 0:
			target_lines.append("%s  %d" % [tr("result.shots_used"), _shots_used])
		metadata.text = " · ".join(target_lines)
		metadata.visible = not target_lines.is_empty()
		return
	color_breakdown.visible = false
	title.text = tr("result.time_expired") if _finish_reason == &"timeout" else tr("result.completed")
	%TimeoutClock.visible = _finish_reason == &"timeout"
	coverage.text = "%.1f%%" % _final_coverage
	target.text = "%s %.0f%%" % [tr("stage.target"), _target_coverage]
	stars.text = "%s  %s" % [
		tr("result.grade"),
		"★".repeat(_star_count) + "☆".repeat(maxi(0, 3 - _star_count)),
	]
	previous_best.text = "%s  %.1f%%" % [tr("result.previous_best"), _previous_best]
	var lines: Array[String] = []
	if _elapsed_seconds >= 0.0:
		lines.append("%s  %s" % [tr("result.elapsed"), _format_duration(_elapsed_seconds)])
	if _shots_used >= 0:
		lines.append("%s  %d" % [tr("result.shots_used"), _shots_used])
	metadata.text = " · ".join(lines)
	metadata.visible = not lines.is_empty()


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(roundi(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
