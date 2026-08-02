class_name SettingsScreen
extends CanvasLayer

signal close_requested

var _controls: Dictionary = {}
var _syncing: bool = false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open() -> void:
	_sync_from_state()
	visible = true
	var close_button := get_node_or_null("SettingsRoot/Panel/Margin/Content/Footer/Close")
	if close_button != null:
		close_button.grab_focus.call_deferred()


func _build() -> void:
	var root := Control.new()
	root.name = "SettingsRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.035, 0.06, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := UIFactory.panel(Vector2(1120.0, 850.0), Color(0.98, 0.97, 0.94, 0.98), 26)
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -560.0
	panel.offset_right = 560.0
	panel.offset_top = -425.0
	panel.offset_bottom = 425.0
	root.add_child(panel)
	var margin := UIFactory.margin(panel, Vector4(48, 38, 48, 38))
	margin.name = "Margin"
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 20)
	margin.add_child(content)
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var title := UIFactory.label("SETTINGS", 40, UIFactory.NAVY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	title_row.add_child(UIFactory.label("CHANGES SAVE AUTOMATICALLY", 14, UIFactory.MUTED))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 54)
	content.add_child(columns)
	var audio_column := _settings_column("AUDIO")
	columns.add_child(audio_column)
	_add_slider(audio_column, "MASTER VOLUME", &"master_volume")
	_add_slider(audio_column, "MUSIC VOLUME", &"music_volume")
	_add_slider(audio_column, "SOUND EFFECTS", &"sfx_volume")
	audio_column.add_child(_section_heading("GAMEPLAY"))
	_add_toggle(audio_column, "CAMERA SHAKE", &"camera_shake")
	_add_toggle(audio_column, "FOLLOW CAMERA", &"follow_camera")
	_add_toggle(audio_column, "TRAJECTORY PREVIEW", &"trajectory_preview")

	var display_column := _settings_column("DISPLAY")
	columns.add_child(display_column)
	_add_toggle(display_column, "FULLSCREEN", &"fullscreen")
	_add_option(display_column, "RESOLUTION", &"resolution", ["1280x720", "1600x900", "1920x1080"])
	_add_option(display_column, "GRAPHICS QUALITY", &"quality", ["low", "medium", "high"])
	display_column.add_child(_section_heading("LANGUAGE"))
	_add_option(display_column, "INTERFACE LANGUAGE", &"language", ["en"])
	var language_note := UIFactory.label("English is the initial language. The saved key and selector are ready for additional locales.", 15, UIFactory.MUTED)
	language_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	display_column.add_child(language_note)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 14)
	content.add_child(footer)
	var defaults := UIFactory.button("RESTORE DEFAULTS", false, Vector2(250.0, 58.0))
	defaults.pressed.connect(_restore_defaults)
	footer.add_child(defaults)
	var close := UIFactory.button("CLOSE", true, Vector2(190.0, 58.0))
	close.name = "Close"
	close.pressed.connect(func() -> void:
		visible = false
		close_requested.emit()
	)
	footer.add_child(close)


func _settings_column(title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 485.0
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	column.add_child(_section_heading(title))
	return column


func _section_heading(text: String) -> Label:
	var result := UIFactory.label(text, 18, UIFactory.BLUE)
	result.custom_minimum_size.y = 42.0
	return result


func _add_slider(parent: VBoxContainer, caption: String, key: StringName) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var caption_row := HBoxContainer.new()
	row.add_child(caption_row)
	caption_row.add_child(UIFactory.label(caption, 16, UIFactory.CHARCOAL))
	var value_label := UIFactory.label("80%", 16, UIFactory.NAVY)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption_row.add_child(value_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.custom_minimum_size.y = 34.0
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%d%%" % roundi(value)
		_store(key, value / 100.0)
	)
	row.add_child(slider)
	_controls[key] = slider


func _add_toggle(parent: VBoxContainer, caption: String, key: StringName) -> void:
	var toggle := CheckButton.new()
	toggle.text = caption
	toggle.custom_minimum_size.y = 48.0
	toggle.add_theme_font_size_override("font_size", 16)
	toggle.add_theme_color_override("font_color", UIFactory.CHARCOAL)
	toggle.add_theme_color_override("font_pressed_color", UIFactory.CHARCOAL)
	toggle.add_theme_color_override("font_hover_color", UIFactory.NAVY)
	toggle.add_theme_color_override("font_hover_pressed_color", UIFactory.NAVY)
	toggle.add_theme_color_override("font_focus_color", UIFactory.NAVY)
	toggle.toggled.connect(func(value: bool) -> void: _store(key, value))
	parent.add_child(toggle)
	_controls[key] = toggle


func _add_option(parent: VBoxContainer, caption: String, key: StringName, values: Array[String]) -> void:
	parent.add_child(UIFactory.label(caption, 16, UIFactory.CHARCOAL))
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(0.0, 50.0)
	option.add_theme_font_size_override("font_size", 16)
	for value in values:
		option.add_item(value.to_upper())
		option.set_item_metadata(option.item_count - 1, value)
	option.item_selected.connect(func(index: int) -> void: _store(key, option.get_item_metadata(index)))
	parent.add_child(option)
	_controls[key] = option


func _sync_from_state() -> void:
	_syncing = true
	var game_state := get_node("/root/GameState")
	for key in _controls:
		var control: Control = _controls[key]
		var value = game_state.settings.get(String(key))
		if control is HSlider:
			control.value = float(value) * 100.0
		elif control is CheckButton:
			control.button_pressed = bool(value)
		elif control is OptionButton:
			for index in range(control.item_count):
				if control.get_item_metadata(index) == value:
					control.select(index)
					break
	_syncing = false


func _store(key: StringName, value) -> void:
	if _syncing:
		return
	var game_state := get_node("/root/GameState")
	if game_state.update_setting(key, value):
		_apply_setting(key, value)


func _apply_setting(key: StringName, value) -> void:
	match key:
		&"master_volume":
			_set_bus_volume("Master", float(value))
		&"music_volume":
			_set_bus_volume("Music", float(value))
		&"sfx_volume":
			_set_bus_volume("SFX", float(value))
		&"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(value) else DisplayServer.WINDOW_MODE_WINDOWED)
		&"resolution":
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				var parts := String(value).split("x")
				if parts.size() == 2:
					DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
		&"quality":
			get_viewport().scaling_3d_scale = 0.75 if value == "low" else (1.0 if value == "medium" else 1.15)


func _set_bus_volume(bus_name: String, normalized: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(normalized, 0.001)))
		AudioServer.set_bus_mute(index, normalized <= 0.001)


func _restore_defaults() -> void:
	var game_state := get_node("/root/GameState")
	var defaults: Dictionary = get_node("/root/SaveSystem").default_data().settings
	for key in defaults:
		game_state.update_setting(StringName(key), defaults[key], false)
		_apply_setting(StringName(key), defaults[key])
	game_state.save_now()
	_sync_from_state()
