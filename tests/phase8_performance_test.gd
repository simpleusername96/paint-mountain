extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	data.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(data)
	game_state.select_stage(&"burst_basin")
	var load_started := Time.get_ticks_usec()
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	for _frame in range(5):
		await process_frame
	var load_ms := float(Time.get_ticks_usec() - load_started) / 1000.0
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var projectiles: ProjectileManager = gameplay.get_node("ProjectileManager")
	controller.begin_aiming()
	cannon.set_aim(-7.0, 36.0, 74.0)
	controller.request_fire()
	var maximum_active := 0
	for _frame in range(45):
		await process_frame
		maximum_active = maxi(maximum_active, projectiles.active_count())
	const MEASURED_FRAMES := 360
	var measured_started := Time.get_ticks_usec()
	var previous_tick := measured_started
	var maximum_frame_ms := 0.0
	for _frame in range(MEASURED_FRAMES):
		await process_frame
		var now := Time.get_ticks_usec()
		maximum_frame_ms = maxf(maximum_frame_ms, float(now - previous_tick) / 1000.0)
		previous_tick = now
		maximum_active = maxi(maximum_active, projectiles.active_count())
	var elapsed_seconds := float(Time.get_ticks_usec() - measured_started) / 1000000.0
	var average_fps := float(MEASURED_FRAMES) / maxf(elapsed_seconds, 0.001)
	var memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	_assert_true(load_ms < 3000.0, "stage load must remain under three seconds")
	_assert_true(average_fps >= 55.0, "1920x1080 average frame rate must remain at least 55 FPS")
	_assert_true(maximum_frame_ms < 120.0, "no large paint/Burst frame may stall longer than 120 ms")
	_assert_true(maximum_active <= ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES, "performance run must preserve the eight-ball limit")
	print("Phase 8 performance: load %.2f ms, avg %.2f FPS, worst %.2f ms, max balls %d, static memory %.2f MiB, coverage %.3f%%." % [
		load_ms,
		average_fps,
		maximum_frame_ms,
		maximum_active,
		memory_mb,
		gameplay.get_node("PaintSystem").coverage_percent(),
	])
	game_state.persistence_enabled = true
	gameplay.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
