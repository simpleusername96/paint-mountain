extends Node

signal progression_changed
signal settings_changed(settings: Dictionary)

var selected_stage_id: StringName = &"stage_01"
var unlocked_stages: Array[StringName] = StageCatalog.all_stage_ids()
var best_results: Dictionary = {}
var legacy_best_results: Dictionary = {}
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
	legacy_best_results = Dictionary(data.get("legacy_best_results", {})).duplicate(true)
	settings = Dictionary(data.get("settings", _save_system().default_data().settings)).duplicate(true)
	TranslationServer.set_locale(String(settings.get("language", "ko")))


func select_stage(stage_id: StringName) -> bool:
	var canonical_stage_id := StageCatalog.canonical_id(stage_id)
	if StageCatalog.get_stage(canonical_stage_id) == null:
		return false
	selected_stage_id = canonical_stage_id
	return true


func complete_stage(
		stage_id: StringName,
		coverage: float,
		stars: int,
		persist: bool = true,
		result_metadata: Dictionary = {}
) -> void:
	var key := String(StageCatalog.canonical_id(stage_id))
	var previous: Dictionary = best_results.get(key, {})
	var is_strictly_better := not best_results.has(key) \
			or coverage > float(previous.get("coverage", 0.0))
	if is_strictly_better:
		var best_result := {
			"result_schema_version": SaveSystem.RESULT_SCHEMA_VERSION,
			"rule_kind": "legacy_coverage",
			"coverage": coverage,
			"stars": stars,
			"coverage_metric_version": TargetSurfaceCoverage.METRIC_VERSION,
		}
		if not result_metadata.is_empty():
			best_result["metadata"] = {
				"elapsed_seconds": maxf(float(result_metadata.get("elapsed_seconds", 0.0)), 0.0),
				"shots_used": maxi(int(result_metadata.get("shots_used", 0)), 0),
				"finish_reason": String(result_metadata.get("finish_reason", "")),
			}
		best_results[key] = best_result
	progression_changed.emit()
	if persist and persistence_enabled:
		save_now()


## Persists only verified target-band clears. Ranking favors grade and accuracy,
## then resource use; an exact tie keeps the stable existing record.
func complete_target_band_stage(
		stage_id: StringName,
		result: Dictionary,
		persist: bool = true
) -> bool:
	if not bool(result.get("cleared", false)):
		return false
	var key := String(StageCatalog.canonical_id(stage_id))
	var candidate := _target_band_best_entry(result)
	if candidate.is_empty():
		return false
	var previous: Dictionary = best_results.get(key, {})
	if not previous.is_empty() and not _target_band_result_is_better(candidate, previous):
		return false
	best_results[key] = candidate
	progression_changed.emit()
	if persist and persistence_enabled:
		save_now()
	return true


func best_for(stage_id: StringName) -> Dictionary:
	var canonical_id := StageCatalog.canonical_id(stage_id)
	var entry := Dictionary(best_results.get(String(canonical_id), {}))
	var stage := StageCatalog.get_stage(canonical_id)
	if entry.is_empty() or stage == null:
		return entry
	# A valid scalar record from the former Stage 07-30 rule remains preserved in
	# save data, but it is not a Paint Score and must never be shown as one.
	var expected_rule := "target_band" if stage.uses_target_band() else "legacy_coverage"
	return entry if String(entry.get("rule_kind", "")) == expected_rule else {}


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
		"version": SaveSystem.SAVE_VERSION,
		"selected_stage_id": String(selected_stage_id),
		"coverage_metric_version": TargetSurfaceCoverage.METRIC_VERSION,
		"best_results": best_results.duplicate(true),
		"legacy_best_results": legacy_best_results.duplicate(true),
		"settings": settings.duplicate(true),
	}


func _target_band_best_entry(result: Dictionary) -> Dictionary:
	var target_min := float(result.get("target_min", 0.0))
	var target_max := float(result.get("target_max", 0.0))
	var paint_score := float(result.get("paint_score", 0.0))
	if target_min >= target_max or paint_score < target_min - 0.0001 \
			or paint_score > target_max + 0.0001:
		return {}
	var center := (target_min + target_max) * 0.5
	var ticks_per_second := maxi(int(result.get("ticks_per_second", Engine.physics_ticks_per_second)), 1)
	var elapsed_seconds := maxf(
		float(result.get("elapsed_ticks", 0)) / float(ticks_per_second),
		0.0
	)
	return {
		"result_schema_version": SaveSystem.RESULT_SCHEMA_VERSION,
		"rule_kind": "target_band",
		"score_rule_version": int(result.get("score_rule_version", 1)),
		"coverage_metric_version": int(
			result.get("coverage_metric_version", TargetSurfaceCoverage.METRIC_VERSION)
		),
		"stars": clampi(int(result.get("stars", 0)), 1, 3),
		"paint_score": paint_score,
		"target_min": target_min,
		"target_max": target_max,
		"distance_to_center": absf(paint_score - center),
		"red_percent": maxf(float(result.get("red_percent", 0.0)), 0.0),
		"green_percent": maxf(float(result.get("green_percent", 0.0)), 0.0),
		"total_percent": maxf(float(result.get("total_percent", 0.0)), 0.0),
		"deal_seed": int(result.get("deal_seed", 0)),
		"metadata": {
			"elapsed_seconds": elapsed_seconds,
			"shots_used": maxi(int(result.get("shots_used", 0)), 0),
			"finish_reason": String(result.get("finish_reason", "")),
		},
	}


func _target_band_result_is_better(candidate: Dictionary, previous: Dictionary) -> bool:
	if String(previous.get("rule_kind", "")) != "target_band":
		return true
	var candidate_stars := int(candidate.get("stars", 0))
	var previous_stars := int(previous.get("stars", 0))
	if candidate_stars != previous_stars:
		return candidate_stars > previous_stars
	var candidate_error := float(candidate.get("distance_to_center", INF))
	var previous_error := float(previous.get("distance_to_center", INF))
	if not is_equal_approx(candidate_error, previous_error):
		return candidate_error < previous_error
	var candidate_metadata := Dictionary(candidate.get("metadata", {}))
	var previous_metadata := Dictionary(previous.get("metadata", {}))
	var candidate_shots := int(candidate_metadata.get("shots_used", 2_147_483_647))
	var previous_shots := int(previous_metadata.get("shots_used", 2_147_483_647))
	if candidate_shots != previous_shots:
		return candidate_shots < previous_shots
	var candidate_time := float(candidate_metadata.get("elapsed_seconds", INF))
	var previous_time := float(previous_metadata.get("elapsed_seconds", INF))
	return candidate_time < previous_time and not is_equal_approx(candidate_time, previous_time)


func _save_system() -> Node:
	return get_node("/root/SaveSystem")
