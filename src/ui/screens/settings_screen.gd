class_name SettingsScreen
extends CanvasLayer

signal close_requested

var _controls: Dictionary = {}
var _volume_values: Dictionary = {}
var _syncing := false
var _display_mutation_count := 0
@onready var _columns_layout: Control = %Layout
@onready var _audio_column: VBoxContainer = %Audio
@onready var _display_column: VBoxContainer = %Display


func _ready() -> void:
	_controls = {
		&"master_volume": %Master,
		&"music_volume": %Music,
		&"sfx_volume": %Sfx,
		&"camera_shake": %CameraShake,
		&"reduced_motion": %ReducedMotion,
		&"trajectory_preview": %Trajectory,
		&"fullscreen": %Fullscreen,
		&"resolution": %Resolution,
		&"quality": %Quality,
		&"language": %Language,
	}
	_volume_values = {
		&"master_volume": %MasterValue,
		&"music_volume": %MusicValue,
		&"sfx_volume": %SfxValue,
	}
	_setup_options()
	_connect_controls()
	%Defaults.pressed.connect(_restore_defaults)
	%Close.pressed.connect(_close)
	get_node("/root/GameState").settings_changed.connect(_on_settings_changed)
	get_viewport().size_changed.connect(_queue_responsive_layout)
	_apply_display_settings_from_state()
	visible = false
	_queue_responsive_layout()


func open() -> void:
	_sync_from_state()
	visible = true
	_queue_responsive_layout()
	%Close.grab_focus.call_deferred()


func _queue_responsive_layout() -> void:
	_apply_responsive_layout.call_deferred()


## The scroll view owns overflow. The same controls remain in tree order, then
## are positioned as two columns only when their minimum readable width fits.
func _apply_responsive_layout() -> void:
	if not is_instance_valid(_columns_layout):
		return
	var available_width := maxf(_columns_layout.get_parent_control().size.x, 1.0)
	var viewport_size := get_viewport().get_visible_rect().size
	var responsive_size := _responsive_window_size(viewport_size)
	var compact := responsive_size.x < 1040.0 or responsive_size.y < 620.0
	var density := _display_density(viewport_size, responsive_size) if compact else 1.0
	_apply_control_density(compact, density)
	var wide_layout := responsive_size.x >= 1040.0
	var gutter := 52.0 if wide_layout else 0.0
	var column_width := (available_width - gutter) * 0.5 if wide_layout else available_width
	_audio_column.position = Vector2.ZERO
	_audio_column.size = Vector2(column_width, _audio_column.get_combined_minimum_size().y)
	if wide_layout:
		_display_column.position = Vector2(column_width + gutter, 0.0)
		_display_column.size = Vector2(column_width, _display_column.get_combined_minimum_size().y)
		_columns_layout.custom_minimum_size = Vector2(
			available_width,
			maxf(_audio_column.size.y, _display_column.size.y)
		)
	else:
		_display_column.position = Vector2(0.0, _audio_column.size.y + 24.0)
		_display_column.size = Vector2(column_width, _display_column.get_combined_minimum_size().y)
		_columns_layout.custom_minimum_size = Vector2(
			available_width,
			_display_column.position.y + _display_column.size.y
		)
	_columns_layout.size = _columns_layout.custom_minimum_size


func _responsive_window_size(fallback_size: Vector2) -> Vector2:
	if get_viewport() is SubViewport:
		return fallback_size
	var window_size := Vector2(DisplayServer.window_get_size())
	return window_size if window_size.x > 0.0 and window_size.y > 0.0 else fallback_size


func _display_density(viewport_size: Vector2, window_size: Vector2) -> float:
	if get_viewport() is SubViewport or window_size.x <= 0.0 or window_size.y <= 0.0:
		return 1.0
	return clampf(minf(viewport_size.x / window_size.x, viewport_size.y / window_size.y), 1.0, 2.0)


