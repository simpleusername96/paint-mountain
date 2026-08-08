extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false
var _playback_errors: Array[String] = []
var _playback_finished := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.selected_stage_id = &"first_descent"
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	root.add_child(gameplay)
	await _wait_for_gameplay(gameplay)
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var recorder := gameplay.get_node("ReplayRecorder") as ReplayRecorder
	var presentation := gameplay.get_node("ReplayPresentationController") as ReplayPresentationController
	var agent := gameplay.get_node("GameplayAgentApi") as GameplayAgentApi
	var wind := gameplay.get_node("WindController") as WindController
	var projectiles := gameplay.get_node("ProjectileManager") as ProjectileManager
	var layout := gameplay.generated_layout() as GeneratedStageLayout
	_assert(controller != null and cannon != null and recorder != null and presentation != null \
			and agent != null and wind != null and projectiles != null and layout != null,
		"fixture owners must exist")
	if _failed:
		await _finish(gameplay, game_state)
		return
	_assert(recorder.start_attempt(gameplay.stage_data, layout.terrain_seed, layout, wind.schedule_identity()), "recording must start")
	_assert(controller.begin_aiming(), "source must enter aiming")
	var fractional_power := cannon.power_percent - 0.1 \
			if cannon.power_percent >= 100.0 else cannon.power_percent + 0.1
	var aim := AimTuple.canonicalize(cannon.yaw_degrees, cannon.elevation_degrees, fractional_power)
	_assert(aim != null, "fractional aim must canonicalize")
	if aim == null:
		await _finish(gameplay, game_state)
		return
	_assert(controller.begin_human_aim_revision(1), "revision must begin")
	_assert(controller.commit_human_aim_revision(1, aim.yaw_degrees, aim.elevation_degrees, aim.power_percent), "revision must commit")
	_assert(controller.begin_human_aim_revision(2), "second revision must begin")
	_assert(agent.set_aim(aim.yaw_degrees, aim.elevation_degrees, aim.power_percent), "agent direct aim must bypass the second pending revision")
	_assert(agent.change_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION), "agent must enter map inspection")
	_assert(agent.change_interaction_mode(CameraDirector.InteractionMode.AIM_LOCKED), "agent must return to aim lock")
	var contact_wind_ticks := {"source": -1, "replay": -1}
	projectiles.projectile_contact_reported.connect(
		func(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
			if not contact.is_first_contact:
				return
			contact_wind_ticks["replay" if presentation.active else "source"] = wind.elapsed_ticks()
	)
	_assert(agent.fire(), "source agent Fire must bypass ordinary human workflow")
	await _wait_for_contact(controller)
	var source_contact := _contact_snapshot(controller.current_shot_observation())
	var source_wind_tick := int(contact_wind_ticks.source)
	_assert(agent.finish(), "source Finish must be accepted")
	var source_result := controller.result_snapshot().duplicate(true)
	var attempt := recorder.export_attempt()
	_assert(_has_fractional_aim_without_target_payload(attempt),
		"fractional committed aim must record only its canonical tuple")
	presentation.playback_error.connect(func(message: String) -> void: _playback_errors.append(message))
	presentation.playback_finished.connect(func() -> void: _playback_finished = true)
	_assert(presentation.start(attempt), "fractional attempt must start replay")
	var replay_contact := {}
	for _tick in range(60 * 12):
		await physics_frame
		var observation := controller.current_shot_observation()
		if replay_contact.is_empty() and observation != null and observation.first_contact != null:
			replay_contact = _contact_snapshot(observation)
		if not _playback_errors.is_empty() or _playback_finished:
			break
	var replay_result := controller.result_snapshot()
	var replay_wind_tick := int(contact_wind_ticks.replay)
	_assert(_playback_errors.is_empty(),
		"fractional first-contact replay must not report a parity error: %s" % str(_playback_errors))
	_assert(_playback_finished, "fractional first-contact replay must finish result verification")
	_assert(_contacts_match(source_contact, replay_contact),
		"fractional replay must preserve first-contact identity, event, and point: %s / %s" % [
			JSON.stringify(source_contact), JSON.stringify(replay_contact),
		])
	# Source Fire is issued from the test coroutine and replay Fire from the
	# fixed-physics playback owner, so observation can straddle one frame signal.
	# The authoritative contact/paint result must still match exactly.
	_assert(absi(source_wind_tick - replay_wind_tick) <= 1,
		"fractional replay contact must stay within one fixed-tick boundary: %d / %d" % [
			source_wind_tick, replay_wind_tick,
		])
	_assert(int(source_result.get("paint_mask_checksum", -1)) \
			== int(replay_result.get("paint_mask_checksum", -2)) \
			and is_equal_approx(float(source_result.get("coverage", -1.0)),
				float(replay_result.get("coverage", -2.0))),
		"fractional replay must preserve authoritative paint checksum and coverage")
	if not _failed:
		print("Fractional replay contact passed: aim=%s, wind tick=%d, terrain/top contact and paint checksum match." % [
			aim.stable_key(), source_wind_tick,
		])
	await _finish(gameplay, game_state)


func _wait_for_gameplay(gameplay: Node) -> void:
	for _frame in range(180):
		await physics_frame
		if gameplay.has_method("generated_layout") and gameplay.generated_layout() != null:
			return
	_assert(false, "fixture did not configure")


func _wait_for_contact(controller: StageController) -> void:
	for _frame in range(60 * 8):
		var observation := controller.current_shot_observation()
		if observation != null and observation.first_contact != null:
			return
		await physics_frame
	_assert(false, "source did not reach first contact")


func _contact_snapshot(observation: ShotObservation) -> Dictionary:
	if observation == null or observation.first_contact == null:
		return {}
	var contact := observation.first_contact
	return {
		"tick": contact.physics_tick,
		"event": contact.source_event_index,
		"owner": String(contact.contact_owner_id),
		"shape": String(contact.contact_shape_id),
		"point": [contact.world_position.x, contact.world_position.y, contact.world_position.z],
	}


func _contacts_match(source: Dictionary, replay: Dictionary) -> bool:
	if source.is_empty() or replay.is_empty():
		return false
	var source_point: Array = source.get("point", [])
	var replay_point: Array = replay.get("point", [])
	return String(source.get("owner", "")) == String(replay.get("owner", "")) \
			and String(source.get("shape", "")) == String(replay.get("shape", "")) \
			and int(source.get("event", -1)) == int(replay.get("event", -2)) \
			and source_point.size() == 3 and replay_point.size() == 3 \
			and Vector3(float(source_point[0]), float(source_point[1]), float(source_point[2])) \
					.distance_to(Vector3(float(replay_point[0]), float(replay_point[1]),
						float(replay_point[2]))) <= 0.001


func _has_fractional_aim_without_target_payload(attempt: Dictionary) -> bool:
	for action_variant in Array(attempt.get("actions", [])):
		var action := action_variant as Dictionary
		if action == null or String(action.get("kind", "")) != "aim":
			continue
		var power := float(action.get("power", 0.0))
		if is_equal_approx(power, roundf(power)):
			continue
		return action.keys().size() == 5 \
				and not action.has("selected_target") \
				and not action.has("target_world_point") \
				and not action.has("solve_revision")
	return false


func _finish(gameplay: Node, game_state: GameState) -> void:
	if is_instance_valid(gameplay):
		gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Fractional replay diagnostic failed: %s" % message)
