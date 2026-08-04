class_name CoverageMeter
extends PanelContainer

@onready var progress: ProgressBar = %Progress
@onready var value_label: Label = %CoverageValue
@onready var target_label: Label = %TargetValue
var _target := 0.0


func configure(target: float) -> void:
	_target = clampf(target, 0.0, 100.0)
	target_label.text = "%s %.0f%%" % [tr("hud.target"), _target]
	update_coverage(0.0)


func update_coverage(coverage: float) -> void:
	var absolute_coverage := clampf(coverage, 0.0, 100.0)
	progress.value = clampf(absolute_coverage / maxf(_target, 0.001) * 100.0, 0.0, 100.0)
	value_label.text = "%.1f%%" % absolute_coverage