func _apply_control_density(compact: bool, density: float) -> void:
	var scale := maxf(density, 1.0) if compact else 1.0
	var margin := $SettingsRoot/Panel/Margin as MarginContainer
	var content := $SettingsRoot/Panel/Margin/Content as VBoxContainer
	var title := $SettingsRoot/Panel/Margin/Content/Header/Title as Label
	if compact:
		for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
			margin.add_theme_constant_override(side, roundi(12.0 * scale))
		content.add_theme_constant_override(&"separation", roundi(8.0 * scale))
		title.add_theme_font_size_override(&"font_size", roundi(22.0 * scale))
	else:
		margin.add_theme_constant_override(&"margin_left", 28)
		margin.add_theme_constant_override(&"margin_top", 22)
		margin.add_theme_constant_override(&"margin_right", 28)
		margin.add_theme_constant_override(&"margin_bottom", 20)
		content.add_theme_constant_override(&"separation", 16)
		title.remove_theme_font_size_override(&"font_size")
	for node in _columns_layout.find_children("*", "Control", true, false):
		var control := node as Control
		if control is Label:
			var font_size := 17.0 if control.theme_type_variation == &"HudAccentSection" else 15.0
			if compact:
				control.add_theme_font_size_override(&"font_size", roundi(font_size * scale))
			else:
				control.remove_theme_font_size_override(&"font_size")
		elif control is CheckButton or control is OptionButton:
			if compact:
				control.add_theme_font_size_override(&"font_size", roundi(15.0 * scale))
			else:
				control.remove_theme_font_size_override(&"font_size")
		if control is TextureRect:
			control.custom_minimum_size = Vector2(24.0, 24.0) * scale
		elif control is HSlider:
			control.custom_minimum_size.y = 38.0 * scale
		elif control is OptionButton:
			control.custom_minimum_size.y = 44.0 * scale
		elif control is HBoxContainer and control.name.to_lower().ends_with("row"):
			control.custom_minimum_size.y = 44.0 * scale
	var defaults := %Defaults as Button
	var close := %Close as Button
	defaults.custom_minimum_size = Vector2(220.0, 46.0) * scale
	close.custom_minimum_size = Vector2(160.0, 46.0) * scale
	for button in [defaults, close]:
		if compact:
			button.add_theme_font_size_override(&"font_size", roundi(16.0 * scale))
		else:
			button.remove_theme_font_size_override(&"font_size")


func _setup_options() -> void:
	_add_options(%Resolution, ["1280x720", "1600x900", "1920x1080"])
	_add_options(%Quality, ["low", "medium", "high"])
	_add_options(%Language, ["ko", "en"])
	_refresh_language_option_labels()


func _add_options(option: OptionButton, values: Array[String]) -> void:
	option.clear()
	for value in values:
		option.add_item(value)
		option.set_item_metadata(option.item_count - 1, value)


func _connect_controls() -> void:
	for key in [&"master_volume", &"music_volume", &"sfx_volume"]:
		(_controls[key] as HSlider).value_changed.connect(_on_volume_changed.bind(key))
	for key in [&"camera_shake", &"reduced_motion", &"trajectory_preview", &"fullscreen"]:
		(_controls[key] as CheckButton).toggled.connect(func(value: bool) -> void: _store(key, value))
	for key in [&"resolution", &"quality", &"language"]:
		var option := _controls[key] as OptionButton
		option.item_selected.connect(func(index: int) -> void: _store(key, option.get_item_metadata(index)))


func _sync_from_state() -> void:
	_syncing = true
	var settings: Dictionary = get_node("/root/GameState").settings
	for key in _controls:
		var control: Control = _controls[key]
		var value = settings.get(String(key))
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
	_sync_display_controls()
	_refresh_volume_values()


func _on_volume_changed(value: float, key: StringName) -> void:
	var value_label := _volume_values.get(key) as Label
	if value_label != null:
		value_label.text = "%d%%" % roundi(value)
	_store(key, value / 100.0)


