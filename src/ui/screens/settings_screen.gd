class_name SettingsScreen
extends CanvasLayer

signal close_requested

var _controls: Dictionary = {}
var _syncing := false


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
	_setup_options()
	_connect_controls()
	%Defaults.pressed.connect(_restore_defaults)
	%Close.pressed.connect(_close)
	get_node("/root/GameState").settings_changed.connect(_on_settings_changed)
	visible = false


func open() -> void:
	_sync_from_state()
	visible = true
	%Close.grab_focus.call_deferred()


func _setup_options() -> void:
	_add_options(%Resolution, ["1280x720", "1600x900", "1920x1080"])
	_add_options(%Quality, ["low", "medium", "high"])
	_add_options(%Language, ["ko", "en"])
	_refresh_language_option_labels()


func _add_options(option: OptionButton, values: Array[String]) -> void:
	option.clear()
	for value in values:
		option.add_item(value.to_upper())
		option.set_item_metadata(option.item_count - 1, value)


func _connect_controls() -> void:
	for key in [&"master_volume", &"music_volume", &"sfx_volume"]:
		(_controls[key] as HSlider).value_changed.connect(func(value: float) -> void: _store(key, value / 100.0))
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


func _store(key: StringName, value) -> void:
	if _syncing:
		return
	var game_state := get_node("/root/GameState")
	if key == &"language":
		game_state.update_setting(&"language_user_selected", true, false)
	if game_state.update_setting(key, value):
		_apply_setting(key, value)


func _apply_setting(key: StringName, value) -> void:
	match key:
		&"master_volume": _set_bus_volume("Master", float(value))
		&"music_volume": _set_bus_volume("Music", float(value))
		&"sfx_volume": _set_bus_volume("SFX", float(value))
		&"fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(value) else DisplayServer.WINDOW_MODE_WINDOWED)
		&"resolution":
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				var parts := String(value).split("x")
				if parts.size() == 2:
					DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
		&"quality": get_viewport().scaling_3d_scale = 0.75 if value == "low" else (1.0 if value == "medium" else 1.15)


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
	_refresh_language_option_labels()
	_sync_from_state()


func _refresh_language_option_labels() -> void:
	if not is_instance_valid(%Language):
		return
	for index in range(%Language.item_count):
		%Language.set_item_text(index, tr("settings.korean") if %Language.get_item_metadata(index) == "ko" else tr("settings.english"))


func _on_settings_changed(_settings: Dictionary) -> void:
	_refresh_language_option_labels()


func _close() -> void:
	visible = false
	close_requested.emit()
