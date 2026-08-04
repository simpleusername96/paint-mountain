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
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var recorder: ReplayRecorder = gameplay.get_node("ReplayRecorder")
	var presentation: ReplayPresentationController = gameplay.get_node("ReplayPresentationController")
	var agent: GameplayAgentApi = gameplay.get_node("GameplayAgentApi")
	recorder.record_aim(4.0, 42.0, 71.0)
	recorder.record_fire()
	var attempt := recorder.export_attempt()
	_assert_true(int(attempt.format_version) == 6 and int(attempt.physics_fps) == 60, "replay must use format 6 at 60 physics FPS")
	_assert_true(
		int(attempt.target_mask_checksum) != 0 \
				and int(attempt.containment_checksum) != 0 \
				and int(attempt.placement_checksum) != 0 \
				and not attempt.generated_default_aim.is_empty(),
		"format-6 replay must retain layout checksums and the generated default aim"
	)
	_assert_true(
		(String(attempt.layout_admission) == "certificate" and int(attempt.reachability_checksum) != 0) \
				or (String(attempt.layout_admission) == "structural" and int(attempt.reachability_checksum) == 0),
		"reachability may be zero only for the structural runtime admission"
	)
	_assert_true(not recorder.load_attempt({"format_version": 5, "stage_id": "first_descent", "shots": []}), "format 5 must be rejected after the checksum contract changed")
	_assert_true(presentation.start(attempt), "valid format-6 presentation must start")
	var locked_aim := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	_assert_true(not controller.set_aim(-20.0, 18.0, 0.0, StageController.ActionOrigin.HUMAN), "human aim must be rejected during replay")
	_assert_true(not agent.set_aim(-20.0, 18.0, 0.0), "agent aim must be rejected during replay")
	_assert_true(not agent.change_camera(CameraDirector.Mode.WIDE), "agent camera mutation must be rejected during replay")
	_assert_true(not agent.start_next_stage(), "agent stage navigation must be rejected during replay")
	_assert_true(not controller.restart(false, StageController.ActionOrigin.DEBUG), "debug restart must be rejected during replay")
	controller.force_stage_clear(StageController.ActionOrigin.DEBUG)
	_assert_true(controller.current_state == StageController.State.AIMING, "debug clear must not mutate replay state")
	_assert_true(Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent).is_equal_approx(locked_aim), "rejected input must not mutate cannon values")
	var navigation_count := 0
	gameplay.navigation_requested.connect(func(_destination: StringName) -> void: navigation_count += 1)
	gameplay._request_navigation(&"stage_select")
	_assert_true(navigation_count == 0, "normal stage navigation must be locked")
	await physics_frame
	await physics_frame
	await physics_frame
	_assert_true(controller.current_state == StageController.State.PROJECTILE_IN_FLIGHT, "replay-origin aim and fire must use the normal stage path")
	_assert_true(is_equal_approx(cannon.yaw_degrees, 4.0) and is_equal_approx(cannon.elevation_degrees, 42.0), "replay aim must be applied")
	_assert_true(presentation.set_paused(true) and presentation.set_speed(2.0), "presentation controls must remain active")
	_assert_true(presentation.restart_playback(), "restart playback must be available while locked")
	_assert_true(presentation.exit(), "exit must cleanly end presentation")
	_assert_true(controller.current_state == StageController.State.BRIEFING and not controller.action_origin_is_locked(), "exit must return to briefing before releasing the lock")
	_assert_true(controller.begin_aiming(StageController.ActionOrigin.HUMAN), "human input must be restored only after exit")
	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Replay presentation checks passed: format 6 metadata, format 5 rejection, and exclusive replay-origin mutation.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
