extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rejected := ShotObservation.new()
	rejected.configure(1, 0.0, 38.0, 68.0, 0.0)
	rejected.record_paint_command_rejection(null)
	var rejected_facts := rejected.to_dictionary()
	_assert_true(
		rejected.paint_command_rejection_count == 1 \
				and rejected.paint_command_rejections.size() == 1 \
				and int(rejected_facts.paint_command_rejection_count) == 1,
		"a rejected authoritative command must remain an explicit shot fact"
	)
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
		"contacts": [],
		"settlement_reasons": {},
		"settlements": [],
		"paint_command_count": 0,
		"last_applied_tick": -1,
		"last_drained_tick": -1,
		"last_drain_checksum": 0,
		"last_drain_event_tick": -1,
		"all_settled_tick": -1,
		"sealed": [],
		"sealed_tick": -1,
	}
	manager.projectile_contact_reported.connect(func(projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if source.first_contact == null:
			source.first_contact = contact
		source.contacts.append({
			"spawn_ordinal": projectile.spawn_ordinal,
			"source_event_index": contact.source_event_index,
			"owner": String(contact.contact_owner_id),
			"shape": String(contact.contact_shape_id),
		})
	)
	manager.projectile_stopped.connect(func(projectile: PaintProjectile, reason: StringName) -> void:
		source.settlement_reasons[reason] = int(source.settlement_reasons.get(reason, 0)) + 1
		source.settlements.append({
			"spawn_ordinal": projectile.spawn_ordinal,
			"reason": String(reason),
		})
	)
	paint.paint_command_applied.connect(func(command, _written: int, _newly: int) -> void:
		source.paint_command_count += 1
		source.last_applied_tick = maxi(source.last_applied_tick, int(command.physics_tick))
	)
	paint.paint_commands_drained.connect(func(tick: int, _count: int, checksum: int) -> void:
		source.last_drained_tick = tick
		source.last_drain_checksum = checksum
		source.last_drain_event_tick = Engine.get_physics_frames()
	)
	manager.all_projectiles_settled.connect(func() -> void: source.all_settled_tick = Engine.get_physics_frames())
	controller.shot_observation_sealed.connect(func(observation: ShotObservation) -> void:
		source.sealed.append(observation)
		source.sealed_tick = Engine.get_physics_frames()
	)
	_assert_true(controller.begin_aiming(), "shot fixture must enter aiming")
	_assert_true(controller.set_aim(0.0, 38.0, 68.0), "shot fixture aim must be accepted")
	_assert_true(controller.request_fire(), "shot fixture must fire")
	_assert_true(
		manager.process_physics_priority == 900 \
				and paint.process_physics_priority == 1000 \
				and controller.process_physics_priority == 1100,
		"manager, paint drain, and settlement observation must run in 900/1000/1100 order"
	)
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
		_assert_true(observation.schema_version == 4, "sealed observation must use schema 4")
		_assert_true(observation.shot_number == 1, "observation must retain shot order")
		_assert_true(observation.first_contact == source.first_contact, "first contact must come from the manager signal")
		_assert_true(observation.contacts.size() == source.contacts.size(), "every ordered manager contact must be retained")
		for index in range(mini(observation.contacts.size(), source.contacts.size())):
			var actual: Dictionary = observation.contacts[index]
			var expected: Dictionary = source.contacts[index]
			_assert_true(
				int(actual.spawn_ordinal) == int(expected.spawn_ordinal) \
						and int(actual.source_event_index) == int(expected.source_event_index) \
						and String(actual.contact_owner_id) == String(expected.owner) \
						and String(actual.contact_shape_id) == String(expected.shape),
				"contact order and stable identity must match manager emission"
			)
		_assert_true(observation.settlement_reason_counts == source.settlement_reasons, "settlement counts must match source signals")
		_assert_true(observation.settlements.size() == source.settlements.size(), "ordered settlements must match source signals")
		_assert_true(is_equal_approx(observation.coverage_after, paint.coverage_percent()), "sealed coverage must match PaintSystem")
		_assert_true(is_equal_approx(observation.coverage_gain, observation.coverage_after - observation.coverage_before), "coverage gain must derive from sealed endpoints")
		_assert_true(observation.paint_command_count == source.paint_command_count and observation.paint_command_count > 0, "sealed command count must match applied paint commands")
		_assert_true(observation.paint_command_rejection_count == 0 and observation.paint_command_rejections.is_empty(), "a valid shot must seal with no rejected authoritative command")
		_assert_true(observation.final_drain_tick == source.last_drained_tick and observation.final_drain_tick >= source.last_applied_tick, "sealed drain must cover the final applied command")
		_assert_true(observation.final_paint_mask_checksum == source.last_drain_checksum and observation.final_paint_mask_checksum == paint.paint_mask_checksum(), "sealed checksum must match the authoritative drained mask")
		_assert_true(source.sealed_tick - source.all_settled_tick >= 2, "sealing must wait two inactive physics ticks")
		_assert_true(source.sealed_tick >= source.last_drain_event_tick, "sealing must not precede the final paint drain")
		_assert_true(controller.last_sealed_shot_observation() == observation, "StageController must expose the same sealed object")
	var agent: GameplayAgentApi = gameplay.get_node("GameplayAgentApi")
	_assert_true(bool(agent.get_observation().previous_shot.get("is_sealed", false)) and int(agent.get_observation().previous_shot.get("schema_version", 0)) == 4, "agent observation must consume the sealed schema-4 object")
	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Shot observation checks passed: ordered contacts, settlements, drain facts, checksum, and coverage were sealed once.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
