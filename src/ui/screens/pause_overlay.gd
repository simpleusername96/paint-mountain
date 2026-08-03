class_name PauseOverlay
extends Control

signal resume_requested
signal restart_requested
signal settings_requested
signal stages_requested
signal main_menu_requested


func _ready() -> void:
	%Resume.pressed.connect(func() -> void: resume_requested.emit())
	%Restart.pressed.connect(func() -> void: restart_requested.emit())
	%Settings.pressed.connect(func() -> void: settings_requested.emit())
	%Stages.pressed.connect(func() -> void: stages_requested.emit())
	%MainMenu.pressed.connect(func() -> void: main_menu_requested.emit())


func focus_resume() -> void:
	%Resume.grab_focus()
