extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const TEST_SAVE_PATH := "user://paint_mountain_phase6_test.json"

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	_cleanup_test_saves()
	var save_system := root.get_node("/root/SaveSystem")
	var game_state := root.get_node("/root/GameState")
	var stages := StageCatalog.all_stages()
	_assert_true(stages.size() == 3, "catalog must expose exactly three stages")
	_assert_true(stages[0].mechanism_loadout.size() == 0, "First Descent must have no mechanisms")
	_assert_true(stages[1].mechanism_loadout.size() == 1 and stages[1].mechanism_loadout[0].kind == MechanismData.Kind.BURST, "Burst Basin must request one generated Burst")
	_assert_true(stages[2].mechanism_loadout.size() == 2, "Split Ridge must request exactly two generated mechanisms")
	_assert_true(stages[2].target_coverage == 70.0, "Split Ridge target must remain 70 percent")
	for stage in stages:
		_assert_true(not stage.reliable_solution.is_empty(), "%s must contain a recorded solution sequence" % stage.display_name_key)

	var sample_save: Dictionary = save_system.default_data()
	sample_save.unlocked_stages = ["first_descent", "burst_basin"]
	sample_save.best_results = {"first_descent": {"coverage": 24.5, "stars": 2}}
	_assert_true(save_system.save_data(sample_save, TEST_SAVE_PATH) == OK, "versioned save must write atomically")
	var loaded: Dictionary = save_system.load_data(TEST_SAVE_PATH)
	_assert_true(loaded.unlocked_stages.size() == 2, "saved unlocks must load")
	_assert_true(is_equal_approx(float(loaded.best_results.first_descent.coverage), 24.5), "best coverage must survive reload")

	var invalid := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	invalid.store_string("{not-valid-json")
	invalid.close()
	var fallback: Dictionary = save_system.load_data(TEST_SAVE_PATH)
	_assert_true(fallback.unlocked_stages == ["first_descent"], "invalid save must fall back without blocking play")

	game_state.initialize_from_data(save_system.default_data())
	game_state.complete_stage(&"first_descent", 22.0, 1, false)
	_assert_true(game_state.unlocked_stages.has(&"burst_basin"), "clearing stage one must unlock stage two")
	game_state.complete_stage(&"burst_basin", 40.0, 1, false)
	_assert_true(game_state.unlocked_stages.has(&"split_ridge"), "clearing stage two must unlock stage three")
	_assert_true(game_state.select_stage(&"split_ridge"), "unlocked Split Ridge must be selectable")

	var recorder := ReplayRecorder.new()
	root.add_child(recorder)
	recorder.start_attempt(stages[2], 3001)
	recorder.record_aim(-12.0, 39.0, 72.0)
	recorder.record_fire()
	recorder.record_aim(3.0, 44.0, 76.0)
	recorder.record_fire()
	var serialized := JSON.stringify(recorder.export_attempt())
	var restored_data = JSON.parse_string(serialized)
	var restored := ReplayRecorder.new()
	root.add_child(restored)
	_assert_true(restored.load_attempt(restored_data), "versioned replay must reload from serialized data")
	var replay_observation := {"actions": []}
	restored.replay_action_ready.connect(func(action: Dictionary) -> void: replay_observation.actions.append(action))
	_assert_true(restored.emit_next_action(), "replay play must emit its first stored action")
	restored.set_playback_paused(true)
	_assert_true(not restored.emit_next_action(), "paused replay must not advance")
	restored.set_playback_paused(false)
	restored.set_playback_speed(2.0)
	_assert_true(restored.playback_speed == 2.0 and restored.emit_next_action(), "replay must support 2x and resume")
	_assert_true(replay_observation.actions.size() == 2, "replay must preserve ordered actions")
	restored.reset_playback()
	_assert_true(restored.playback_index == 0 and restored.playback_speed == 1.0, "replay restart must restore index and speed")

	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var agent: GameplayAgentApi = gameplay.get_node("GameplayAgentApi")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var observation := agent.get_observation()
	_assert_true(observation.stage_id == "split_ridge", "gameplay must load the selected StageData resource")
	_assert_true(observation.mechanisms.size() == 2, "agent observation must expose placed mechanism state")
	_assert_true(observation.terrain_height_grid.size() == 9 and observation.terrain_height_grid[0].size() == 13, "agent observation must expose a bounded terrain grid")
	_assert_true(not observation.ready_for_action, "briefing must not accept an agent shot")
	_assert_true(controller.begin_aiming(), "agent test must enter the shared aiming state")
	_assert_true(agent.set_aim(-12.0, 39.0, 72.0), "agent set_aim must use the ready cannon command")
	_assert_true(agent.fire(), "agent fire must enter the same validated StageController path")
	_assert_true(not agent.fire(), "agent cannot bypass the active-shot fire guard")
	agent.restart()
	_assert_true(manager.active_count() == 0 and controller.current_state == StageController.State.AIMING, "agent restart must perform the normal clean retry")

	if not _failed:
		print("Phase 6 content checks passed: 3 stages, atomic save fallback, 2-shot replay, and UI-independent agent actions.")
	paused = false
	gameplay.queue_free()
	_cleanup_test_saves()
	quit(1 if _failed else 0)


func _cleanup_test_saves() -> void:
	var user_directory := DirAccess.open("user://")
	if user_directory == null:
		return
	for file_name in user_directory.get_files():
		if file_name.begins_with("paint_mountain_phase6_test.json"):
			user_directory.remove(file_name)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
