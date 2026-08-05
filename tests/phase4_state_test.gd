extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.time_scale = 2.0
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.select_stage(&"first_descent")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame

	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var paint_system := gameplay.get_node("PaintSystem") as PaintSystem
	var finished_results: Array[Dictionary] = []
	var observed_states: Array[int] = []
	var legacy_terminal_events: Array[StringName] = []
	controller.state_changed.connect(
		func(state: int, _previous: int) -> void: observed_states.append(state)
	)
	controller.stage_finished.connect(
		func(result: Dictionary) -> void: finished_results.append(result)
	)
	controller.stage_cleared.connect(
		func(_coverage: float, _shots: int) -> void: legacy_terminal_events.append(&"clear")
	)
	controller.stage_failed.connect(
		func(_coverage: float, _missing: float) -> void: legacy_terminal_events.append(&"failed")
	)

	_assert(controller.current_state == StageController.State.BRIEFING, "stage must begin in briefing")
	_assert(not controller.run_has_started(), "briefing must not start the run clock")
	_assert(not controller.finish_stage(), "Finish must be unavailable before the first shot")
	await physics_frame
	await physics_frame
	_assert(controller.elapsed_run_ticks() == 0, "pre-fire preparation must not consume run time")

	_assert(controller.begin_aiming(), "briefing must enter the playable aiming state")
	await physics_frame
	_assert(controller.elapsed_run_ticks() == 0, "pre-fire aiming must not consume run time")
	_assert(controller.request_fire(), "the admitted first root must launch")
	await physics_frame
	await physics_frame
	_assert(controller.run_has_started(), "the first actual root launch must start the clock")
	_assert(controller.elapsed_run_ticks() > 0, "an active run must advance on physics ticks")

	var before_pause := controller.elapsed_run_ticks()
	_assert(controller.toggle_pause(), "an active run must allow pause")
	await physics_frame
	await physics_frame
	_assert(controller.elapsed_run_ticks() == before_pause, "pause must freeze the run clock")
	_assert(controller.toggle_pause(), "pause must resume to the playable state")

	# Settling a family, reaching a grade threshold, or exhausting ammunition no
	# longer decides the stage. Only Finish or timeout may enter RESULT.
	controller.stage_data.target_coverage = 0.0
	manager.cleanup()
	await physics_frame
	await physics_frame
	controller.shots_remaining = 0
	_assert(controller.current_state == StageController.State.AIMING, "coverage and zero ammunition must not auto-end the run")
	_assert(not controller.request_fire(), "zero ammunition must reject Fire without ending the run")
	var coverage_before_finish := paint_system.coverage_percent()
	_assert(controller.finish_stage(), "Finish must remain available after the first shot")
	_assert(controller.current_state == StageController.State.RESULT, "manual Finish must produce one RESULT")
	_assert(observed_states.has(StageController.State.FINISHING), "Finish must pass through the result barrier")
	_assert(finished_results.size() == 1, "manual Finish must emit one result snapshot")
	_assert(manager.active_count() == 0, "resident projectiles must be cleaned after the score snapshot")
	var manual_result := controller.result_snapshot()
	_assert(manual_result.get("finish_reason") == StageController.FINISH_REASON_MANUAL, "manual Finish must retain its reason")
	_assert(is_equal_approx(float(manual_result.get("coverage", -1.0)), coverage_before_finish), "result coverage must come from PaintSystem")
	_assert(not controller.finish_stage(), "a completed run must reject a second Finish")

	controller.stage_data.duration_seconds = 0.1
	_assert(controller.restart(false), "retry must reset directly to aiming")
	_assert(not controller.run_has_started() and controller.elapsed_run_ticks() == 0, "retry must reset the clock and prior result")
	_assert(controller.request_fire(), "timeout fixture must launch its first root")
	var timeout_budget := 120
	while controller.current_state != StageController.State.RESULT and timeout_budget > 0:
		await physics_frame
		timeout_budget -= 1
	_assert(timeout_budget > 0, "the configured short duration must reach RESULT")
	var timeout_result := controller.result_snapshot()
	_assert(timeout_result.get("finish_reason") == StageController.FINISH_REASON_TIMEOUT, "duration expiry must record timeout")
	_assert(finished_results.size() == 2, "manual Finish and timeout must each emit exactly one result")
	_assert(legacy_terminal_events.is_empty(), "normal results must not emit legacy clear/fail events")
	_assert(manager.active_count() == 0, "timeout must clean residents after its score snapshot")

	if not _failed:
		print("phase4_state_test passed: first-shot clock, pause, manual Finish, zero-ammo wait, and timeout")
	Engine.time_scale = 1.0
	paused = false
	gameplay.queue_free()
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
