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
	_assert_true(
		scheduler.configure(
			cannon,
			wind,
			AABB(Vector3(-100.0, -20.0, -220.0), Vector3(200.0, 180.0, 260.0)),
			profile,
			9173,
			_fake_predict
		),
		"scheduler fixture must configure"
	)
	scheduler.set_consumers_enabled(true)
	scheduler._physics_process(1.0 / 60.0)
	_assert_true(_fake_compute_count == 1, "first enabled physics tick must publish one prediction")
	_assert_true(cannon.current_prediction() != null, "published context must become current")

	var initial_context: StringName = scheduler.current_context_key()
	wind.start()
	for _tick in range(10):
		wind._physics_process(1.0 / 60.0)
		scheduler.request_latest()
		scheduler._physics_process(1.0 / 60.0)
	_assert_true(
		_fake_compute_count == 1 and scheduler.current_context_key() == initial_context,
		"unchanged wind across the full prediction horizon must reuse one stable context"
	)

	cannon.set_aim(1.0, 38.0, 68.0)
	scheduler.request_latest()
	cannon.set_aim(2.0, 38.0, 68.0)
	scheduler.request_latest()
	cannon.set_aim(3.0, 38.0, 68.0)
	scheduler.request_latest()
	_assert_true(_fake_compute_count == 1, "several aim changes must not query before physics")
	scheduler._physics_process(1.0 / 60.0)
	_assert_true(
		_fake_compute_count == 2 and cannon.prediction_aim_key() == cannon.aim_key(),
		"one physics tick must publish only the latest aim"
	)

	scheduler.set_consumers_enabled(false)
	cannon.set_aim(4.0, 38.0, 68.0)
	scheduler.request_latest()
	scheduler._physics_process(1.0 / 60.0)
	_assert_true(_fake_compute_count == 2, "suspended consumers must not query")
	scheduler.set_consumers_enabled(true)
	scheduler._physics_process(1.0 / 60.0)
	_assert_true(_fake_compute_count == 3, "resume must publish the newest pending context once")

	var changing_profile := WindProfile.new()
	changing_profile.interval_seconds = 13.0
	changing_profile.transition_seconds = 3.0
	var epoch0 := WindController.prediction_epoch_for(changing_profile, 271, 0, 720, 3)
	var epoch1 := WindController.prediction_epoch_for(changing_profile, 271, 1, 720, 3)
	var epoch2 := WindController.prediction_epoch_for(changing_profile, 271, 2, 720, 3)
	var epoch3 := WindController.prediction_epoch_for(changing_profile, 271, 3, 720, 3)
	_assert_true(
		epoch0 == epoch1 and epoch1 == epoch2 and epoch3 == epoch0 + 1,
		"changing-wind prediction epochs must advance once per three physics ticks"
	)
	var stable_epoch0 := WindController.prediction_epoch_for(profile, 9173, 0, 720, 3)
	var stable_epoch120 := WindController.prediction_epoch_for(profile, 9173, 120, 720, 3)
	_assert_true(
		stable_epoch0 < 0 and stable_epoch0 == stable_epoch120,
		"stable wind must keep one negative keyframe epoch across elapsed ticks"
	)

	_assert_true(
		_last_launch_tick >= 0 and scheduler.prediction_compute_count() == _fake_compute_count,
		"scheduler diagnostics must count only actual prediction callback calls"
	)
	cannon.queue_free()
	wind.queue_free()
	scheduler.queue_free()
	await process_frame
	if not _failed:
		print("Prediction scheduler checks passed: fixed-physics latest-key work, stable reuse, buckets, and suspension.")
	quit(1 if _failed else 0)


func _fake_predict(
		_cannon: CannonController,
		_bounds: AABB,
		_profile: WindProfile,
		_seed: int,
		launch_tick: int
) -> TrajectoryPrediction:
	_fake_compute_count += 1
	_last_launch_tick = launch_tick
	return TrajectoryPrediction.new(
		TrajectoryPrediction.Kind.COLLISION,
		Vector3(0.0, 1.0, -10.0),
		PackedVector3Array([Vector3.ZERO, Vector3(0.0, 1.0, -10.0)]),
		1.0
	)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Prediction scheduler check failed: %s" % message)
