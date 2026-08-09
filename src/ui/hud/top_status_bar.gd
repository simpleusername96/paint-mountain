class_name TopStatusBar
extends Control

signal settings_requested

@onready var stage_value: Label = %StageValue
@onready var mode_value: Label = %ModeValue


func _ready() -> void:
	%SettingsButton.pressed.connect(func() -> void: settings_requested.emit())


func configure(stage: StageData) -> void:
	stage_value.text = "▲ %s %02d" % [tr("hud.stage"), stage.stage_number]


func update_mode(state: StageController.State) -> void:
	var key: String = String({
		StageController.State.BRIEFING: "hud.briefing",
		StageController.State.AIMING: "hud.aiming",
		StageController.State.PROJECTILE_IN_FLIGHT: "hud.in_flight",
		StageController.State.PAINT_SETTLING: "hud.paint_settling",
		StageController.State.SHOT_RESULT: "hud.shot_result",
		StageController.State.FINISHING: "hud.finishing",
		StageController.State.RESULT: "hud.result",
	}.get(state, "hud.aiming"))
	mode_value.text = tr(key)
