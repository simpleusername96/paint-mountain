extends SceneTree

const TEST_PATH := "user://paint_mountain_save_v6_migration_test.json"

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node("/root/SaveSystem")
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false

	var v5_data: Dictionary = save_system.default_data()
	v5_data["version"] = 5
	v5_data["best_results"] = {
		"stage_01": {
			"coverage": 42.5,
			"stars": 2,
			"coverage_metric_version": TargetSurfaceCoverage.METRIC_VERSION,
		},
	}
	v5_data["legacy_best_results"] = {"stage_02": {"coverage": 18.0}}
	_write_fixture(v5_data)
	var migrated: Dictionary = save_system.load_data(TEST_PATH)
	_assert(int(migrated.get("version", -1)) == 6, "v5 save must migrate to v6")
	_assert(Dictionary(migrated.get("best_results", {})).is_empty(), "v5 scalar bests must not become target-band clears")
	var legacy: Dictionary = migrated.get("legacy_best_results", {})
	_assert(legacy.has("stage_01") and legacy.has("stage_02"), "migration must merge old and existing legacy bests")

	game_state.initialize_from_data(migrated)
	var failed_result := _target_result(false, 9.0, 2, 4, 120)
	_assert(not game_state.complete_target_band_stage(&"stage_01", failed_result, false), "failed result must not persist")
	_assert(game_state.best_for(&"stage_01").is_empty(), "failed result must leave best empty")

	var first_clear := _target_result(true, 8.0, 2, 4, 120)
	_assert(game_state.complete_target_band_stage(&"stage_01", first_clear, false), "first clear must persist")
	var first_best: Dictionary = game_state.best_for(&"stage_01")
	_assert(String(first_best.get("rule_kind", "")) == "target_band", "new best must declare target-band rule")
	_assert(is_equal_approx(float(first_best.get("distance_to_center", -1.0)), 1.0), "distance must use target center")

	var lower_grade := _target_result(true, 9.0, 1, 1, 20)
	_assert(not game_state.complete_target_band_stage(&"stage_01", lower_grade, false), "lower grade must not replace a clear")
	var better_accuracy := _target_result(true, 9.0, 2, 5, 180)
	_assert(game_state.complete_target_band_stage(&"stage_01", better_accuracy, false), "equal grade with smaller error must replace")
	var fewer_shots := _target_result(true, 9.0, 2, 3, 200)
	_assert(game_state.complete_target_band_stage(&"stage_01", fewer_shots, false), "equal grade/error with fewer shots must replace")
	var faster := _target_result(true, 9.0, 2, 3, 80)
	_assert(game_state.complete_target_band_stage(&"stage_01", faster, false), "equal grade/error/shots with faster time must replace")
	var exact_tie := _target_result(true, 9.0, 2, 3, 80)
	_assert(not game_state.complete_target_band_stage(&"stage_01", exact_tie, false), "exact tie must preserve stable existing record")

	_assert(save_system.save_data(game_state.export_data(), TEST_PATH) == OK, "v6 save must write")
	var round_trip: Dictionary = save_system.load_data(TEST_PATH)
	var saved_best: Dictionary = Dictionary(round_trip.get("best_results", {})).get("stage_01", {})
	_assert(int(saved_best.get("result_schema_version", -1)) == SaveSystem.RESULT_SCHEMA_VERSION, "v6 result schema must survive round trip")
	_assert(int(Dictionary(saved_best.get("metadata", {})).get("shots_used", -1)) == 3, "best metadata must survive round trip")

	_cleanup()
	if not _failed:
		print("save_v6_migration_test passed: legacy archival and target-band best ranking")
	quit(1 if _failed else 0)


func _target_result(cleared: bool, score: float, stars: int, shots: int, ticks: int) -> Dictionary:
	return {
		"cleared": cleared,
		"score_rule_version": 1,
		"coverage_metric_version": TargetSurfaceCoverage.METRIC_VERSION,
		"stars": stars,
		"paint_score": score,
		"target_min": 7.0,
		"target_max": 11.0,
		"red_percent": 3.0,
		"green_percent": 6.0,
		"total_percent": 9.0,
		"deal_seed": 17,
		"shots_used": shots,
		"elapsed_ticks": ticks,
		"ticks_per_second": 60,
		"finish_reason": "manual",
	}


func _write_fixture(data: Dictionary) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	_assert(file != null, "v5 fixture must open")
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()


func _cleanup() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_PATH)
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(absolute_path + suffix):
			DirAccess.remove_absolute(absolute_path + suffix)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Save v6 migration check failed: %s" % message)
