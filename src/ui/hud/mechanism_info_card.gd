class_name MechanismInfoCard
extends PanelContainer

const CALLOUT_SECONDS := 1.2

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var timer: Timer = %Timer


func _ready() -> void:
	timer.wait_time = CALLOUT_SECONDS
	timer.timeout.connect(func() -> void: visible = false)
	visible = false


func show_brief(kind: MechanismData.Kind) -> void:
	_set_copy(kind)
	visible = true
	timer.stop()


func show_activation(kind: MechanismData.Kind) -> void:
	_set_copy(kind)
	description.text = tr("mechanism.activated")
	visible = true
	timer.start()


func hide_card() -> void:
	timer.stop()
	visible = false


func _set_copy(kind: MechanismData.Kind) -> void:
	var stem := "uphill_rebound"
	match kind:
		MechanismData.Kind.BURST:
			stem = "burst"
		MechanismData.Kind.SPLITTER:
			stem = "splitter"
	title.text = tr("mechanism.%s" % stem)
	description.text = tr("mechanism.%s.description" % stem)
