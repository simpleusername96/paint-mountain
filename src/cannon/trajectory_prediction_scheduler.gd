class_name TrajectoryPredictionScheduler
extends Node

## Owns one bounded runtime prediction job. The newest nominated context replaces
## obsolete work; prediction is presentation-only and never gates StageController.

const MAXIMUM_STEPS_PER_TICK := 12
const MAXIMUM_WORK_USEC_PER_TICK := 1000
const AIM_NOMINATION_INTERVAL_TICKS := 12
const DYNAMIC_WIND_BUCKET_TICKS := 30

var _cannon: CannonController
var _wind_controller: WindController
var _bounds := AABB()
var _wind_profile: WindProfile
var _schedule_seed := 0
var _prediction_callback: Callable
var _consumers_enabled := false
var _aim_interaction_active := false
var _request_dirty := true
var _nominate_immediately := true
var _scheduler_tick := 0
var _last_nomination_tick := -AIM_NOMINATION_INTERVAL_TICKS
var _hold_physics_ticks := 0
var _current_context_key: StringName = &""
var _active_request: Dictionary = {}
var _active_job: TrajectoryPredictionJob
var _prediction_compute_count := 0
var _prediction_publication_count := 0
var _last_advance_step_count := 0
var _last_advance_elapsed_usec := 0
var _discarded_job_count := 0
var _target_request: Dictionary = {}
var _target_candidates: Array[Dictionary] = []
var _target_candidate_index := 0
var _target_callback: Callable
var _active_kind: StringName = &""
var _target_nominated := false
var _target_solver: TerrainAimSolver


func configure(
		cannon: CannonController,
		wind_controller: WindController,
		bounds: AABB,
		wind_profile: WindProfile,
		schedule_seed: int,
		prediction_callback: Callable = Callable()
) -> bool:
	if cannon == null or wind_controller == null or wind_profile == null \
			or not bounds.has_volume():
		return false
	_cannon = cannon
	_wind_controller = wind_controller
	_bounds = bounds
	_wind_profile = wind_profile
	_schedule_seed = schedule_seed
	_prediction_callback = prediction_callback
	_request_dirty = true
	_nominate_immediately = true
	set_physics_process(_consumers_enabled)
	return true


## Marks the live aim/wind context for coalescing. Immediate requests are used
## for stage entry, settled input, camera return, and wind-transition boundaries.
func request_latest(immediate: bool = false) -> void:
	if not immediate and _live_context_is_already_owned():
		return
	_request_dirty = true
	_nominate_immediately = _nominate_immediately or immediate \
			or not _aim_interaction_active


func set_aim_interaction_active(active: bool) -> void:
	if _aim_interaction_active == active:
		return
	_aim_interaction_active = active
	if active:
		_request_dirty = true
	else:
		request_latest(true)


func set_consumers_enabled(enabled: bool) -> void:
	if _consumers_enabled == enabled:
		return
	_consumers_enabled = enabled
	set_physics_process(enabled)
	if enabled:
		request_latest(true)
	else:
		_active_job = null
		_active_request.clear()


func consumers_enabled() -> bool:
	return _consumers_enabled


func hold_refresh_for_seconds(duration_seconds: float) -> void:
	var ticks_per_second := maxi(Engine.physics_ticks_per_second, 1)
	_hold_physics_ticks = maxi(
		_hold_physics_ticks,
		ceili(maxf(duration_seconds, 0.0) * float(ticks_per_second))
	)
	request_latest(true)


func prediction_compute_count() -> int:
	return _prediction_compute_count


func prediction_publication_count() -> int:
	return _prediction_publication_count


func current_context_key() -> StringName:
	return _current_context_key


func active_job_count() -> int:
	return 1 if _active_job != null else 0


## Replaces all older target work. constraint is &"elevation" or &"power";
## branch is an opaque low/high continuity token owned by the caller.
func request_target_solution(
		target: TerrainAimTarget,
		constraint: StringName,
		requested_value: float,
		branch: StringName,
		last_aim: AimTuple,
		revision: int,
		callback: Callable
) -> void:
	if _cannon == null or _wind_controller == null or target == null or not callback.is_valid():
		return
	_target_request = _capture_target_request(target, constraint, requested_value, branch,
		last_aim, revision)
	_target_callback = callback
	_target_candidates.clear()
	_target_candidate_index = 0
	_target_nominated = false
	if _active_job != null:
		_discarded_job_count += 1
		_active_job = null
		_active_request.clear()
		_active_kind = &""
	_publish_target(TerrainAimSolution.new(TerrainAimSolution.Status.PENDING, null, null,
		StringName(_target_request.context_key)))


