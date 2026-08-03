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
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	var source := {
		"first_contact": null,
		"settlement_reasons": {},
		"all_settled_tick": -1,
		"sealed": [],
		"sealed_tick": -1,
	}
	manager.projectile_contact_reported.connect(func(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if source.first_contact == null:
			source.first_contact = contact
	)
	manager.projectile_stopped.connect(func(_projectile: PaintProjectile, reason: StringName) -> void:
		source.settlement_reasons[reason] = int(source.settlement_reasons.get(reason, 0)) + 1
	)
	manager.all_projectiles_settled.connect(func() -> void: source.all_settled_tick = Engine.get_physics_frames())
	controller.shot_observation_sealed.connect(func(observation: ShotObservation) -> void:
		source.sealed.append(observation)
		source.sealed_tick = Engine.get_physics_frames()
	)
	_assert_true(controller.begin_aiming(), "shot fixture must enter aiming")
	_assert_true(controller.set_aim(0.0, 38.0, 68.0), "shot fixture aim must be accepted")
	_assert_true(controller.request_fire(), "shot fixture must fire")
	Engine.time_scale = 3.0
	var budget := 60 * 24
	while controller.current_state not in [StageController.State.AIMING, StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED] and budget > 0:
		await physics_frame
		budget -= 1
	Engine.time_scale = 1.0
	_assert_true(budget > 0, "shot fixture must settle within its bounded lifetime")
	_assert_true(source.sealed.size() == 1, "exactly one sealed observation must be emitted")
	if source.sealed.size() == 1:
		var observation: ShotObservation = source.sealed[0]
		_assert_true(observation.is_sealed, "consumer must receive only a sealed observation")
		_assert_true(observation.shot_number == 1, "observation must retain shot order")
		_assert_true(observation.first_contact == source.first_contact, "first contact must come from the manager signal")
		_assert_true(observation.settlement_reason_counts == source.settlement_reasons, "settlement counts must match source signals")
		_assert_true(is_equal_approx(observation.coverage_after, paint.coverage_percent()), "sealed coverage must match PaintSystem")
		_assert_true(is_equal_approx(observation.coverage_gain, observation.coverage_after - observation.coverage_before), "coverage gain must derive from sealed endpoints")
		_assert_true(is_equal_approx(observation.current_payload + observation.consumed_payload, observation.initial_payload), "aggregate payload accounting must conserve the initial payload")
		_assert_true(source.sealed_tick - source.all_settled_tick >= 2, "sealing must wait two inactive physics ticks")
		_assert_true(controller.last_sealed_shot_observation() == observation, "StageController must expose the same sealed object")
	var agent: GameplayAgentApi = gameplay.get_node("GameplayAgentApi")
	_assert_true(bool(agent.get_observation().previous_shot.get("is_sealed", false)), "agent observation must consume the sealed object")
	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Shot observation checks passed: causal contacts, payload, settlement, and coverage were sealed once.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
