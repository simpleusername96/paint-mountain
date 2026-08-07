extends SceneTree

const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const PREDICTION_SCHEDULER := preload(
	"res://src/cannon/trajectory_prediction_scheduler.gd"
)

var _failed := false
var _fake_compute_count := 0
var _last_launch_tick := -1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cannon := CANNON_SCENE.instantiate() as CannonController
	var wind := WindController.new()
	var scheduler := PREDICTION_SCHEDULER.new()
	root.add_child(cannon)
	root.add_child(wind)
	root.add_child(scheduler)
	await process_frame

	var profile := WindProfile.new()
	profile.interval_seconds = 30.0
	profile.transition_seconds = 3.0
	_assert_true(wind.configure(profile, 9173), "wind fixture must configure")
	var roomy_bounds := AABB(
		Vector3(-10000.0, -10000.0, -10000.0),
		Vector3(20000.0, 20000.0, 20000.0)
	)
	_assert_true(
		scheduler.configure(
			cannon, wind, roomy_bounds, profile, 9173, _fake_job
		),
		"scheduler fixture must configure"
	)
	scheduler.set_consumers_enabled(true)
	scheduler._physics_process(1.0 / 60.0)
	_assert_true(
		_fake_compute_count == 1 and scheduler.active_job_count() == 1,
		"first enabled fixed tick must start exactly one prediction job"
	)
	_assert_true(
		scheduler.last_advance_step_count() \
				<= TrajectoryPredictionScheduler.MAXIMUM_STEPS_PER_TICK,
		"one fixed callback must never exceed the 24-step budget"
	)
	_assert_true(
		cannon.current_prediction() == null,
		"an incomplete job must not publish a partial arc"
	)
	_drive_until_publication(scheduler, cannon, 40)
	_assert_true(
		cannon.current_prediction() != null \
				and scheduler.prediction_publication_count() == 1,
		"one complete job must publish one atomic prediction"
	)

	var initial_context := scheduler.current_context_key()
	wind.start()
	for _tick in range(10):
		wind._physics_process(1.0 / 60.0)
		scheduler.request_latest()
		scheduler._physics_process(1.0 / 60.0)
	_assert_true(
		_fake_compute_count == 1 and scheduler.current_context_key() == initial_context,
		"stable wind must reuse the completed prediction"
	)

	# Continuous drag may nominate only one newest context per twelve scheduler
	# ticks. It never creates a queue longer than one active and one pending.
	scheduler.set_aim_interaction_active(true)
	for tick in range(36):
		cannon.set_aim(float(tick + 1), 38.0, 68.0)
		scheduler.request_latest()
		scheduler._physics_process(1.0 / 60.0)
		_assert_true(
			scheduler.last_advance_step_count() \
					<= TrajectoryPredictionScheduler.MAXIMUM_STEPS_PER_TICK,
			"interactive refresh must retain the fixed-step budget"
		)
		_assert_true(
			scheduler.active_job_count() <= 1 \
					and scheduler.pending_request_count() <= 1,
			"scheduler ownership must remain one active plus one newest pending"
		)
	_assert_true(
		_fake_compute_count <= 4,
		"thirty-six interactive ticks must nominate at most once per twelve ticks"
	)
	scheduler.set_aim_interaction_active(false)
	scheduler._physics_process(1.0 / 60.0)
	var final_aim_key := cannon.aim_key()
	_drive_until_publication(scheduler, cannon, 100)
	_assert_true(
		cannon.prediction_aim_key() == final_aim_key,
		"release must immediately nominate and eventually publish only the latest aim"
	)

	var changing_profile := WindProfile.new()
	changing_profile.interval_seconds = 13.0
	changing_profile.transition_seconds = 3.0
	var epoch0 := WindController.prediction_epoch_for(
		changing_profile, 271, 0, 720, 30
	)
	var epoch29 := WindController.prediction_epoch_for(
		changing_profile, 271, 29, 720, 30
	)
	var epoch30 := WindController.prediction_epoch_for(
		changing_profile, 271, 30, 720, 30
	)
	_assert_true(
		epoch0 == epoch29 and epoch30 == epoch0 + 1,
		"forecast-changing preview epochs must advance once per thirty physics ticks"
	)
	var stable_epoch0 := WindController.prediction_epoch_for(profile, 9173, 0, 720, 30)
	var stable_epoch120 := WindController.prediction_epoch_for(
		profile, 9173, 120, 720, 30
	)
	_assert_true(
		stable_epoch0 < 0 and stable_epoch0 == stable_epoch120,
		"stable wind must keep one negative keyframe epoch across elapsed ticks"
	)
	_assert_true(
		_last_launch_tick >= 0 \
				and scheduler.prediction_compute_count() == _fake_compute_count,
		"structural diagnostics must count only jobs actually started"
	)
	cannon.queue_free()
	wind.queue_free()
	scheduler.queue_free()
	await process_frame
	if not _failed:
		print("Prediction scheduler checks passed: 24-step jobs, latest-only coalescing, stable reuse, and 30-tick buckets.")
	quit(1 if _failed else 0)


func _drive_until_publication(
		scheduler: TrajectoryPredictionScheduler,
		cannon: CannonController,
		maximum_ticks: int
) -> void:
	var expected := cannon.aim_key()
	for _tick in range(maximum_ticks):
		if cannon.prediction_aim_key() == expected \
				and cannon.prediction_matches_expected_context():
			return
		scheduler._physics_process(1.0 / 60.0)
		_assert_true(
			scheduler.last_advance_step_count() \
					<= TrajectoryPredictionScheduler.MAXIMUM_STEPS_PER_TICK,
			"every driven callback must stay inside the step budget"
		)
	_assert_true(false, "latest prediction must complete inside the bounded fixture window")


func _fake_job(
		cannon: CannonController,
		bounds: AABB,
		profile: WindProfile,
		seed: int,
		launch_tick: int
) -> TrajectoryPredictionJob:
	_fake_compute_count += 1
	_last_launch_tick = launch_tick
	return TrajectoryPredictionJob.create(
		cannon.get_world_3d().direct_space_state,
		cannon.get_launch_origin(),
		cannon.get_launch_velocity(),
		cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp,
		bounds,
		TrajectoryPredictionJob.COLLISION_MASK,
		true,
		profile,
		seed,
		launch_tick
	)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Prediction scheduler check failed: %s" % message)
