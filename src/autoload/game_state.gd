extends Node

signal progression_changed
signal settings_changed(settings: Dictionary)

var selected_stage_id: StringName = &"first_descent"
var unlocked_stages: Array[StringName] = [&"first_descent"]
var best_results: Dictionary = {}
var settings: Dictionary = {}
var persistence_enabled: bool = true


func _ready() -> void:
	initialize_from_data(_save_system().load_data())


func initialize_from_data(data: Dictionary) -> void:
	unlocked_stages.clear()
	for stage_id in data.get("unlocked_stages", ["first_descent"]):
		unlocked_stages.append(StringName(stage_id))
	if not unlocked_stages.has(&"first_descent"):
		unlocked_stages.push_front(&"first_descent")
	best_results = Dictionary(data.get("best_results", {})).duplicate(true)
	settings = Dictionary(data.get("settings", _save_system().default_data().settings)).duplicate(true)
	if not unlocked_stages.has(selected_stage_id):
		selected_stage_id = &"first_descent"


func select_stage(stage_id: StringName) -> bool:
	if not unlocked_stages.has(stage_id) or StageCatalog.get_stage(stage_id) == null:
		return false
	selected_stage_id = stage_id
	return true


func complete_stage(stage_id: StringName, coverage: float, stars: int, persist: bool = true) -> void:
	var key := String(stage_id)
	var previous: Dictionary = best_results.get(key, {})
	best_results[key] = {
		"coverage": maxf(coverage, float(previous.get("coverage", 0.0))),
		"stars": maxi(stars, int(previous.get("stars", 0))),
	}
	var next_id := StageCatalog.next_stage_id(stage_id)
	if not next_id.is_empty() and not unlocked_stages.has(next_id):
		unlocked_stages.append(next_id)
	progression_changed.emit()
	if persist and persistence_enabled:
		save_now()


func best_for(stage_id: StringName) -> Dictionary:
	return Dictionary(best_results.get(String(stage_id), {}))


func update_setting(key: StringName, value, persist: bool = true) -> bool:
	if not settings.has(String(key)):
		return false
	settings[String(key)] = value
	settings_changed.emit(settings.duplicate(true))
	if persist and persistence_enabled:
		save_now()
	return true


func save_now() -> Error:
	return _save_system().save_data(export_data())


func export_data() -> Dictionary:
	var unlocked: Array[String] = []
	for stage_id in unlocked_stages:
		unlocked.append(String(stage_id))
	return {
		"version": 1,
		"unlocked_stages": unlocked,
		"best_results": best_results.duplicate(true),
		"settings": settings.duplicate(true),
	}


func _save_system() -> Node:
	return get_node("/root/SaveSystem")
