class_name CoverageMeter
extends PanelContainer

@onready var progress: ProgressBar = %Progress
@onready var value_label: Label = %CoverageValue
@onready var target_marker: ColorRect = %TargetMarker
var _target := 0.0


func configure(target: float) -> void:
	_target = clampf(target, 0.0, 100.0)
	_update_marker.call_deferred()
	update_coverage(0.0)


func update_coverage(coverage: float) -> void:
	progress.value = clampf(coverage, 0.0, 100.0)
	value_label.text = tr("hud.coverage_format") % [coverage, _target]


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_marker.call_deferred()


func _update_marker() -> void:
	if not is_instance_valid(target_marker) or not is_instance_valid(progress):
		return
	target_marker.position.x = progress.position.x + progress.size.x * _target / 100.0 - 1.0
