extends SceneTree

const SANDBOX_SCENE := preload("res://scenes/sandbox/projectile_sandbox.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.time_scale = 2.0
	var first_trial := await _run_trial()
	var second_trial := await _run_trial()
	_assert_true(first_trial.completed, "first physics trial did not settle within its bounded lifetime")
	_assert_true(second_trial.completed, "second physics trial did not settle within its bounded lifetime")
	_assert_true(first_trial.impacts > 0, "projectile must physically impact the mountain")
	_assert_true(second_trial.impacts > 0, "repeated projectile must physically impact the mountain")
	_assert_true(first_trial.reason == second_trial.reason, "identical trials must share a termination reason")
	_assert_true(first_trial.reason == &"settled", "the repeated sandbox shot must reach the settled path")
	var impact_delta: float = first_trial.first_impact.distance_to(second_trial.first_impact)
	_assert_true(
		impact_delta <= 0.25,
		"identical trials must remain within the first-impact tolerance"
	)
	if not _failed:
		print(
			"Phase 2 rigid-body checks passed: first impact delta %.5f m, reason %s." % [
				impact_delta,
				first_trial.reason,
			]
		)
	Engine.time_scale = 1.0
	quit(1 if _failed else 0)


func _run_trial() -> Dictionary:
	var sandbox := SANDBOX_SCENE.instantiate()
	root.add_child(sandbox)
	await physics_frame
	await physics_frame
	var cannon: CannonController = sandbox.get_node("Cannon")
	var manager: ProjectileManager = sandbox.get_node("ProjectileManager")
	var trial_state := {
		"first_impact": Vector3.INF,
		"impacts": 0,
		"reason": &"",
	}
	manager.projectile_impact.connect(
		func(_projectile: PaintProjectile, world_position: Vector3, _speed: float) -> void:
			trial_state.impacts += 1
			if trial_state.first_impact == Vector3.INF:
				trial_state.first_impact = world_position
	)
	manager.projectile_stopped.connect(
		func(_projectile: PaintProjectile, reason: StringName) -> void:
			trial_state.reason = reason
	)
	cannon.set_aim(0.0, 38.0, 68.0)
	manager.spawn_projectile(cannon.projectile_data, cannon.get_launch_origin(), cannon.get_launch_velocity())
	var frame_budget := 60 * 24
	while manager.active_count() > 0 and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	var result := {
		"completed": manager.active_count() == 0,
		"first_impact": trial_state.first_impact,
		"impacts": trial_state.impacts,
		"reason": trial_state.reason,
	}
	manager.cleanup()
	sandbox.queue_free()
	await process_frame
	return result


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
