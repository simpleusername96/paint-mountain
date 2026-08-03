class_name ReplayPresentationController
extends Node

signal active_changed(active: bool)
signal playback_finished
signal presentation_exited
signal incompatible_attempt(message_key: StringName)
signal playback_error(message: String)

var active: bool = false
var _recorder: ReplayRecorder
var _stage_controller: StageController
var _camera_director: CameraDirector
var _playback_start_tick: int = 0
var _first_action_tick: int = 0
var _finished: bool = false
var _source_attempt: Dictionary = {}
var _observation_index: int = 0
var _pending_result_state: int = -1


func configure(
		recorder: ReplayRecorder,
		stage_controller: StageController,
		camera_director: CameraDirector
) -> void:
	_recorder = recorder
	_stage_controller = stage_controller
	_camera_director = camera_director
	if not _recorder.replay_action_ready.is_connected(_on_replay_action_ready):
		_recorder.replay_action_ready.connect(_on_replay_action_ready)
	if not _stage_controller.shot_observation_sealed.is_connected(_on_shot_observation_sealed):
		_stage_controller.shot_observation_sealed.connect(_on_shot_observation_sealed)
	if not _stage_controller.state_changed.is_connected(_on_stage_state_changed):
		_stage_controller.state_changed.connect(_on_stage_state_changed)
	set_physics_process(false)


func start(attempt: Dictionary) -> bool:
	if active or _recorder == null or _stage_controller == null or _camera_director == null:
		return false
	if not _recorder.load_attempt(attempt):
		incompatible_attempt.emit(&"replay.incompatible_format")
		return false
	if not _stage_controller.lock_action_origin(StageController.ActionOrigin.REPLAY):
		return false
	_source_attempt = attempt.duplicate(true)
	active = true
	_finished = false
	_observation_index = 0
	_pending_result_state = -1
	_recorder.reset_playback()
	_first_action_tick = maxi(0, _recorder.next_action_tick())
	_playback_start_tick = Engine.get_physics_frames()
	_stage_controller.restart(false, StageController.ActionOrigin.REPLAY)
	active_changed.emit(true)
	set_physics_process(true)
	return true


func exit() -> bool:
	if not active:
		return false
	set_physics_process(false)
	_recorder.set_playback_paused(false)
	_recorder.set_playback_speed(1.0)
	_stage_controller.restart(true, StageController.ActionOrigin.REPLAY)
	_stage_controller.release_action_origin(StageController.ActionOrigin.REPLAY)
	active = false
	_finished = false
	_observation_index = 0
	_pending_result_state = -1
	Engine.time_scale = 1.0
	active_changed.emit(false)
	presentation_exited.emit()
	return true


func set_paused(value: bool) -> bool:
	if not active:
		return false
	_recorder.set_playback_paused(value)
	return true


func set_speed(value: float) -> bool:
	if not active:
		return false
	_recorder.set_playback_speed(value)
	return true


func restart_playback() -> bool:
	if not active:
		return false
	_recorder.reset_playback()
	_first_action_tick = maxi(0, _recorder.next_action_tick())
	_playback_start_tick = Engine.get_physics_frames()
	_finished = false
	_stage_controller.restart(false, StageController.ActionOrigin.REPLAY)
	return true


func source_attempt() -> Dictionary:
	return _source_attempt.duplicate(true)


func _physics_process(_delta: float) -> void:
	if not active or _finished or _recorder.playback_paused:
		return
	var next_tick := _recorder.next_action_tick()
	if next_tick < 0:
		var expected: Array = _recorder.attempt.get("expected_observations", [])
		if _observation_index >= expected.size() and _pending_result_state < 0:
			_finished = true
			playback_finished.emit()
		return
	var elapsed := Engine.get_physics_frames() - _playback_start_tick
	var due := roundi(float(next_tick - _first_action_tick) / _recorder.playback_speed)
	if elapsed >= due:
		_recorder.emit_next_action()


func _on_replay_action_ready(action: Dictionary) -> void:
	var accepted := false
	match String(action.get("kind", "")):
		"aim":
			accepted = _stage_controller.set_aim(
				float(action.yaw), float(action.elevation), float(action.power),
				StageController.ActionOrigin.REPLAY
			)
		"fire":
			accepted = _stage_controller.request_fire(StageController.ActionOrigin.REPLAY)
		"restart":
			accepted = _stage_controller.restart(false, StageController.ActionOrigin.REPLAY)
		"camera":
			var mode := int(action.mode)
			accepted = mode >= 0 and mode < CameraDirector.Mode.size()
			if accepted:
				_camera_director.set_mode(mode as CameraDirector.Mode)
	if not accepted:
		_fail_playback("Replay action '%s' was rejected at tick %d." % [action.get("kind", ""), action.get("physics_tick", -1)])


func _on_shot_observation_sealed(observation: ShotObservation) -> void:
	if not active or observation == null:
		return
	var expected_observations: Array = _recorder.attempt.get("expected_observations", [])
	if _observation_index >= expected_observations.size():
		_fail_playback("Replay produced an unexpected extra shot observation.")
		return
	var expected: Dictionary = expected_observations[_observation_index]
	_observation_index += 1
	var expected_point_data: Array = expected.get("first_contact_point", [])
	if expected_point_data.size() != 3 or observation.first_contact == null:
		_fail_playback("Replay first-contact evidence is incomplete.")
		return
	var expected_point := Vector3(float(expected_point_data[0]), float(expected_point_data[1]), float(expected_point_data[2]))
	if observation.first_contact.world_position.distance_to(expected_point) > 0.5:
		_fail_playback("Replay first contact exceeded the 0.5 m tolerance.")
		return
	if absf(observation.coverage_gain - float(expected.get("coverage_gain", -1000.0))) > 0.1 \
			or absf(observation.coverage_after - float(expected.get("total_coverage", -1000.0))) > 0.1:
		_fail_playback("Replay coverage exceeded the 0.1 percentage-point tolerance.")
		return
	if Array(observation.mechanism_activation_kinds) != Array(expected.get("mechanism_kinds", [])):
		_fail_playback("Replay mechanism activation order changed.")
		return
	if _normalized_reasons(observation.settlement_reason_counts) != _normalized_reasons(expected.get("settlement_reasons", {})):
		_fail_playback("Replay projectile settlement reasons changed.")
		return
	_pending_result_state = int(expected.get("result_state", -1))


func _on_stage_state_changed(current_state: int, previous_state: int) -> void:
	if not active or previous_state != StageController.State.SHOT_RESULT or _pending_result_state < 0:
		return
	if current_state != _pending_result_state:
		_fail_playback("Replay final result state changed.")
		return
	_pending_result_state = -1


func _normalized_reasons(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[String(key)] = int(source[key])
	return result


func _fail_playback(message: String) -> void:
	_finished = true
	_recorder.set_playback_paused(true)
	playback_error.emit(message)
