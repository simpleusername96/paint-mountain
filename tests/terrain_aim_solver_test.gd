extends SceneTree

const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const TERRAIN_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cannon := CANNON_SCENE.instantiate() as CannonController
	root.add_child(cannon)
	await process_frame
	var identity := TrajectoryHitIdentity.terrain_top(
		TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID, 0, Vector2i(4, 2), 1,
		Vector3(0.2, 0.3, 0.5)
	)
	var target := TerrainAimTarget.new(Vector3(75.0, 0.0, -110.0), Vector3.UP, identity)
	var profile := WindProfile.new()
	var free := TerrainAimSolver.nominate(cannon, target, &"target", 0.0, &"low",
		AimTuple.new(0.0, 38.0, 68), profile, 9173, 0)
	var repeated := TerrainAimSolver.nominate(cannon, target, &"target", 0.0, &"low",
		AimTuple.new(0.0, 38.0, 68), profile, 9173, 0)
	var high_branch := TerrainAimSolver.nominate(cannon, target, &"target", 0.0, &"high",
		AimTuple.new(0.0, 58.0, 68), profile, 9173, 0)
	var pinned_elevation := TerrainAimSolver.nominate(cannon, target, &"elevation", 38.0,
		&"low", AimTuple.new(0.0, 38.0, 68), profile, 9173, 0)
	var pinned_power := TerrainAimSolver.nominate(cannon, target, &"power", 68.0, &"high",
		AimTuple.new(0.0, 38.0, 68), profile, 9173, 0)
	_assert_true(not free.is_empty() and free.size() <= TerrainAimSolver.MAXIMUM_NOMINATIONS,
		"free target solve must nominate a bounded candidate set")
	_assert_true(_candidate_keys(free) == _candidate_keys(repeated),
		"the same wind seed and launch tick must nominate deterministically")
	_assert_true(free.all(func(candidate: Dictionary) -> bool:
		return (candidate.aim as AimTuple).elevation_degrees \
				< TerrainAimSolver.BRANCH_SPLIT_ELEVATION_DEGREES),
		"low-branch nomination must not silently cross into the high branch")
	_assert_true(not high_branch.is_empty() and high_branch.all(func(candidate: Dictionary) -> bool:
		return (candidate.aim as AimTuple).elevation_degrees \
				>= TerrainAimSolver.BRANCH_SPLIT_ELEVATION_DEGREES),
		"high-branch nomination must not silently cross into the low branch")
	_assert_true(not pinned_elevation.is_empty() and (pinned_elevation[0].aim as AimTuple).elevation_degrees == 38.0,
		"pinned elevation must preserve the requested tenth-degree value")
	_assert_true(not pinned_power.is_empty() and (pinned_power[0].aim as AimTuple).power_percent == 68,
		"pinned power must preserve the requested value")
	_assert_true((free[0].aim as AimTuple).yaw_degrees > 0.0,
		"positive-X targets must nominate positive player yaw")
	var contact := target.world_point
	var prediction := TrajectoryPrediction.new(TrajectoryPrediction.Kind.COLLISION, contact,
		PackedVector3Array([contact]), 1.0, null, Vector3.UP, &"", identity, contact)
	_assert_true(TerrainAimSolver.validates_target(prediction, target, cannon.projectile_data.radius),
		"same top identity and half-radius contact must validate")
	cannon.queue_free()
	await process_frame
	await _check_scheduler_target_round_trip(TerrainTestFixtureFactory.Kind.FLAT, 0.0, 8.0, "flat")
	await _check_scheduler_target_round_trip(TerrainTestFixtureFactory.Kind.RAMP, -10.0, 0.0, "sloped")
	if not _failed:
		print("Terrain aim solver checks passed: bounded inversion, pinning, yaw sign, and top identity validation.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("Terrain aim solver check failed: %s" % message)


func _check_scheduler_target_round_trip(kind: TerrainTestFixtureFactory.Kind,
		terrain_y: float, _seed_yaw: float, label: String) -> void:
	var host := Node3D.new()
	root.add_child(host)
	var terrain := TERRAIN_SCENE.instantiate() as TerrainSurface
	host.add_child(terrain)
	terrain.position.z = -45.0
	terrain.position.y = terrain_y
	terrain.configure(TerrainTestFixtureFactory.build_layout(kind))
	var cannon := CANNON_SCENE.instantiate() as CannonController
	host.add_child(cannon)
	var wind := WindController.new()
	host.add_child(wind)
	var scheduler := TrajectoryPredictionScheduler.new()
	host.add_child(scheduler)
	var profile := WindProfile.new()
	profile.maximum_acceleration = 0.0
	_assert_true(wind.configure(profile, 9173), "target fixture wind must configure")
	await physics_frame
	cannon.set_aim(0.0, 24.0, 20.0)
	var bounds := AABB(Vector3(-100.0, -30.0, -120.0), Vector3(200.0, 180.0, 180.0))
	var target_point := terrain.world_surface_point(Vector2(0.0, -45.0))
	var target_normal := terrain.world_surface_normal(Vector2(0.0, -45.0))
	var identity := terrain.classify_top_physics_hit(target_point)
	_assert_true(identity != null and identity.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		"%s target fixture must resolve canonical terrain-top identity" % label)
	if identity == null or identity.contact_owner_id != TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
		host.queue_free()
		await process_frame
		return
	var target := TerrainAimTarget.new(target_point, target_normal, identity)
	_assert_true(scheduler.configure(cannon, wind, bounds, profile, 9173),
		"target fixture scheduler must configure")
	scheduler.set_consumers_enabled(true)
	var stale_callbacks: Array[TerrainAimSolution] = []
	var callbacks: Array[TerrainAimSolution] = []
	var stale_callback := func(solution: TerrainAimSolution) -> bool:
		stale_callbacks.append(solution)
		return false
	var callback := func(solution: TerrainAimSolution) -> bool:
		callbacks.append(solution)
		if solution.status != TerrainAimSolution.Status.VALID:
			return false
		cannon.set_aim(solution.aim.yaw_degrees, solution.aim.elevation_degrees,
			float(solution.aim.power_percent))
		return true
	# A stale revision is replaced before the scheduler may nominate it.
	scheduler.request_target_solution(target, &"target", 0.0, &"low",
		AimTuple.new(0.0, 24.0, 20.0), 40, stale_callback)
	scheduler.request_target_solution(target, &"target", 0.0, &"low",
		AimTuple.new(0.0, 24.0, 20.0), 41, callback)
	for _tick in range(180):
		scheduler._physics_process(1.0 / 60.0)
		if cannon.current_prediction() != null and cannon.prediction_matches_expected_context():
			break
	_assert_true(not callbacks.is_empty() and callbacks[0].status == TerrainAimSolution.Status.PENDING,
		"%s target request must publish pending before bounded work" % label)
	_assert_true(stale_callbacks.size() == 1 \
			and stale_callbacks[0].status == TerrainAimSolution.Status.PENDING,
		"%s newest revision must supersede stale target work" % label)
	_assert_true(cannon.current_prediction() != null and cannon.prediction_matches_expected_context(),
		"%s accepted VALID callback must atomically publish Cannon's matching prediction" % label)
	_assert_true(scheduler.active_job_count() <= 1 and scheduler.last_advance_step_count() <= 12,
		"%s target work must retain one-job and 12-step limits" % label)
	_assert_true(scheduler.last_advance_elapsed_usec() <= TrajectoryPredictionScheduler.MAXIMUM_WORK_USEC_PER_TICK + 2500,
		"%s bounded scheduler diagnostic must remain near its 1 ms work budget" % label)
	if cannon.current_prediction() != null:
		_assert_true(TerrainAimSolver.validates_target(cannon.current_prediction(), target,
			cannon.projectile_data.radius), "%s published prediction must be top contact within half radius" % label)
	var free_aim := AimTuple.new(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	# Pinning reuses the same physical target and changes only the requested control.
	for pinned in [
		[&"elevation", clampf(free_aim.elevation_degrees + 0.5,
			AimTuple.MINIMUM_ELEVATION_DEGREES, AimTuple.MAXIMUM_ELEVATION_DEGREES)],
		[&"power", clampf(free_aim.power_percent + 2.0,
			AimTuple.MINIMUM_POWER_PERCENT, AimTuple.MAXIMUM_POWER_PERCENT)],
	]:
		var pinned_solutions: Array[TerrainAimSolution] = []
		var pinned_finished := false
		var pinned_callback := func(solution: TerrainAimSolution) -> bool:
			pinned_solutions.append(solution)
			if solution.status == TerrainAimSolution.Status.PENDING:
				return false
			pinned_finished = true
			if solution.status != TerrainAimSolution.Status.VALID:
				return false
			cannon.set_aim(solution.aim.yaw_degrees, solution.aim.elevation_degrees, float(solution.aim.power_percent))
			return true
		scheduler.request_target_solution(target, pinned[0], float(pinned[1]), &"low",
			free_aim, 50, pinned_callback)
		for _pinned_tick in range(180):
			scheduler._physics_process(1.0 / 60.0)
			if pinned_finished:
				break
		var valid := pinned_solutions.filter(func(value: TerrainAimSolution) -> bool: return value.status == TerrainAimSolution.Status.VALID)
		_assert_true(not valid.is_empty(), "%s pinned %s request must validate" % [label, String(pinned[0])])
		if not valid.is_empty():
			var solved: AimTuple = valid.back().aim
			_assert_true(is_equal_approx(solved.elevation_degrees, float(pinned[1])) \
					if pinned[0] == &"elevation" \
					else is_equal_approx(solved.power_percent, float(pinned[1])),
				"%s pinned %s control must be preserved" % [label, String(pinned[0])])
	host.queue_free()
	await process_frame


func _candidate_keys(candidates: Array[Dictionary]) -> Array[StringName]:
	var result: Array[StringName] = []
	for candidate in candidates:
		result.append((candidate.aim as AimTuple).stable_key())
	return result


func _complete_prediction(cannon: CannonController, bounds: AABB,
		profile: WindProfile) -> TrajectoryPrediction:
	var job := TrajectoryPredictionJob.create(cannon.get_world_3d().direct_space_state,
		cannon.get_launch_origin(), cannon.get_launch_velocity(), cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp, bounds, TrajectoryPredictionJob.COLLISION_MASK,
		true, profile, 9173, 0)
	while not job.is_complete():
		job.advance(TrajectoryPredictionJob.MAXIMUM_STEPS)
	return job.completed_prediction()
