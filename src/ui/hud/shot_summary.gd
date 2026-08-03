class_name ShotSummary
extends PanelContainer

const DISPLAY_SECONDS := 1.2

@onready var summary: Label = %Summary
@onready var timer: Timer = %Timer


func _ready() -> void:
	timer.wait_time = DISPLAY_SECONDS
	timer.timeout.connect(func() -> void: visible = false)
	visible = false


func show_observation(observation: ShotObservation) -> void:
	var causes: Array[String] = []
	var splitter_count := observation.mechanism_activation_kinds.count(MechanismData.Kind.SPLITTER)
	if splitter_count > 0:
		causes.append(tr("hud.summary_split") % splitter_count)
	if observation.spawned_child_count > 0:
		causes.append(tr("hud.summary_balls") % observation.spawned_child_count)
	if causes.is_empty():
		causes.append(tr("hud.summary_direct"))
	summary.text = "+%.1f%% · %s" % [observation.coverage_gain, " · ".join(causes)]
	visible = true
	timer.start()