func cancel_target_solution() -> void:
	if _target_request.is_empty():
		return
	if _active_kind == &"target" and _active_job != null:
		_discarded_job_count += 1
		_active_job = null
		_active_request.clear()
		_active_kind = &""
	_publish_target(TerrainAimSolution.new(
		TerrainAimSolution.Status.STALE_CONTEXT, null, null,
		StringName(_target_request.get("context_key", &"")), &"cancelled"
	))
	_clear_target_request()


func last_advance_step_count() -> int:
	return _last_advance_step_count


func last_advance_elapsed_usec() -> int:
	return _last_advance_elapsed_usec


func discarded_job_count() -> int:
	return _discarded_job_count


func _physics_process(_delta: float) -> void:
	if _cannon == null or _wind_controller == null or not _consumers_enabled:
		return
	_scheduler_tick += 1
	_last_advance_step_count = 0
	_last_advance_elapsed_usec = 0
	if _hold_physics_ticks > 0:
		_hold_physics_ticks -= 1
		return
	if not _target_request.is_empty():
		if not _target_nominated:
			_nominate_target_request()
		if _target_solver != null and not _target_solver.is_complete():
			var nomination_started := Time.get_ticks_usec()
			_target_solver.advance_until(nomination_started + MAXIMUM_WORK_USEC_PER_TICK)
			_last_advance_elapsed_usec = Time.get_ticks_usec() - nomination_started
			if not _target_solver.is_complete():
				return
			_target_candidates = _target_solver.candidates()
		if _active_job == null:
			_start_next_target_job()
		if _active_job != null:
			_advance_active_job()
		return
	if _request_dirty and _nomination_is_due():
		_nominate_live_context()
	if _active_job == null:
		return
	_advance_active_job()


func _advance_active_job() -> void:
	if _active_job == null:
		return
	var started_at := Time.get_ticks_usec()
	while _last_advance_step_count < MAXIMUM_STEPS_PER_TICK \
			and not _active_job.is_complete():
		_last_advance_step_count += _active_job.advance(1)
		if Time.get_ticks_usec() - started_at >= MAXIMUM_WORK_USEC_PER_TICK:
			break
	_last_advance_elapsed_usec = Time.get_ticks_usec() - started_at
	if not _active_job.is_complete():
		return
	if _active_kind == &"target":
		_complete_target_job()
	else:
		_complete_active_job()


func _nomination_is_due() -> bool:
	return _nominate_immediately or not _aim_interaction_active \
			or _scheduler_tick - _last_nomination_tick \
			>= AIM_NOMINATION_INTERVAL_TICKS


func _nominate_live_context() -> void:
	var request := _capture_live_request()
	var context_key := request.context_key as StringName
	_current_context_key = context_key
	_last_nomination_tick = _scheduler_tick
	_request_dirty = false
	_nominate_immediately = false
	_cannon.expect_prediction_context(context_key)
	if _active_job != null:
		if StringName(_active_request.get("context_key", &"")) != context_key:
			_discarded_job_count += 1
			_active_job = null
			_active_request.clear()
			_start_job(request)
		return
	if _cannon.prediction_key() == context_key \
			and _cannon.prediction_matches_expected_context():
		return
	_start_job(request)


func _capture_live_request() -> Dictionary:
	var launch_tick := _prediction_launch_tick()
	var aim_key := _cannon.aim_key()
	var wind_identity := _wind_controller.schedule_identity()
	var wind_epoch := _wind_controller.prediction_epoch(
		TrajectoryPredictionJob.MAXIMUM_STEPS,
		DYNAMIC_WIND_BUCKET_TICKS
	)
	return {
		"context_key": build_context_key(aim_key, wind_identity, wind_epoch),
		"aim_key": aim_key,
		"wind_identity": wind_identity,
		"launch_tick": launch_tick,
		"origin": _cannon.get_launch_origin(),
		"launch_velocity": _cannon.get_launch_velocity(),
		"projectile_radius": _cannon.projectile_data.radius,
		"linear_damp": _cannon.projectile_data.linear_damp,
	}


