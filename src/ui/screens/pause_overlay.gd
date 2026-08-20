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
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout.call_deferred()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var window_size := viewport_size if get_viewport() is SubViewport \
			else Vector2(DisplayServer.window_get_size())
	var compact := window_size.y < 480.0
	var surface := $Center/Surface as PanelContainer
	var margin := $Center/Surface/Margin as MarginContainer
	var column := $Center/Surface/Margin/Column as VBoxContainer
	var title := $Center/Surface/Margin/Column/Title as Label
	if compact:
		surface.custom_minimum_size.x = 320.0
		for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
			margin.add_theme_constant_override(side, 8)
		column.add_theme_constant_override(&"separation", 2)
		title.theme_type_variation = &"ScreenTitleCompact"
		%Resume.custom_minimum_size.y = 44.0
		for button in [%Restart, %Settings, %Stages, %MainMenu]:
			button.custom_minimum_size.y = 40.0
	else:
		surface.custom_minimum_size.x = 340.0
		margin.add_theme_constant_override(&"margin_left", 22)
		margin.add_theme_constant_override(&"margin_top", 20)
		margin.add_theme_constant_override(&"margin_right", 22)
		margin.add_theme_constant_override(&"margin_bottom", 20)
		column.add_theme_constant_override(&"separation", 8)
		title.theme_type_variation = &"ScreenTitle"
		%Resume.custom_minimum_size.y = 52.0
		for button in [%Restart, %Settings, %Stages, %MainMenu]:
			button.custom_minimum_size.y = 48.0


func focus_resume() -> void:
	%Resume.grab_focus()


func focus_settings() -> void:
	%Settings.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed(&"ui_cancel"):
		return
	if event is InputEventKey and event.echo:
		return
	get_viewport().set_input_as_handled()
	resume_requested.emit()
