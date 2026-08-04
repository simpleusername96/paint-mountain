class_name ActionButtons
extends Control

signal fire_requested


func _ready() -> void:
	%FireButton.pressed.connect(func() -> void: fire_requested.emit())


func set_fire_enabled(enabled: bool) -> void:
	%FireButton.disabled = not enabled


func focus_fire() -> void:
	%FireButton.grab_focus()
