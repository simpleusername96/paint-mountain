class_name ResultSummary
extends VBoxContainer

@onready var score_scale: ScoreScale = %ScoreScale


func _ready() -> void:
	score_scale.set_preset(ScoreScale.Preset.HORIZONTAL_SUMMARY)


func set_verdict(verdict: String, value: String) -> void:
	%Verdict.text = verdict
	%Value.text = value
	accessibility_name = "%s · %s" % [verdict, value]


func set_facts(text: String) -> void:
	%Facts.text = text
