class_name ResultPanel
extends PanelContainer

signal retry_requested
signal next_requested
signal stages_requested

@onready var title: Label = %Title
@onready var stars: Label = %Stars
@onready var coverage: Label = %Coverage
@onready var coverage_explanation: Label = %CoverageExplanation
@onready var previous_best: Label = %PreviousBest
@onready var metadata: Label = %Metadata

var _final_coverage := 0.0
var _star_count := 0
var _previous_best := 0.0
var _elapsed_seconds := -1.0
var _shots_used := -1
var _finish_reason: StringName = &"manual"


func _ready() -> void:
	%Retry.pressed.connect(func() -> void: retry_requested.emit())
	%Next.pressed.connect(func() -> void: next_requested.emit())
	%Stages.pressed.connect(func() -> void: stages_requested.emit())


func configure_has_next(has_next: bool) -> void:
	%Next.disabled = not has_next


func show_coverage_result(
		final_coverage: float,
		star_count: int,
		best_coverage: float,
		elapsed_seconds: float = -1.0,
		shots_used: int = -1,
		finish_reason: StringName = &"manual"
) -> void:
	_final_coverage = clampf(final_coverage, 0.0, 100.0)
	_star_count = clampi(star_count, 0, 3)
	_previous_best = clampf(best_coverage, 0.0, 100.0)
	_elapsed_seconds = elapsed_seconds
	_shots_used = shots_used
	_finish_reason = finish_reason
	_refresh_copy()


func refresh_locale() -> void:
	_refresh_copy()


func focus_retry() -> void:
	%Retry.grab_focus()


func _refresh_copy() -> void:
	title.text = tr("result.time_expired") if _finish_reason == &"timeout" else tr("result.completed")
	coverage.text = "%.1f%%" % _final_coverage
	coverage_explanation.text = tr("result.coverage_explanation")
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
