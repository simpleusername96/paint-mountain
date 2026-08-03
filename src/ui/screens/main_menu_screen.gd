class_name MainMenuScreen
extends CanvasLayer

signal play_requested
signal stage_select_requested
signal settings_requested
signal quit_requested


func _ready() -> void:
	%Play.pressed.connect(func() -> void: play_requested.emit())
	%StageSelect.pressed.connect(func() -> void: stage_select_requested.emit())
	%Settings.pressed.connect(func() -> void: settings_requested.emit())
	%Quit.pressed.connect(func() -> void: quit_requested.emit())


func focus_primary() -> void:
	%Play.grab_focus()
