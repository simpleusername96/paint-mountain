extends Node

signal progression_changed
signal settings_changed(settings: Dictionary)

var selected_stage_id: StringName = &"stage_01"
var unlocked_stages: Array[StringName] = StageCatalog.all_stage_ids()
var best_results: Dictionary = {}
var settings: Dictionary = {}
var persistence_enabled: bool = true


func _ready() -> void:
	initialize_from_data(_save_system().load_data())


func initialize_from_data(data: Dictionary) -> void:
	unlocked_stages = StageCatalog.all_stage_ids()
	var persisted_selected := StageCatalog.canonical_id(
		StringName(data.get("selected_stage_id", "stage_01"))
	)
	selected_stage_id = persisted_selected if StageCatalog.get_stage(persisted_selected) != null else &"stage_01"
	best_results = Dictionary(data.get("best_results", {})).duplicate(true)
	settings = Dictionary(data.get("settings", _save_system().default_data().settings)).duplicate(true)
	TranslationServer.set_locale(String(settings.get("language", "ko")))


func select_stage(stage_id: StringName) -> bool:
	var canonical_stage_id := StageCatalog.canonical_id(stage_id)
	if StageCatalog.get_stage(canonical_stage_id) == null:
		return false
	selected_stage_id = canonical_stage_id
	return true


func complete_stage(stage_id: StringName, coverage: float, stars: int, persist: bool = true) -> void:
	var key := String(StageCatalog.canonical_id(stage_id))
	var previous: Dictionary = best_results.get(key, {})
	best_results[key] = {
		"coverage": maxf(coverage, float(previous.get("coverage", 0.0))),
		"stars": maxi(stars, int(previous.get("stars", 0))),
	}
	var next_id := StageCatalog.next_stage_id(StringName(key))
	progression_changed.emit()
	if persist and persistence_enabled:
		save_now()


func best_for(stage_id: StringName) -> Dictionary:
	return Dictionary(best_results.get(String(StageCatalog.canonical_id(stage_id)), {}))


func update_setting(key: StringName, value, persist: bool = true) -> bool:
	if not settings.has(String(key)):
		return false
	settings[String(key)] = value
	if key == &"language":
		TranslationServer.set_locale(String(value))
	settings_changed.emit(settings.duplicate(true))
	if persist and persistence_enabled:
		save_now()
	return true


func save_now() -> Error:
	return _save_system().save_data(export_data())


func export_data() -> Dictionary:
	return {
		"version": 3,
		"selected_stage_id": String(selected_stage_id),
		"best_results": best_results.duplicate(true),
		"settings": settings.duplicate(true),
	}


func _save_system() -> Node:
	return get_node("/root/SaveSystem")
