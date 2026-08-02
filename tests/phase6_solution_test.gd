extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_solution")


func _run_solution() -> void:
	# Reliable solutions must be validated against the production 60 Hz trajectory.
	Engine.time_scale = 1.0
	var requested_stage: StringName = &"first_descent"
	var probe_only := false
	var shot_probe := Vector3.INF
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			requested_stage = StringName(argument.trim_prefix("--stage="))
		elif argument == "--probe-only":
			probe_only = true
		elif argument.begins_with("--shot="):
			var components := argument.trim_prefix("--shot=").split(",")
			if components.size() == 3:
				shot_probe = Vector3(float(components[0]), float(components[1]), float(components[2]))
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var unlocked_data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	unlocked_data.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(unlocked_data)
	_assert_true(game_state.select_stage(requested_stage), "requested solution stage must be selectable")
	var stage := StageCatalog.get_stage(requested_stage)
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var agent: GameplayAgentApi = gameplay.get_node("GameplayAgentApi")
	var projectile_manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var mechanism_nodes := gameplay.get_node("Mechanisms").get_children()
	var mechanism_activations := {"count": 0, "kinds": {}}
	var impact_positions: Array[Vector3] = []
	agent.gameplay_event.connect(func(event_name: StringName, payload: Dictionary) -> void:
		if event_name == &"mechanism_activated":
			mechanism_activations.count += 1
			mechanism_activations.kinds[String(payload.kind)] = true
		elif event_name == &"projectile_impacted":
			impact_positions.append(payload.position)
	)
	print("%s mechanism observations: %s" % [stage.display_name_key, agent.get_observation().mechanisms])
	if probe_only:
		Engine.time_scale = 1.0
		game_state.persistence_enabled = true
		gameplay.queue_free()
		quit(0)
		return
	controller.begin_aiming()
	var solution: Array[Vector3] = stage.reliable_solution
	if shot_probe != Vector3.INF:
		solution = [shot_probe]
	for shot in solution:
		if controller.current_state in [StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED]:
			break
		_assert_true(agent.set_aim(shot.x, shot.y, shot.z), "solution shot must start from AIMING")
		_assert_true(agent.fire(), "solution shot must pass the shared fire guard")
		var closest_mechanism_distance := INF
		var closest_projectile_position := Vector3.ZERO
		var frame_budget := 60 * 26
		while controller.current_state not in [StageController.State.AIMING, StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED] and frame_budget > 0:
			await physics_frame
			if shot_probe != Vector3.INF and not mechanism_nodes.is_empty():
				for projectile in projectile_manager.active_projectiles():
					var distance := projectile.global_position.distance_to(mechanism_nodes[0].global_position)
					if distance < closest_mechanism_distance:
						closest_mechanism_distance = distance
						closest_projectile_position = projectile.global_position
			frame_budget -= 1
		_assert_true(frame_budget > 0, "solution shot must settle within its bounded lifetime")
		print("%s shot %.0f/%.0f/%.0f -> %.3f%% (%s)" % [
			stage.display_name_key,
			shot.x,
			shot.y,
			shot.z,
			float(agent.get_observation().current_coverage),
			controller.state_name(),
		])
		if shot_probe != Vector3.INF:
			if mechanism_nodes.is_empty():
				print("Impacts: %s" % [impact_positions])
			else:
				print("Closest mechanism pass: %.3fm at %s; activations=%d; impacts=%s" % [closest_mechanism_distance, closest_projectile_position, mechanism_activations.count, impact_positions])
	if shot_probe == Vector3.INF:
		_assert_true(controller.current_state == StageController.State.STAGE_CLEAR, "%s recorded solution must clear its target" % stage.display_name_key)
		if not stage.mechanism_loadout.is_empty():
			_assert_true(mechanism_activations.count > 0, "%s solution must activate its teaching mechanism" % stage.display_name_key)
			for mechanism_data in stage.mechanism_loadout:
				var required_kind: String = MechanismData.Kind.keys()[mechanism_data.kind]
				_assert_true(mechanism_activations.kinds.has(required_kind), "%s solution must activate %s" % [stage.display_name_key, required_kind])
	if not _failed and shot_probe == Vector3.INF:
		print("Phase 6 solution passed for %s at %.3f%% with %d mechanism activations." % [
			stage.display_name_key,
			float(agent.get_observation().current_coverage),
			mechanism_activations.count,
		])
	Engine.time_scale = 1.0
	game_state.persistence_enabled = true
	gameplay.queue_free()
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
