class_name PauseOverlay
extends Control

signal resume_requested
signal restart_requested
signal settings_requested
signal stages_requested
signal main_menu_requested


func _ready() -> void:
	(%Resume as ActionControl).configure(
		"ui.resume", ActionControl.IconKind.PLAY, ActionControl.VisualRole.PRIMARY)
	(%Restart as ActionControl).configure(
		"ui.restart", ActionControl.IconKind.RETRY, ActionControl.VisualRole.WORLD)
	(%Settings as ActionControl).configure(
		"ui.settings", ActionControl.IconKind.SETTINGS, ActionControl.VisualRole.WORLD)
	(%Stages as ActionControl).configure(
		"ui.stage_select", ActionControl.IconKind.STAGES, ActionControl.VisualRole.WORLD)
	(%MainMenu as ActionControl).configure(
		"ui.main_menu", ActionControl.IconKind.HOME, ActionControl.VisualRole.WORLD)
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
	var compact := window_size.y < 480.0 or window_size.x < 760.0
	var density := 1.0 if get_viewport() is SubViewport else clampf(
		minf(viewport_size.x / maxf(window_size.x, 1.0),
				viewport_size.y / maxf(window_size.y, 1.0)), 1.0, 2.0)
	var resolved := density if compact else 1.0
	var content := $Center/Content as VBoxContainer
	var actions := %Actions as HBoxContainer
	var title := %Title as Label
	content.custom_minimum_size = Vector2(340.0, 132.0) * resolved \
			if compact else Vector2(420.0, 160.0)
	content.add_theme_constant_override(&"separation", roundi(18.0 * resolved) if compact else 28)
	actions.add_theme_constant_override(&"separation", roundi(14.0 * resolved) if compact else 20)
	title.add_theme_font_size_override(&"font_size", roundi(30.0 * resolved) if compact else 42)
	for action in [%Resume, %Restart, %Settings, %Stages, %MainMenu]:
		var control := action as ActionControl
		control.set_compact(compact, resolved)
		control.set_icon_width(28.0 if compact else 32.0)
		var edge := (48.0 if compact else 56.0) * resolved
		control.custom_minimum_size = Vector2(edge, edge)


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
