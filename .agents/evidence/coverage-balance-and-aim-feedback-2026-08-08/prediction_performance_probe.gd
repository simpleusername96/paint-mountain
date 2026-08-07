extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")
const STAGE_IDS: Array[StringName] = [&"stage_01", &"stage_10", &"stage_30"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	for stage_id in STAGE_IDS:
		await _measure_stage(game_state, stage_id)
	game_state.persistence_enabled = true
	quit()


func _measure_stage(game_state: GameState, stage_id: StringName) -> void:
	game_state.select_stage(stage_id)
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(stage_id)
	if gameplay == null:
		push_error("Prediction performance probe could not load %s." % stage_id)
		return
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var scheduler := gameplay.get_node(
		"TrajectoryPredictionScheduler"
	) as TrajectoryPredictionScheduler
	var wind := gameplay.get_node("WindController") as WindController
	if not controller.begin_aiming():
		push_error("Prediction performance probe could not enter Aim View for %s." % stage_id)
		gameplay.queue_free()
		await process_frame
		return
	scheduler.set_consumers_enabled(false)
	await physics_frame
	var batch_times_usec: Array[int] = []
	var job := TrajectoryPredictionJob.create(
		cannon.get_world_3d().direct_space_state,
		cannon.get_launch_origin(),
		cannon.get_launch_velocity(),
		cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp,
		scheduler._bounds,
		TrajectoryPredictionJob.COLLISION_MASK,
		true,
		gameplay.stage_data.wind_profile,
		gameplay.stage_data.terrain_seed,
		wind.elapsed_ticks()
	)
	var total_steps := 0
	while not job.is_complete():
		var started_at := Time.get_ticks_usec()
		total_steps += job.advance(TrajectoryPredictionScheduler.MAXIMUM_STEPS_PER_TICK)
		batch_times_usec.append(Time.get_ticks_usec() - started_at)
	var total_usec := 0
	var maximum_usec := 0
	for elapsed_usec in batch_times_usec:
		total_usec += elapsed_usec
		maximum_usec = maxi(maximum_usec, elapsed_usec)
	batch_times_usec.sort()
	var median_usec := batch_times_usec[batch_times_usec.size() / 2] \
			if not batch_times_usec.is_empty() else 0
	print(
		"PREDICTION_CANDIDATE_BATCH stage=%s steps=%d batches=%d total_ms=%.3f median_batch_ms=%.3f max_batch_ms=%.3f kind=%d" % [
			stage_id,
			total_steps,
			batch_times_usec.size(),
			float(total_usec) / 1000.0,
			float(median_usec) / 1000.0,
			float(maximum_usec) / 1000.0,
			int(job.completed_prediction().kind),
		]
	)
	await _measure_scheduler(cannon, scheduler)
	gameplay.queue_free()
	await process_frame


func _measure_scheduler(
		cannon: CannonController,
		scheduler: TrajectoryPredictionScheduler
) -> void:
	cannon.set_aim(
		clampf(cannon.yaw_degrees + 0.1, AimTuple.MINIMUM_YAW_DEGREES, AimTuple.MAXIMUM_YAW_DEGREES),
		cannon.elevation_degrees,
		cannon.power_percent
	)
	scheduler.set_consumers_enabled(true)
	scheduler.request_latest(true)
	var started_at := Time.get_ticks_usec()
	var physics_ticks := 0
	var maximum_tick_usec := 0
	while physics_ticks < 60 and not cannon.prediction_matches_expected_context():
		await physics_frame
		physics_ticks += 1
		maximum_tick_usec = maxi(
			maximum_tick_usec,
			scheduler.last_advance_elapsed_usec()
		)
	var elapsed_usec := Time.get_ticks_usec() - started_at
	print(
		"PREDICTION_CANDIDATE_SCHEDULER stage=%s settled=%s physics_ticks=%d latency_ms=%.3f max_tick_ms=%.3f discarded=%d" % [
			gameplay_stage_id(cannon),
			str(cannon.prediction_matches_expected_context()),
			physics_ticks,
			float(elapsed_usec) / 1000.0,
			float(maximum_tick_usec) / 1000.0,
			scheduler.discarded_job_count(),
		]
	)
	scheduler.set_consumers_enabled(false)


func gameplay_stage_id(cannon: CannonController) -> String:
	var gameplay := cannon.get_parent()
	return String(gameplay.stage_data.stage_id) if gameplay != null else "unknown"