func _start_job(request: Dictionary) -> void:
	_active_kind = &"preview"
	_active_request = request
	_prediction_compute_count += 1
	if _prediction_callback.is_valid():
		var result: Variant = _prediction_callback.call(
			_cannon,
			_bounds,
			_wind_profile,
			_schedule_seed,
			int(request.launch_tick)
		)
		if result is TrajectoryPredictionJob:
			_active_job = result as TrajectoryPredictionJob
		elif result is TrajectoryPrediction:
			_active_job = TrajectoryPredictionJob.completed(
				result as TrajectoryPrediction
			)
		else:
			_active_job = TrajectoryPredictionJob.create(
				null, Vector3.ZERO, Vector3.ZERO, 0.0, 0.0, _bounds
			)
		return
	_active_job = TrajectoryPredictionJob.create(
		_cannon.get_world_3d().direct_space_state,
		request.origin as Vector3,
		request.launch_velocity as Vector3,
		float(request.projectile_radius),
		float(request.linear_damp),
		_bounds,
		TrajectoryPredictionJob.COLLISION_MASK,
		true,
		_wind_profile,
		_schedule_seed,
		int(request.launch_tick)
	)


func _complete_active_job() -> void:
	var finished_request := _active_request.duplicate()
	var finished_job := _active_job
	_active_request = {}
	_active_job = null
	_active_kind = &""
	var finished_key := StringName(finished_request.get("context_key", &""))
	var live_key := _live_context_key()
	if finished_key == live_key:
		var prediction := finished_job.completed_prediction()
		if prediction != null:
			_cannon.set_prediction(
				prediction,
				StringName(finished_request.aim_key),
				StringName(finished_request.wind_identity),
				int(finished_request.launch_tick),
				finished_key
			)
			_prediction_publication_count += 1
	if finished_key != live_key:
		_request_dirty = true


func _capture_target_request(
		target: TerrainAimTarget, constraint: StringName, requested_value: float,
		branch: StringName, last_aim: AimTuple, revision: int
) -> Dictionary:
	var launch_tick := _prediction_launch_tick()
	var wind_identity := _wind_controller.schedule_identity()
	var wind_epoch := _wind_controller.prediction_epoch(
		TrajectoryPredictionJob.MAXIMUM_STEPS, DYNAMIC_WIND_BUCKET_TICKS
	)
	return {
		"target": target,
		"constraint": constraint,
		"requested_value": requested_value,
		"branch": branch,
		"last_aim": last_aim,
		"revision": revision,
		"launch_tick": launch_tick,
		"wind_identity": wind_identity,
		"wind_epoch": wind_epoch,
		"context_key": StringName("target:%s|%d|%s|%d" % [
			String(target.revision_key), revision, String(wind_identity), wind_epoch
		]),
	}


func _start_next_target_job() -> void:
	if _target_request.is_empty():
		return
	if _target_candidate_index >= _target_candidates.size():
		_publish_target(TerrainAimSolution.new(
			TerrainAimSolution.Status.NO_SOLUTION, null, null,
			StringName(_target_request.context_key), &"no_verified_candidate"
		))
		_clear_target_request()
		return
	var candidate := _target_candidates[_target_candidate_index]
	_target_candidate_index += 1
	var aim: AimTuple = candidate.aim
	_active_kind = &"target"
	_active_request = {
		"aim": aim,
		"context_key": _target_request.context_key,
		"launch_tick": _target_request.launch_tick,
	}
	_prediction_compute_count += 1
	_active_job = TrajectoryPredictionJob.create(
		_cannon.get_world_3d().direct_space_state,
		_cannon.get_launch_origin_for(aim.yaw_degrees, aim.elevation_degrees),
		CannonBallistics.launch_velocity(_cannon.projectile_data, aim.yaw_degrees,
			aim.elevation_degrees, float(aim.power_percent)),
		_cannon.projectile_data.radius, _cannon.projectile_data.linear_damp, _bounds,
		TrajectoryPredictionJob.COLLISION_MASK, true, _wind_profile, _schedule_seed,
		int(_target_request.launch_tick)
	)


