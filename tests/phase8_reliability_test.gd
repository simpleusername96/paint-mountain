extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const ITERATIONS := 30

var _failed: bool = false
var _slowest_restart_ms: float = 0.0


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	data.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(data)
	game_state.select_stage(&"split_ridge")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	for _frame in range(4):
		await process_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var projectiles: ProjectileManager = gameplay.get_node("ProjectileManager")
	controller.begin_aiming()
	controller.restart_completed.connect(_on_restart_completed)
	for iteration in range(ITERATIONS):
		cannon.set_aim(float(iteration % 9) - 4.0, 34.0, 68.0)
		_assert_true(controller.request_fire(), "a clean aiming state must accept fire")
		await physics_frame
		controller.restart(false)
		await process_frame
		await physics_frame
		_assert_clean_restart(controller, projectiles)
		var outside := projectiles.stage_bounds.position - Vector3.ONE * 8.0
		var escaped := projectiles.spawn_projectile(cannon.projectile_data, outside, Vector3.ZERO)
		_assert_true(escaped != null, "out-of-bounds probe must spawn")
		await physics_frame
		await process_frame
		_assert_true(projectiles.active_count() == 0, "out-of-bounds projectile must be retired")
		_assert_true(_projectile_child_count(projectiles) == 0, "retired projectile nodes must be freed")
	var stop_reasons: Array[StringName] = []
	projectiles.projectile_stopped.connect(func(_projectile: PaintProjectile, reason: StringName) -> void: stop_reasons.append(reason))
	projectiles.spawn_projectile(cannon.projectile_data, cannon.get_launch_origin(), Vector3.ZERO, 0.0)
	await physics_frame
	await process_frame
	var lifetime_data := cannon.projectile_data.duplicate(true) as ProjectileData
	lifetime_data.maximum_lifetime = 0.01
	projectiles.spawn_projectile(lifetime_data, cannon.get_launch_origin() + Vector3.UP * 12.0, Vector3.ZERO)
	await physics_frame
	await process_frame
	_assert_true(stop_reasons.has(&"empty_payload"), "zero-payload projectile must use the empty-payload termination path")
	_assert_true(stop_reasons.has(&"lifetime"), "expired projectile must use the lifetime termination path")
	controller.restart(false)
	await process_frame
	_assert_clean_restart(controller, projectiles)
	_assert_true(_slowest_restart_ms <= 50.0, "restart must remain at or below 50 ms")
	print("Phase 8 reliability: %d fire/restart and out-of-bounds cycles passed; slowest restart %.3f ms." % [
		ITERATIONS,
		_slowest_restart_ms,
	])
	game_state.persistence_enabled = true
	gameplay.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _assert_clean_restart(controller: StageController, projectiles: ProjectileManager) -> void:
	_assert_true(controller.current_state == StageController.State.AIMING, "restart must restore aiming")
	_assert_true(controller.shots_remaining == controller.stage_data.maximum_shots, "restart must refill shots")
	_assert_true(projectiles.active_count() == 0, "restart must leave no active projectile")
	_assert_true(_projectile_child_count(projectiles) == 0, "restart must leave no projectile node")


func _projectile_child_count(projectiles: ProjectileManager) -> int:
	var count := 0
	for child in projectiles.get_children():
		if child is PaintProjectile:
			count += 1
	return count


func _on_restart_completed(elapsed_ms: float) -> void:
	_slowest_restart_ms = maxf(_slowest_restart_ms, elapsed_ms)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
