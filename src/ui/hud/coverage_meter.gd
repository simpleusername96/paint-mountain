class_name CoverageMeter
extends Control

@onready var progress: ProgressBar = %Progress
@onready var value_label: Label = %CoverageValue
@onready var target_label: Label = %TargetValue
@onready var target_line: HSeparator = %TargetLine
var _target := 0.0


func configure(target: float) -> void:
	_target = clampf(target, 0.0, 100.0)
	tooltip_text = tr("hud.coverage_tooltip")
	target_label.text = "◆ %.0f" % _target
	var target_y := progress.position.y + progress.size.y * (1.0 - _target / 100.0)
	target_line.position.y = target_y - target_line.size.y * 0.5
	update_coverage(0.0)


func update_coverage(coverage: float) -> void:
	var absolute_coverage := clampf(coverage, 0.0, 100.0)
	progress.value = absolute_coverage
	value_label.text = "%.1f%%" % absolute_coverage


func refresh_locale() -> void:
	configure(_target)
