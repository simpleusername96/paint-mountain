extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const POWERS := [60.0, 68.0, 76.0, 84.0, 92.0]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var unlocked: Dictionary = root.get_node("/root/SaveSystem").default_data()
	unlocked.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(unlocked)
	for stage_id in [&"burst_basin", &"split_ridge"]:
		_assert_true(game_state.select_stage(stage_id), "%s must be selectable for aim checks" % stage_id)
		var gameplay := GAMEPLAY_SCENE.instantiate()
		root.add_child(gameplay)
		await physics_frame
		await physics_frame
		var cannon: CannonController = gameplay.get_node("Cannon")
		var input_controller: AimInputController = gameplay.get_node("AimInputController")
		var stage_controller: StageController = gameplay.get_node("StageController")
		var camera: Camera3D = gameplay.get_node("Camera")
		var mechanisms := gameplay.get_node("Mechanisms").get_children()
		var space_state: PhysicsDirectSpaceState3D = gameplay.get_world_3d().direct_space_state
		_assert_true(stage_controller.begin_aiming(), "%s must enter aiming for pointer targeting" % stage_id)
		for _frame in range(45):
			await process_frame
		for mechanism: GimmickBase in mechanisms:
			var solved := {}
			for power in POWERS:
				solved = ImpactTargetSolver.solve(
					space_state,
					cannon.get_launch_origin(),
					mechanism.global_position,
					cannon.projectile_data,
					power,
					mechanism,
					cannon
				)
				if solved.valid:
					break
			_assert_true(bool(solved.get("valid", false)), "%s must have a valid first-impact solution for %s" % [stage_id, mechanism.data.display_name])
			if bool(solved.get("valid", false)):
				_assert_true(float(solved.elevation) >= 18.0 and float(solved.elevation) <= 68.0, "solver elevation must stay within cannon limits")
				_assert_true(float(solved.yaw) >= -28.0 and float(solved.yaw) <= 28.0, "solver yaw must stay within cannon limits")
				print("%s %s solution: yaw=%.3f elevation=%.3f power=%.0f collision=%s time=%.3f" % [
					stage_id, mechanism.data.display_name, solved.yaw, solved.elevation, solved.power, solved.collision_position, solved.flight_time
				])
				cannon.set_aim(cannon.yaw_degrees, cannon.elevation_degrees, float(solved.power))
				var screen_target := camera.unproject_position(mechanism.global_position + Vector3.UP * mechanism.data.trigger_radius * 0.6)
				_assert_true(input_controller.commit_screen_position(screen_target), "%s pointer targeting must commit visible %s" % [stage_id, mechanism.data.display_name])
				_assert_true(cannon.is_aim_valid(), "committed mechanism target must enable the shared fire guard")
				var shots_before_invalid := stage_controller.shots_remaining
				_assert_true(not input_controller.commit_screen_position(Vector2(-1000.0, -1000.0)), "offscreen pointer target must be invalid")
				_assert_true(not stage_controller.request_fire(), "invalid pointer target must block the shared fire guard")
				_assert_true(stage_controller.shots_remaining == shots_before_invalid, "rejected invalid fire must not consume a shot")
				_assert_true(input_controller.commit_screen_position(screen_target), "valid pointer target must recover after invalid hover")
		if stage_id == &"split_ridge":
			var layout: GeneratedStageLayout = gameplay.generated_layout()
			var stage := StageCatalog.get_stage(stage_id)
			for route_index in range(layout.route_spines.size()):
				for route_t in [0.42, 0.62]:
					var local_target := layout.route_position(route_index, route_t)
					var target := stage.terrain_center + Vector3(local_target.x, layout.height_at_local(local_target.x, local_target.z), local_target.z)
					var terrain_solution := {}
					for power in POWERS:
						terrain_solution = ImpactTargetSolver.solve(space_state, cannon.get_launch_origin(), target, cannon.projectile_data, power, null, cannon)
						if terrain_solution.valid:
							break
					if terrain_solution.get("valid", false):
						print("split_ridge route%d t%.2f solution: yaw=%.3f elevation=%.3f power=%.0f target=%s" % [route_index, route_t, terrain_solution.yaw, terrain_solution.elevation, terrain_solution.power, target])
		gameplay.queue_free()
		await process_frame
	game_state.persistence_enabled = true
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Aim interaction check failed: %s" % message)