func _refresh_volume_values() -> void:
	for key in _volume_values:
		var slider := _controls.get(key) as HSlider
		var value_label := _volume_values.get(key) as Label
		if slider != null and value_label != null:
			value_label.text = "%d%%" % roundi(slider.value)


func _store(key: StringName, value) -> void:
	if _syncing:
		return
	var game_state := get_node("/root/GameState")
	_syncing = true
	if key == &"language":
		game_state.update_setting(&"language_user_selected", true, false)
	var changed: bool = game_state.update_setting(key, value)
	_syncing = false
	if changed:
		_apply_setting(key, value)
		_sync_from_state()


func _apply_setting(key: StringName, value) -> void:
	match key:
		&"master_volume": _set_bus_volume("Master", float(value))
		&"music_volume": _set_bus_volume("Music", float(value))
		&"sfx_volume": _set_bus_volume("SFX", float(value))
		&"quality": get_viewport().scaling_3d_scale = 0.75 if value == "low" else (1.0 if value == "medium" else 1.15)
		&"fullscreen": _apply_fullscreen(bool(value))
		&"resolution":
			if not bool(get_node("/root/GameState").settings.get("fullscreen", false)):
				_apply_windowed_resolution(String(value))


func _set_bus_volume(bus_name: String, normalized: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(normalized, 0.001)))
		AudioServer.set_bus_mute(index, normalized <= 0.001)


func _restore_defaults() -> void:
	var game_state := get_node("/root/GameState")
	var defaults: Dictionary = get_node("/root/SaveSystem").default_data().settings
	_syncing = true
	for key in defaults:
		game_state.update_setting(StringName(key), defaults[key], false)
	_syncing = false
	for key in [&"master_volume", &"music_volume", &"sfx_volume", &"quality"]:
		_apply_setting(key, game_state.settings[String(key)])
	_apply_display_settings_from_state()
	game_state.save_now()
	_sync_from_state()


func _refresh_language_option_labels() -> void:
	if not is_instance_valid(%Language):
		return
	for index in range(%Language.item_count):
		%Language.set_item_text(index, tr("settings.korean") if %Language.get_item_metadata(index) == "ko" else tr("settings.english"))


## Passive synchronization must never resize or change the mode of the window.
## Only explicit display-setting actions call the DisplayServer helpers below.
func _sync_display_controls() -> void:
	var settings: Dictionary = get_node("/root/GameState").settings
	_refresh_language_option_labels()
	for index in range(%Quality.item_count):
		%Quality.set_item_text(index, tr("settings.quality_%s" % %Quality.get_item_metadata(index)))
	for index in range(%Resolution.item_count):
		var value := String(%Resolution.get_item_metadata(index))
		%Resolution.set_item_text(index, value.replace("x", " × "))
	var fullscreen := bool(settings.get("fullscreen", false))
	%Resolution.disabled = fullscreen


func _apply_display_settings_from_state() -> void:
	var settings: Dictionary = get_node("/root/GameState").settings
	_apply_fullscreen(bool(settings.get("fullscreen", false)))


func _apply_fullscreen(fullscreen: bool) -> void:
	var desired_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen \
			else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != desired_mode:
		DisplayServer.window_set_mode(desired_mode)
		_display_mutation_count += 1
	if not fullscreen:
		_apply_windowed_resolution(String(
			get_node("/root/GameState").settings.get("resolution", "1280x720")
		))


func _apply_windowed_resolution(value: String) -> void:
	var parts := value.split("x")
	if parts.size() == 2:
		var requested_size := Vector2i(int(parts[0]), int(parts[1]))
		if DisplayServer.window_get_size() != requested_size:
			DisplayServer.window_set_size(requested_size)
			_display_mutation_count += 1


func display_mutation_count() -> int:
	return _display_mutation_count


func _on_settings_changed(_settings: Dictionary) -> void:
	if not _syncing:
		_sync_from_state()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed(&"ui_cancel"):
		return
	if event is InputEventKey and event.echo:
		return
	get_viewport().set_input_as_handled()
	_close()


func _close() -> void:
	visible = false
	close_requested.emit()
