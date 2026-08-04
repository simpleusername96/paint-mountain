extends Node

const SAVE_VERSION := 3
const DEFAULT_SAVE_PATH := "user://paint_mountain_save.json"


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"selected_stage_id": "first_descent",
		"best_results": {},
		"settings": {
			"master_volume": 0.8,
			"music_volume": 0.7,
			"sfx_volume": 0.85,
			"camera_shake": true,
			"follow_camera": true,
			"trajectory_preview": true,
			"fast_progress": true,
			"fullscreen": false,
			"resolution": "1920x1080",
			"quality": "medium",
			"language": "ko",
			"language_user_selected": false,
		},
	}


func load_data(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_data()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_data()
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	var parsed = parser.data
	if parse_error != OK or not parsed is Dictionary:
		_preserve_invalid(path)
		return default_data()
	if int(parsed.get("version", -1)) == 1 or int(parsed.get("version", -1)) == 2:
		parsed = _migrate_v1(parsed)
	elif int(parsed.get("version", -1)) != SAVE_VERSION:
		_preserve_invalid(path)
		return default_data()
	return _merge_with_defaults(parsed)


func save_data(data: Dictionary, path: String = DEFAULT_SAVE_PATH) -> Error:
	var payload := _merge_with_defaults(data)
	payload["version"] = SAVE_VERSION
	var absolute_path := ProjectSettings.globalize_path(path)
	var temporary_path := absolute_path + ".tmp"
	var backup_path := absolute_path + ".bak"
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(absolute_path):
		var backup_error := DirAccess.rename_absolute(absolute_path, backup_path)
		if backup_error != OK:
			DirAccess.remove_absolute(temporary_path)
			return backup_error
	var replace_error := DirAccess.rename_absolute(temporary_path, absolute_path)
	if replace_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, absolute_path)
		return replace_error
	return OK


func _merge_with_defaults(data: Dictionary) -> Dictionary:
	var merged := default_data()
	merged["selected_stage_id"] = data.get("selected_stage_id", merged.selected_stage_id)
	merged["best_results"] = data.get("best_results", merged.best_results)
	var incoming_settings: Dictionary = data.get("settings", {})
	var settings: Dictionary = merged.settings
	for key in incoming_settings:
		if settings.has(key):
			settings[key] = incoming_settings[key]
	merged["settings"] = settings
	return merged


func _migrate_v1(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var migrated_settings: Dictionary = Dictionary(migrated.get("settings", {})).duplicate(true)
	migrated_settings["language"] = "ko"
	migrated_settings["language_user_selected"] = false
	migrated["settings"] = migrated_settings
	var selected := String(migrated.get("selected_stage_id", "first_descent"))
	if selected == "stage_01":
		selected = "first_descent"
	migrated["selected_stage_id"] = selected
	migrated["version"] = SAVE_VERSION
	return migrated


func _preserve_invalid(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var invalid_path := "%s.invalid-%s" % [absolute_path, timestamp]
	DirAccess.rename_absolute(absolute_path, invalid_path)
