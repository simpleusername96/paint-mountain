class_name ResultPanel
extends PanelContainer

signal retry_requested
signal next_requested
signal stages_requested
signal replay_requested

@onready var title: Label = %Title
@onready var stars: Label = %Stars
@onready var details: Label = %Details


func _ready() -> void:
	%Retry.pressed.connect(func() -> void: retry_requested.emit())
	%Next.pressed.connect(func() -> void: next_requested.emit())
	%Stages.pressed.connect(func() -> void: stages_requested.emit())
	%Replay.pressed.connect(func() -> void: replay_requested.emit())


func configure_has_next(has_next: bool) -> void:
	%Next.disabled = not has_next


func show_clear(final_coverage: float, target: float, shots_used: int, star_count: int, previous_best: float) -> void:
	title.text = tr("result.clear")
	stars.text = "★".repeat(star_count) + "☆".repeat(maxi(0, 3 - star_count))
	details.text = "%s  %.2f%%\n%s  %.2f%%\n%s  %d\n%s  %.2f%%" % [tr("result.final"), final_coverage, tr("result.target"), target, tr("result.shots_used"), shots_used, tr("result.previous_best"), previous_best]


func show_failure(final_coverage: float, missing: float, previous_best: float) -> void:
	title.text = tr("result.failed")
	stars.text = "☆☆☆"
	details.text = "%s  %.2f%%\n%s  %.2f%%\n%s  %.2f%%" % [tr("result.final"), final_coverage, tr("result.missing"), missing, tr("result.previous_best"), previous_best]


func focus_retry() -> void:
	%Retry.grab_focus()
