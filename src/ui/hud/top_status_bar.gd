class_name TopStatusBar
extends Control

@onready var stage_value: Label = %StageValue
@onready var target_value: Label = %TargetValue
@onready var shots_value: Label = %ShotsValue
@onready var mode_value: Label = %ModeValue


func configure(stage: StageData) -> void:
	stage_value.text = "%s %02d" % [tr("hud.stage"), stage.stage_number]
	target_value.text = "%s  %.0f%%" % [tr("hud.target"), stage.target_coverage]
	update_shots(stage.maximum_shots)


func update_shots(remaining: int) -> void:
	shots_value.text = "%s  %d" % [tr("hud.shots"), remaining]


func update_mode(state: StageController.State) -> void:
	var key: String = String({
		StageController.State.BRIEFING: "hud.briefing",
		StageController.State.AIMING: "hud.aiming",
		StageController.State.PROJECTILE_IN_FLIGHT: "hud.in_flight",
		StageController.State.PAINT_SETTLING: "hud.paint_settling",
		StageController.State.SHOT_RESULT: "hud.shot_result",
		StageController.State.STAGE_CLEAR: "hud.stage_clear",
		StageController.State.STAGE_FAILED: "hud.stage_failed",
	}.get(state, "hud.aiming"))
	mode_value.text = tr(key)
