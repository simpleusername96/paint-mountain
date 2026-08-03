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
	var safe_route_only := false
	var shot_probe := Vector3.INF
	var custom_shots: Array[Vector3] = []
	var search_speed := 1
	var compare_shots := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			requested_stage = StringName(argument.trim_prefix("--stage="))
		elif argument == "--probe-only":
			probe_only = true
		elif argument == "--safe-route-only":
			safe_route_only = true
		elif argument.begins_with("--shot="):
			var components := argument.trim_prefix("--shot=").split(",")
			if components.size() == 3:
				shot_probe = Vector3(float(components[0]), float(components[1]), float(components[2]))
		elif argument.begins_with("--shots="):
			for encoded_shot in argument.trim_prefix("--shots=").split("|"):
				var components := encoded_shot.split(",")
				if components.size() == 3:
					custom_shots.append(Vector3(float(components[0]), float(components[1]), float(components[2])))
		elif argument.begins_with("--search-speed="):
			search_speed = clampi(int(argument.trim_prefix("--search-speed=")), 1, 8)
		elif argument == "--compare-shots":
			compare_shots = true
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
	if safe_route_only:
		solution = [
			Vector3(-14.0, 34.0, 68.0),
			Vector3(-18.0, 38.0, 76.0),
			Vector3(-10.0, 42.0, 68.0),
			Vector3(-20.0, 46.0, 76.0),
			Vector3(-12.0, 50.0, 84.0),
			Vector3(-16.0, 54.0, 84.0),
		]
	if shot_probe != Vector3.INF:
		solution = [shot_probe]
	elif not custom_shots.is_empty():
		solution = custom_shots
	for shot in solution:
		if controller.current_state in [StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED]:
			break
		_assert_true(agent.set_aim(shot.x, shot.y, shot.z), "solution shot must start from AIMING")
		_assert_true(agent.fire(), "solution shot must pass the shared fire guard")
		if search_speed > 1:
			Engine.physics_ticks_per_second = 60 * search_speed
			Engine.time_scale = float(search_speed)
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
		if compare_shots and shot != solution[-1]:
			controller.restart(false, StageController.ActionOrigin.DEBUG)
			await process_frame
			await physics_frame
	if safe_route_only:
		_assert_true(requested_stage == &"split_ridge", "safe-route verification is defined only for Split Ridge")
		_assert_true(float(agent.get_observation().current_coverage) < stage.target_coverage, "the direct left-route sequence must remain below the 70% target")
		if not _failed:
			print("Split Ridge safe-route guard passed below target at %.3f%%." % float(agent.get_observation().current_coverage))
	elif shot_probe == Vector3.INF and custom_shots.is_empty():
		_assert_true(controller.current_state == StageController.State.STAGE_CLEAR, "%s recorded solution must clear its target" % stage.display_name_key)
		if not stage.mechanism_loadout.is_empty():
			_assert_true(mechanism_activations.count > 0, "%s solution must activate its teaching mechanism" % stage.display_name_key)
			for mechanism_data in stage.mechanism_loadout:
				var required_kind: String = MechanismData.Kind.keys()[mechanism_data.kind]
				_assert_true(mechanism_activations.kinds.has(required_kind), "%s solution must activate %s" % [stage.display_name_key, required_kind])
	if not _failed and shot_probe == Vector3.INF and custom_shots.is_empty() and not safe_route_only:
		print("Phase 6 solution passed for %s at %.3f%% with %d mechanism activations." % [
			stage.display_name_key,
			float(agent.get_observation().current_coverage),
			mechanism_activations.count,
		])
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	game_state.persistence_enabled = true
	gameplay.queue_free()
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