func _complete_target_job() -> void:
	var finished_job := _active_job
	var finished_request := _active_request.duplicate()
	_active_job = null
	_active_request.clear()
	_active_kind = &""
	if _target_request.is_empty() or StringName(finished_request.context_key) \
			!= StringName(_target_request.context_key) or not _target_context_is_current():
		if not _target_request.is_empty():
			_target_nominated = false
			_target_candidates.clear()
			_target_candidate_index = 0
		return
	var prediction := finished_job.completed_prediction()
	var target: TerrainAimTarget = _target_request.target
	if TerrainAimSolver.validates_target(prediction, target, _cannon.projectile_data.radius):
		var aim := finished_request.aim as AimTuple
		var forward_context := build_context_key(
			aim.stable_key(), _wind_controller.schedule_identity(),
			_wind_controller.prediction_epoch(TrajectoryPredictionJob.MAXIMUM_STEPS,
				DYNAMIC_WIND_BUCKET_TICKS)
		)
		var accepted := _publish_target(TerrainAimSolution.new(TerrainAimSolution.Status.VALID,
			finished_request.aim as AimTuple, prediction,
			forward_context))
		if accepted and _target_context_is_current() and _cannon.aim_key() == aim.stable_key():
			_cannon.expect_prediction_context(forward_context)
			_cannon.set_prediction(prediction, aim.stable_key(), _wind_controller.schedule_identity(),
				int(finished_request.launch_tick), forward_context)
			_prediction_publication_count += 1
		_clear_target_request()
		return
	_start_next_target_job()


func _target_context_is_current() -> bool:
	if _target_request.is_empty():
		return false
	return StringName(_target_request.wind_identity) == _wind_controller.schedule_identity() \
		and int(_target_request.wind_epoch) == _wind_controller.prediction_epoch(
			TrajectoryPredictionJob.MAXIMUM_STEPS, DYNAMIC_WIND_BUCKET_TICKS
		)


func _publish_target(solution: TerrainAimSolution) -> bool:
	if _target_callback.is_valid():
		var result: Variant = _target_callback.call(solution)
		return result is bool and result
	return false


func _clear_target_request() -> void:
	_target_request.clear()
	_target_candidates.clear()
	_target_candidate_index = 0
	_target_nominated = false
	_target_solver = null
	_target_callback = Callable()


func _nominate_target_request() -> void:
	# Capture the newest wind epoch on the bounded scheduler tick, never in input.
	_target_request = _capture_target_request(
		_target_request.target as TerrainAimTarget,
		StringName(_target_request.constraint), float(_target_request.requested_value),
		StringName(_target_request.branch), _target_request.last_aim as AimTuple,
		int(_target_request.revision)
	)
	_target_solver = TerrainAimSolver.new()
	_target_solver.begin(_cannon, _target_request.target as TerrainAimTarget,
		StringName(_target_request.constraint), float(_target_request.requested_value),
		StringName(_target_request.branch), _target_request.last_aim as AimTuple,
		_wind_profile, _schedule_seed, int(_target_request.launch_tick))
	_target_candidates = _target_solver.candidates()
	_target_candidate_index = 0
	_target_nominated = true


func _live_context_key() -> StringName:
	return build_context_key(
		_cannon.aim_key(),
		_wind_controller.schedule_identity(),
		_wind_controller.prediction_epoch(
			TrajectoryPredictionJob.MAXIMUM_STEPS,
			DYNAMIC_WIND_BUCKET_TICKS
		)
	)


func _live_context_is_already_owned() -> bool:
	if _cannon == null or _wind_controller == null or not _consumers_enabled:
		return false
	var live_key := _live_context_key()
	if live_key != _current_context_key:
		return false
	if _active_job != null \
			and StringName(_active_request.get("context_key", &"")) == live_key:
		return true
	return _cannon.prediction_key() == live_key \
			and _cannon.prediction_matches_expected_context()


func _prediction_launch_tick() -> int:
	var epoch := _wind_controller.prediction_epoch(
		TrajectoryPredictionJob.MAXIMUM_STEPS,
		DYNAMIC_WIND_BUCKET_TICKS
	)
	return _wind_controller.elapsed_ticks() \
			if epoch < 0 else epoch * DYNAMIC_WIND_BUCKET_TICKS


static func build_context_key(
		aim_key: StringName,
		wind_schedule_identity: StringName,
		wind_epoch: int
) -> StringName:
	return StringName("%s|%s|%d" % [
		String(aim_key),
		String(wind_schedule_identity),
		wind_epoch,
	])
