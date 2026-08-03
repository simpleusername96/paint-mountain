class_name ReplayRecorder
extends Node

signal replay_action_ready(action: Dictionary)

const FORMAT_VERSION := 4

var attempt: Dictionary = {}
var playback_index: int = 0
var playback_paused: bool = false
var playback_speed: float = 1.0
var _recording_start_tick: int = 0


func start_attempt(
		stage_data: StageData,
		_physics_seed: int,
		generated_layout: GeneratedStageLayout
) -> bool:
	if stage_data == null or generated_layout == null \
			or not generated_layout.is_mvp_playable():
		push_error("ReplayRecorder requires the admitted generated layout.")
		attempt = {}
		reset_playback()
		return false
	var default_aim := generated_layout.default_aim
	if default_aim == null or not default_aim.is_valid():
		push_error("ReplayRecorder requires the generated default aim.")
		attempt = {}
		reset_playback()
		return false
	var certificate := generated_layout.reachability_certificate
	var has_full_certificate := certificate != null and certificate.is_valid()
	_recording_start_tick = Engine.get_physics_frames()
	attempt = {
		"format_version": FORMAT_VERSION,
		"stage_id": String(stage_data.stage_id),
		"stage_version": stage_data.stage_version,
		"generation_profile_id": String(generated_layout.profile_id),
		"generation_profile_version": generated_layout.profile_version,
		"requested_seed": generated_layout.terrain_seed,
		"accepted_seed": generated_layout.accepted_seed,
		"height_grid_checksum": generated_layout.checksum,
		"target_mask_checksum": generated_layout.target_mask_checksum,
		"reachability_checksum": (
			certificate.reachable_target_checksum if has_full_certificate else 0
		),
		"containment_checksum": generated_layout.containment.checksum(),
		"placement_checksum": generated_layout.placement_checksum(),
		"layout_admission": "certificate" if has_full_certificate else "mvp_permit",
		"generated_default_aim": {
			"yaw": default_aim.yaw_degrees,
			"elevation": default_aim.elevation_degrees,
			"power": default_aim.power_percent,
		},
		"physics_fps": 60,
		"actions": [],
		"expected_observations": [],
	}
	reset_playback()
	return true


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
	var sealed := _json_safe_dictionary(observation.to_dictionary())
	# These presentation indexes remain explicit while the sealed schema stores
	# the complete ordered facts used by deterministic replay verification.
	sealed["first_contact_point"] = [first_point.x, first_point.y, first_point.z]
	sealed["mechanism_kinds"] = Array(observation.mechanism_activation_kinds)
	sealed["total_coverage"] = observation.coverage_after
	sealed["settlement_reasons"] = _string_key_dictionary(
		observation.settlement_reason_counts
	)
	sealed["result_state"] = -1
	expected.append(sealed)


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
			or not data.has("requested_seed") \
			or not data.has("accepted_seed") \
			or not data.has("height_grid_checksum") \
			or not data.has("target_mask_checksum") \
			or not data.has("reachability_checksum") \
			or not data.has("containment_checksum") \
			or not data.has("placement_checksum") \
			or not data.has("layout_admission") \
			or not data.get("generated_default_aim", {}) is Dictionary \
			or int(data.get("physics_fps", 0)) != 60 \
			or not data.get("actions", []) is Array \
			or not data.get("expected_observations", []) is Array:
		return false
	if not _layout_metadata_is_valid(data):
		return false
	for action in data.actions:
		if not action is Dictionary or not _action_is_valid(action):
			return false
	for observation in data.expected_observations:
		if not observation is Dictionary or not _sealed_observation_is_valid(observation):
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


func _layout_metadata_is_valid(data: Dictionary) -> bool:
	if int(data.get("stage_version", 0)) != StageGenerationContract.CONTRACT_VERSION \
			or String(data.get("generation_profile_id", "")).is_empty() \
			or int(data.get("generation_profile_version", 0)) \
					!= StageGenerationContract.CONTRACT_VERSION \
			or int(data.get("requested_seed", -1)) < 0 \
			or int(data.get("accepted_seed", -1)) < 0 \
			or int(data.get("height_grid_checksum", 0)) == 0 \
			or int(data.get("target_mask_checksum", 0)) == 0 \
			or int(data.get("containment_checksum", 0)) == 0 \
			or int(data.get("placement_checksum", 0)) == 0:
		return false
	var admission := String(data.get("layout_admission", ""))
	var reachability_checksum := int(data.get("reachability_checksum", 0))
	if admission == "certificate":
		if reachability_checksum == 0:
			return false
	elif admission == "mvp_permit":
		if reachability_checksum != 0:
			return false
	else:
		return false
	var aim: Dictionary = data.get("generated_default_aim", {})
	if not aim.has("yaw") or not aim.has("elevation") or not aim.has("power"):
		return false
	var generated_aim := AimTuple.new(
		float(aim.yaw),
		float(aim.elevation),
		int(aim.power)
	)
	return generated_aim.is_valid()


func _sealed_observation_is_valid(observation: Dictionary) -> bool:
	if int(observation.get("schema_version", -1)) != ShotObservation.SCHEMA_VERSION \
			or not bool(observation.get("is_sealed", false)) \
			or int(observation.get("shot_number", 0)) <= 0 \
			or not observation.get("commanded_aim", {}) is Dictionary \
			or not observation.has("coverage_before") \
			or not observation.has("coverage_after") \
			or not observation.has("coverage_gain") \
			or not observation.get("contacts", []) is Array \
			or not observation.get("mechanism_activations", []) is Array \
			or not observation.get("child_spawns", []) is Array \
			or not observation.get("settlements", []) is Array \
			or int(observation.get("paint_command_count", -1)) < 0 \
			or not observation.get("paint_command_rejections", []) is Array \
			or int(observation.get("paint_command_rejection_count", -1)) < 0 \
			or not observation.has("final_drain_tick") \
			or int(observation.get("final_paint_mask_checksum", 0)) == 0:
		return false
	var aim: Dictionary = observation.commanded_aim
	if not aim.has("yaw") or not aim.has("elevation") or not aim.has("power"):
		return false
	if int(observation.paint_command_rejection_count) \
			!= (observation.paint_command_rejections as Array).size():
		return false
	return true


func _json_safe_value(value: Variant) -> Variant:
	if value is Vector3:
		return [value.x, value.y, value.z]
	if value is StringName:
		return String(value)
	if value is Dictionary:
		return _json_safe_dictionary(value)
	if value is Array:
		var converted: Array = []
		for entry in value:
			converted.append(_json_safe_value(entry))
		return converted
	if value is PackedInt32Array:
		return Array(value)
	return value


func _json_safe_dictionary(source: Dictionary) -> Dictionary:
	var converted := {}
	for key in source:
		converted[String(key)] = _json_safe_value(source[key])
	return converted
