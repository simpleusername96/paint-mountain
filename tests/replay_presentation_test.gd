extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.selected_stage_id = &"first_descent"
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await _wait_for_gameplay(gameplay)

	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var recorder: ReplayRecorder = gameplay.get_node("ReplayRecorder")
	var presentation: ReplayPresentationController = gameplay.get_node("ReplayPresentationController")
	var agent: GameplayAgentApi = gameplay.get_node("GameplayAgentApi")
	var wind: WindController = gameplay.get_node("WindController")
	var layout: GeneratedStageLayout = gameplay.generated_layout()

	_assert_true(layout != null and layout.is_runtime_ready(), "gameplay must expose its admitted layout")
	_assert_true(
		recorder.start_attempt(
			gameplay.stage_data,
			layout.accepted_seed,
			layout,
			wind.schedule_identity()
		),
		"format-8 recording must bind to the runtime wind schedule"
	)
	_assert_true(
		controller.begin_aiming(StageController.ActionOrigin.HUMAN),
		"the source attempt must enter Aiming through StageController"
	)
	_assert_true(
		agent.change_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION),
		"the agent must expose map inspection rather than legacy camera presets"
	)
	_assert_true(
		agent.change_interaction_mode(CameraDirector.InteractionMode.AIM_LOCKED),
		"the agent must restore aim lock before Fire"
	)
	await _wait_for_fire_ready(agent)
	_assert_true(agent.fire(), "the source attempt must Fire through the agent origin")
	var active_observation := agent.get_observation()
	_assert_true(bool(active_observation.clock.started), "the first spawned root must start the run clock")
	_assert_true(
		String(active_observation.wind.schedule_identity) == String(wind.schedule_identity()),
		"the agent snapshot must expose the authoritative wind schedule"
	)
	_assert_true(
		int(active_observation.projectiles.resident_count) == 1 \
				and int(active_observation.projectiles.resident_count) \
						== int(active_observation.projectiles.moving_count) \
								+ int(active_observation.projectiles.resting_count) \
				and int(active_observation.projectiles.initial_flight_capacity) == 1,
		"the agent snapshot must distinguish resident, moving, resting, and initial-flight capacity"
	)
	_assert_true(
		active_observation.wind.has("current_direction") \
				and active_observation.wind.has("next_direction") \
				and active_observation.wind.has("current_strength") \
				and active_observation.wind.has("next_strength") \
				and active_observation.wind.has("seconds_until_change") \
				and String(active_observation.interaction.mode) == "AIM_LOCKED",
		"the agent snapshot must expose current/next wind and the interaction contract"
	)
	_assert_true(agent.finish(), "Finish must use the normal StageController agent origin")
	var source_result := controller.result_snapshot()
	_assert_true(
		not recorder.export_attempt().final_result.is_empty(),
		"the source attempt must seal its authoritative result through the gameplay wiring"
	)
	var attempt := recorder.export_attempt()
	var recorded_result: Dictionary = attempt.final_result
	_assert_true(
		int(attempt.format_version) == ReplayRecorder.FORMAT_VERSION \
				and int(attempt.physics_fps) == 60,
		"replay must use format 8 at the fixed physics rate"
	)
	_assert_true(
		String(attempt.wind_schedule_identity) == String(wind.schedule_identity()) \
				and not recorded_result.is_empty(),
		"format 8 must retain wind identity and final result truth"
	)
	var completed_observation := agent.get_observation()
	_assert_true(
		String(completed_observation.result.finish_reason) == "manual" \
				and bool(completed_observation.clock.finished),
		"the agent snapshot must expose the completed clock and result"
	)

	var incompatible_attempt := attempt.duplicate(true)
	incompatible_attempt["wind_schedule_identity"] = "wind-v1-987654321"
	incompatible_attempt["attempt_observation"]["wind_schedule"]["identity"] = \
			"wind-v1-987654321"
	_assert_true(
		not presentation.start(incompatible_attempt),
		"replay must reject a source wind schedule that differs from runtime"
	)
	_assert_true(
		String(recorder.export_attempt().wind_schedule_identity) \
				== String(attempt.wind_schedule_identity),
		"a rejected replay must not replace the current recording"
	)
	_assert_true(presentation.start(attempt), "a matching format-8 replay must start")
	var locked_aim := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	_assert_true(
		not controller.set_aim(-20.0, 18.0, 0.0, StageController.ActionOrigin.HUMAN),
		"human aim must be rejected during replay"
	)
	_assert_true(not agent.finish(), "agent Finish must be rejected during replay")
	_assert_true(
		not agent.change_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION),
		"agent camera interaction must be rejected during replay"
	)
	_assert_true(not agent.start_next_stage(), "agent navigation must be rejected during replay")
	_assert_true(
		Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent) \
				.is_equal_approx(locked_aim),
		"rejected input must not mutate cannon values"
	)

	var playback_errors: Array[String] = []
	var playback_finished_events: Array[bool] = []
	presentation.playback_error.connect(func(message: String) -> void: playback_errors.append(message))
	presentation.playback_finished.connect(func() -> void: playback_finished_events.append(true))
	_assert_true(
		presentation.set_paused(true) and presentation.set_paused(false) \
				and presentation.set_speed(2.0),
		"presentation controls must remain available while replay owns actions"
	)
	for _tick in range(240):
		await physics_frame
		if not playback_finished_events.is_empty() or not playback_errors.is_empty():
			break
	_assert_true(
		playback_errors.is_empty(),
		"matching replay must not report a result mismatch: %s" % str(playback_errors)
	)
	_assert_true(
		playback_finished_events.size() == 1,
		"replay must finish after its result is verified (state=%s, playback=%d/%d, next=%d, result=%s)" % [
			controller.state_name(),
			recorder.playback_index,
			Array(attempt.actions).size(),
			recorder.next_action_tick(),
			str(controller.result_snapshot()),
		]
	)
	var replay_result := controller.result_snapshot()
	_assert_true(
		String(replay_result.finish_reason) == String(source_result.finish_reason) \
				and int(replay_result.paint_mask_checksum) == int(source_result.paint_mask_checksum) \
				and is_equal_approx(float(replay_result.coverage), float(source_result.coverage)),
		"replay must match authoritative reason, paint checksum, and coverage"
	)
	_assert_true(presentation.exit(), "exit must cleanly end presentation")
	_assert_true(
		controller.current_state == StageController.State.BRIEFING \
				and not controller.action_origin_is_locked(),
		"exit must return to briefing before releasing replay ownership"
	)

	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Replay presentation checks passed: format-8 Finish, wind identity, result truth, and agent snapshot contracts.")
	quit(1 if _failed else 0)


func _wait_for_gameplay(gameplay: Node) -> void:
	for _frame in range(180):
		await physics_frame
		if gameplay.has_method("generated_layout") \
				and gameplay.generated_layout() != null \
				and gameplay.get_node("StageController").stage_data != null:
			return
	_assert_true(false, "gameplay did not finish configuring")


func _wait_for_fire_ready(agent: GameplayAgentApi) -> void:
	for _frame in range(180):
		if bool(agent.get_observation().fire_ready):
			return
		await physics_frame
	_assert_true(false, "default aim did not become Fire-ready")


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
