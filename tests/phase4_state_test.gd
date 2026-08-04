extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.time_scale = 2.0
	root.get_node("/root/GameState").select_stage(&"first_descent")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var paint_system: PaintSystem = gameplay.get_node("PaintSystem")
	var layout: GeneratedStageLayout = gameplay.generated_layout()
	var restart_observation := {"elapsed_ms": -1.0}
	var observed_states: Array[int] = []
	controller.state_changed.connect(func(state: int, _previous: int) -> void: observed_states.append(state))
	controller.restart_completed.connect(func(elapsed_ms: float) -> void: restart_observation.elapsed_ms = elapsed_ms)

	_assert_true(controller.current_state == StageController.State.BRIEFING, "gameplay must begin in briefing")
	var default_aim := layout.default_aim
	_assert_true(default_aim != null and default_aim.is_valid(), "First Descent must expose its admitted default aim")
	_assert_true(
		default_aim != null
				and is_equal_approx(cannon.yaw_degrees, default_aim.yaw_degrees)
				and is_equal_approx(cannon.elevation_degrees, default_aim.elevation_degrees)
				and is_equal_approx(cannon.power_percent, float(default_aim.power_percent)),
		"First Descent must apply its admitted generated default aim; got %.1f/%.1f/%.1f" % [cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent]
	)
	_assert_true(controller.begin_aiming(), "briefing must accept the start-aiming action")
	_assert_true(controller.current_state == StageController.State.AIMING, "begin aiming must enter AIMING")
	_assert_true(controller.request_fire(), "ready aiming state must accept the first fire action")
	_assert_true(controller.request_fire(), "a second fire action must be accepted while the first family is active")
	_assert_true(controller.shots_remaining == 2, "two accepted fire actions must consume exactly two shots")
	_assert_true(manager.active_root_count() == 2, "two immediate fires must expose two active root families")
	_assert_true(not controller.request_fire(), "a third fire must be rejected at the two-family capacity")

	var frame_budget := 60 * 60
	while controller.current_state not in [StageController.State.AIMING, StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED] and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	_assert_true(frame_budget > 0, "shot loop must settle into a decision state")
	var expected_result := StageController.result_state_for(
		paint_system.coverage_percent(),
		controller.stage_data.target_coverage,
		controller.shots_remaining
	)
	_assert_true(
		controller.current_state == expected_result,
		"the settled shot must enter the coverage-derived decision state; got %s at %.3f%%" % [
			controller.state_name(), paint_system.coverage_percent()
		]
	)
	_assert_true(manager.active_count() == 0, "shot settlement must leave no managed projectile")
	_assert_true(paint_system.coverage_percent() > 0.0, "settled shot must finalize authoritative coverage")
	_assert_true(observed_states.has(StageController.State.PROJECTILE_IN_FLIGHT), "accepted shot must enter projectile observation")
	_assert_true(observed_states.has(StageController.State.PAINT_SETTLING), "projectile settlement must enter paint settlement")
	_assert_true(observed_states.has(StageController.State.SHOT_RESULT), "coverage gain must appear before the next decision")
	var settled_coverage := paint_system.coverage_percent()

	controller.restart(false)
	_assert_true(controller.current_state == StageController.State.AIMING, "gameplay retry must return directly to AIMING")
	_assert_true(controller.shots_remaining == 4, "restart must refill stage shots")
	_assert_true(is_zero_approx(paint_system.coverage_percent()), "restart must clear paint and coverage")
	_assert_true(manager.active_count() == 0, "restart must clear all projectiles")
	_assert_true(restart_observation.elapsed_ms >= 0.0 and restart_observation.elapsed_ms < 1000.0, "restart must complete under one second")

	_assert_true(controller.toggle_pause(), "aiming must enter pause")
	_assert_true(controller.current_state == StageController.State.PAUSED and paused, "pause must stop the scene tree")
	_assert_true(controller.toggle_pause(), "pause must resume to the prior state")
	_assert_true(controller.current_state == StageController.State.AIMING and not paused, "resume must restore AIMING")

	_assert_true(
		StageController.result_state_for(70.0, 70.0, 0) == StageController.State.STAGE_CLEAR,
		"coverage at target must clear even on the last shot"
	)
	_assert_true(
		StageController.result_state_for(69.9, 70.0, 0) == StageController.State.STAGE_FAILED,
		"exhausted shots below target must fail"
	)
	_assert_true(
		StageController.result_state_for(20.0, 70.0, 2) == StageController.State.AIMING,
		"remaining shots below target must continue"
	)
	_assert_true(
		StageController.result_state_for(100.0, 70.0, 2, 1) \
				== StageController.State.STAGE_FAILED,
		"a rejected authoritative paint command must fail closed even above target"
	)

	if not _failed:
		print(
			"Phase 4 state checks passed: shot settled at %.4f%% and restart took %.3f ms." % [
				settled_coverage,
				restart_observation.elapsed_ms,
			]
		)
	Engine.time_scale = 1.0
	paused = false
	gameplay.queue_free()
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
