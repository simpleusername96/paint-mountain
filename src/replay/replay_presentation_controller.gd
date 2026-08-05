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
var _wind_controller: WindController
var _playback_elapsed_ticks: int = 0
var _first_action_tick: int = 0
var _finished: bool = false
var _source_attempt: Dictionary = {}
var _observation_index: int = 0
var _expects_final_result: bool = false
var _result_verified: bool = false


func configure(
		recorder: ReplayRecorder,
		stage_controller: StageController,
		camera_director: CameraDirector,
		wind_controller: WindController = null
) -> void:
	_recorder = recorder
	_stage_controller = stage_controller
	_camera_director = camera_director
	_wind_controller = wind_controller
	if _wind_controller == null and get_parent() != null:
		_wind_controller = get_parent().get_node_or_null("WindController") as WindController
	if not _recorder.replay_action_ready.is_connected(_on_replay_action_ready):
		_recorder.replay_action_ready.connect(_on_replay_action_ready)
	if not _stage_controller.shot_observation_sealed.is_connected(_on_shot_observation_sealed):
		_stage_controller.shot_observation_sealed.connect(_on_shot_observation_sealed)
	if not _stage_controller.stage_finished.is_connected(_on_stage_finished):
		_stage_controller.stage_finished.connect(_on_stage_finished)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(false)


func start(attempt: Dictionary) -> bool:
	if active or _recorder == null or _stage_controller == null or _camera_director == null:
		return false
	var previous_attempt := _recorder.export_attempt()
	if not _recorder.load_attempt(attempt):
		incompatible_attempt.emit(&"replay.incompatible_format")
		return false
	if _wind_controller == null \
			or _wind_controller.schedule_identity() \
					!= StringName(String(attempt.get("wind_schedule_identity", ""))):
		_restore_recorder_attempt(previous_attempt)
		incompatible_attempt.emit(&"replay.incompatible_wind_schedule")
		return false
	if not _stage_controller.lock_action_origin(StageController.ActionOrigin.REPLAY):
		_restore_recorder_attempt(previous_attempt)
		return false
	_source_attempt = attempt.duplicate(true)
	_finished = false
	_observation_index = 0
	var source_result: Dictionary = _source_attempt.get("final_result", {})
	_expects_final_result = not source_result.is_empty()
	_result_verified = not _expects_final_result
	_recorder.reset_playback()
	_first_action_tick = maxi(0, _recorder.next_action_tick())
	_playback_elapsed_ticks = 0
	active = true
	if not _stage_controller.restart(false, StageController.ActionOrigin.REPLAY):
		active = false
		_stage_controller.release_action_origin(StageController.ActionOrigin.REPLAY)
		_source_attempt.clear()
		_restore_recorder_attempt(previous_attempt)
		return false
	_wind_controller.reset()
	Engine.time_scale = 1.0
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
	if _wind_controller != null:
		_wind_controller.reset()
	_stage_controller.release_action_origin(StageController.ActionOrigin.REPLAY)
	active = false
	_finished = false
	_observation_index = 0
	_expects_final_result = false
	_result_verified = false
	Engine.time_scale = 1.0
	active_changed.emit(false)
	presentation_exited.emit()
	return true


func set_paused(value: bool) -> bool:
	if not active:
		return false
	_recorder.set_playback_paused(value)
	get_tree().paused = value
	return true


func set_speed(value: float) -> bool:
	if not active:
		return false
	_recorder.set_playback_speed(value)
	Engine.time_scale = _recorder.playback_speed
	return true


func restart_playback() -> bool:
	if not active:
		return false
	_recorder.reset_playback()
	_first_action_tick = maxi(0, _recorder.next_action_tick())
	_playback_elapsed_ticks = 0
	_finished = false
	_observation_index = 0
	var source_result: Dictionary = _source_attempt.get("final_result", {})
	_expects_final_result = not source_result.is_empty()
	_result_verified = not _expects_final_result
	if not _stage_controller.restart(false, StageController.ActionOrigin.REPLAY):
		return false
	_wind_controller.reset()
	Engine.time_scale = 1.0
	return true


func source_attempt() -> Dictionary:
	return _source_attempt.duplicate(true)


func _physics_process(_delta: float) -> void:
	if not active or _finished or _recorder.playback_paused:
		return
	# Actions recorded on the same fixed tick must replay on the same fixed tick.
	# Delaying one action per frame changes wind, projectile motion, and Finish.
	while not _finished:
		var next_tick := _recorder.next_action_tick()
		if next_tick < 0:
			break
		var due := maxi(next_tick - _first_action_tick, 0)
		if _playback_elapsed_ticks < due or not _recorder.emit_next_action():
			break
	_playback_elapsed_ticks += 1
	if _finished or _recorder.next_action_tick() >= 0:
		return
	var expected: Array = _recorder.attempt.get("expected_observations", [])
	if _observation_index >= expected.size() and _result_verified:
		_finished = true
		playback_finished.emit()


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
			if accepted and int(action.get("shot_id", 0)) > 0:
				var observation := _stage_controller.current_shot_observation()
				if observation == null or observation.shot_id != int(action.shot_id):
					_fail_playback("Replay shot family identity changed at tick %d." % action.get("physics_tick", -1))
					accepted = false
		"restart":
			accepted = _stage_controller.restart(false, StageController.ActionOrigin.REPLAY)
			if accepted:
				_wind_controller.reset()
		"camera":
			var mode := int(action.mode)
			accepted = mode >= 0 and mode < CameraDirector.InteractionMode.size()
			if accepted:
				accepted = _camera_director.set_interaction_mode(
					mode as CameraDirector.InteractionMode
				)
		"finish":
			accepted = _stage_controller.finish_stage(StageController.ActionOrigin.REPLAY)
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
	var expected_shot_id := int(expected.get("shot_id", 0))
	if expected_shot_id > 0 and observation.shot_id != expected_shot_id:
		_fail_playback("Replay shot family identity changed while sealing the attempt.")


func _on_stage_finished(result: Dictionary) -> void:
	if not active:
		return
	if not _expects_final_result:
		_fail_playback("Replay produced a result that is absent from the source attempt.")
		return
	var expected: Dictionary = _source_attempt.get("final_result", {})
	var expected_reason := String(expected.get("finish_reason", expected.get("result_reason", "")))
	var actual_reason := String(result.get("finish_reason", result.get("result_reason", "")))
	if expected_reason != actual_reason:
		_fail_playback("Replay finish reason changed.")
		return
	if int(expected.get("paint_mask_checksum", 0)) \
			!= int(result.get("paint_mask_checksum", -1)):
		_fail_playback("Replay authoritative paint checksum changed.")
		return
	if not is_equal_approx(
		float(expected.get("coverage", -1.0)),
		float(result.get("coverage", -2.0))
	):
		_fail_playback("Replay authoritative coverage changed.")
		return
	var expected_observations: Array = _source_attempt.get("expected_observations", [])
	if _observation_index != expected_observations.size():
		_fail_playback("Replay result arrived before every source shot was sealed.")
		return
	_result_verified = true


func _fail_playback(message: String) -> void:
	_finished = true
	_recorder.set_playback_paused(true)
	get_tree().paused = true
	playback_error.emit(message)


func _restore_recorder_attempt(previous_attempt: Dictionary) -> void:
	if not previous_attempt.is_empty():
		_recorder.load_attempt(previous_attempt)
