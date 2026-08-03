class_name ReplayRecorder
extends Node

signal replay_action_ready(action: Dictionary)

const FORMAT_VERSION := 3

var attempt: Dictionary = {}
var playback_index: int = 0
var playback_paused: bool = false
var playback_speed: float = 1.0
var _recording_start_tick: int = 0


func start_attempt(stage_data: StageData, physics_seed: int, generated_layout: GeneratedStageLayout = null) -> void:
	_recording_start_tick = Engine.get_physics_frames()
	attempt = {
		"format_version": FORMAT_VERSION,
		"stage_id": String(stage_data.stage_id),
		"stage_version": stage_data.stage_version,
		"generation_profile_id": String(generated_layout.profile_id) if generated_layout != null else "",
		"generation_profile_version": generated_layout.profile_version if generated_layout != null else 0,
		"accepted_seed": generated_layout.accepted_seed if generated_layout != null else physics_seed,
		"height_grid_checksum": generated_layout.checksum if generated_layout != null else 0,
		"physics_fps": 60,
		"actions": [],
		"expected_observations": [],
	}
	reset_playback()


func record_aim(yaw: float, elevation: float, power: float) -> void:
	_append_action({
		"kind": "aim",
		"yaw": yaw,
		"elevation": elevation,
		"power": power,
	})


func record_fire() -> void:
	_append_action({"kind": "fire"})


func record_restart() -> void:
	_append_action({"kind": "restart"})


func record_camera(mode: int) -> void:
	_append_action({"kind": "camera", "mode": mode})


func record_observation(observation: ShotObservation) -> void:
	if attempt.is_empty() or observation == null or not observation.is_sealed:
		return
	var expected: Array = attempt.expected_observations
	var first_point := observation.first_contact.world_position if observation.first_contact != null else Vector3.ZERO
	expected.append({
		"shot_number": observation.shot_number,
		"first_contact_point": [first_point.x, first_point.y, first_point.z],
		"mechanism_kinds": Array(observation.mechanism_activation_kinds),
		"coverage_gain": observation.coverage_gain,
		"total_coverage": observation.coverage_after,
		"settlement_reasons": _string_key_dictionary(observation.settlement_reason_counts),
		"result_state": -1,
	})


func update_latest_result_state(result_state: int) -> void:
	if attempt.is_empty():
		return
	var expected: Array = attempt.expected_observations
	if not expected.is_empty():
		expected.back()["result_state"] = result_state


func load_attempt(data: Dictionary) -> bool:
	if int(data.get("format_version", -1)) != FORMAT_VERSION:
		return false
	if String(data.get("stage_id", "")).is_empty() \
			or not data.has("stage_version") \
			or not data.has("generation_profile_id") \
			or not data.has("generation_profile_version") \
			or not data.has("accepted_seed") \
			or not data.has("height_grid_checksum") \
			or int(data.get("physics_fps", 0)) != 60 \
			or not data.get("actions", []) is Array \
			or not data.get("expected_observations", []) is Array:
		return false
	for action in data.actions:
		if not action is Dictionary or not _action_is_valid(action):
			return false
	attempt = data.duplicate(true)
	reset_playback()
	return true


func export_attempt() -> Dictionary:
	return attempt.duplicate(true)


func last_shot_attempt() -> Dictionary:
	if attempt.is_empty():
		return {}
	var actions: Array = attempt.get("actions", [])
	var last_fire_index := -1
	var previous_fire_index := -1
	for index in range(actions.size()):
		if String(actions[index].get("kind", "")) == "fire":
			previous_fire_index = last_fire_index
			last_fire_index = index
	if last_fire_index < 0:
		return {}
	var start_index := previous_fire_index + 1
	var sliced: Array = []
	var has_aim := false
	for index in range(start_index, last_fire_index + 1):
		if String(actions[index].get("kind", "")) == "aim":
			has_aim = true
			break
	if not has_aim:
		for index in range(start_index - 1, -1, -1):
			if String(actions[index].get("kind", "")) == "aim":
				var inherited_aim: Dictionary = actions[index].duplicate(true)
				inherited_aim.physics_tick = int(actions[start_index].get("physics_tick", 0))
				sliced.append(inherited_aim)
				break
	var first_tick := int(actions[start_index].get("physics_tick", 0))
	for index in range(start_index, last_fire_index + 1):
		var action: Dictionary = actions[index].duplicate(true)
		action.physics_tick = int(action.physics_tick) - first_tick
		sliced.append(action)
	var result := attempt.duplicate(true)
	result.actions = sliced
	var expected: Array = attempt.get("expected_observations", [])
	result.expected_observations = [expected.back().duplicate(true)] if not expected.is_empty() else []
	return result


func reset_playback() -> void:
	playback_index = 0
	playback_paused = false
	playback_speed = 1.0


func set_playback_paused(value: bool) -> void:
	playback_paused = value


func set_playback_speed(value: float) -> void:
	playback_speed = 2.0 if value >= 1.5 else 1.0


func next_action_tick() -> int:
	var actions: Array = attempt.get("actions", [])
	if playback_index >= actions.size():
		return -1
	return int(actions[playback_index].get("physics_tick", 0))


func emit_next_action() -> bool:
	if playback_paused or attempt.is_empty():
		return false
	var actions: Array = attempt.get("actions", [])
	if playback_index >= actions.size():
		return false
	var action: Dictionary = actions[playback_index]
	playback_index += 1
	replay_action_ready.emit(action.duplicate(true))
	return true


func _append_action(fields: Dictionary) -> void:
	if attempt.is_empty():
		return
	var action := fields.duplicate(true)
	action["physics_tick"] = maxi(0, Engine.get_physics_frames() - _recording_start_tick)
	var actions: Array = attempt.actions
	actions.append(action)


func _action_is_valid(action: Dictionary) -> bool:
	if int(action.get("physics_tick", -1)) < 0:
		return false
	match String(action.get("kind", "")):
		"aim":
			return action.size() == 5 and action.has("yaw") and action.has("elevation") and action.has("power")
		"camera":
			return action.size() == 3 and action.has("mode")
		"fire", "restart":
			return action.size() == 2
		_:
			return false


func _string_key_dictionary(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[String(key)] = source[key]
	return result
