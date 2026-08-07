class_name TrajectoryPredictionScheduler
extends Node

const DYNAMIC_WIND_BUCKET_TICKS := 3

var _cannon: CannonController
var _wind_controller: WindController
var _bounds := AABB()
var _wind_profile: WindProfile
var _schedule_seed := 0
var _prediction_callback: Callable
var _consumers_enabled := false
var _dirty := true
var _hold_physics_ticks := 0
var _current_context_key: StringName = &""
var _prediction_compute_count := 0


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
	_dirty = true
	_refresh_expected_context()
	set_physics_process(_consumers_enabled)
	return true


func request_latest() -> void:
	_refresh_expected_context()


func set_consumers_enabled(enabled: bool) -> void:
	if _consumers_enabled == enabled:
		return
	_consumers_enabled = enabled
	set_physics_process(enabled)
	if enabled:
		_refresh_expected_context()
		_dirty = not _cannon.prediction_matches_expected_context()


func consumers_enabled() -> bool:
	return _consumers_enabled


func hold_refresh_for_seconds(duration_seconds: float) -> void:
	var ticks_per_second := maxi(Engine.physics_ticks_per_second, 1)
	_hold_physics_ticks = maxi(
		_hold_physics_ticks,
		ceili(maxf(duration_seconds, 0.0) * float(ticks_per_second))
	)
	_dirty = true
	_refresh_expected_context()


func prediction_compute_count() -> int:
	return _prediction_compute_count


func current_context_key() -> StringName:
	return _current_context_key


func _physics_process(_delta: float) -> void:
	if _cannon == null or _wind_controller == null:
		return
	_refresh_expected_context()
	if not _consumers_enabled:
		return
	if _hold_physics_ticks > 0:
		_hold_physics_ticks -= 1
		return
	if not _dirty and _cannon.prediction_matches_expected_context():
		return
	var launch_tick := _prediction_launch_tick()
	var prediction: TrajectoryPrediction
	_prediction_compute_count += 1
	if _prediction_callback.is_valid():
		prediction = _prediction_callback.call(
			_cannon,
			_bounds,
			_wind_profile,
			_schedule_seed,
			launch_tick
		) as TrajectoryPrediction
	else:
		prediction = TrajectoryPredictor.predict(
			_cannon.get_world_3d().direct_space_state,
			_cannon,
			_bounds,
			_wind_profile,
			_schedule_seed,
			launch_tick
		)
	_cannon.set_prediction(
		prediction,
		_cannon.aim_key(),
		_wind_controller.schedule_identity(),
		launch_tick,
		_current_context_key
	)
	_dirty = false


func _refresh_expected_context() -> void:
	if _cannon == null or _wind_controller == null:
		return
	var next_key := build_context_key(
		_cannon.aim_key(),
		_wind_controller.schedule_identity(),
		_wind_controller.prediction_epoch(
			TrajectoryPredictor.MAXIMUM_STEPS,
			DYNAMIC_WIND_BUCKET_TICKS
		)
	)
	if next_key != _current_context_key:
		_current_context_key = next_key
		_dirty = true
	_cannon.expect_prediction_context(_current_context_key)


func _prediction_launch_tick() -> int:
	var epoch := _wind_controller.prediction_epoch(
		TrajectoryPredictor.MAXIMUM_STEPS,
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
