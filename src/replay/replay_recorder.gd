class_name ReplayRecorder
extends Node

signal replay_action_ready(action: Dictionary)

const FORMAT_VERSION := 10
const DEFAULT_WIND_SCHEDULE_VERSION := 1

var attempt: Dictionary = {}
var playback_index: int = 0
var playback_paused: bool = false
var playback_speed: float = 1.0
var _recording_start_tick: int = 0
var _recorded_fire_count: int = 0
var _attempt_observation: AttemptObservation


func start_attempt(
		stage_data: StageData,
		physics_seed: int,
		generated_layout: GeneratedStageLayout,
		wind_schedule_identity: StringName = &""
) -> bool:
	if stage_data == null or generated_layout == null \
			or not generated_layout.is_runtime_ready():
		push_error("ReplayRecorder requires the runtime-ready generated layout.")
		attempt = {}
		_attempt_observation = null
		reset_playback()
		return false
	var default_aim := generated_layout.default_aim
	if default_aim == null or not default_aim.is_valid():
		push_error("ReplayRecorder requires the generated default aim.")
		attempt = {}
		_attempt_observation = null
		reset_playback()
		return false
	var certificate := generated_layout.reachability_certificate
	var has_full_certificate := certificate != null and certificate.is_valid()
	_recording_start_tick = Engine.get_physics_frames()
	_recorded_fire_count = 0
	var resolved_wind_identity := wind_schedule_identity
	if String(resolved_wind_identity).is_empty():
		resolved_wind_identity = _default_wind_schedule_identity(physics_seed)
	_attempt_observation = AttemptObservation.new()
	if not _attempt_observation.configure(
		stage_data.stage_id,
		resolved_wind_identity,
		physics_seed,
		_recording_start_tick
	):
		push_error("ReplayRecorder requires a stable wind schedule identity.")
		attempt = {}
		_attempt_observation = null
		reset_playback()
		return false
	attempt = {
		"format_version": FORMAT_VERSION,
		"stage_id": String(stage_data.stage_id),
		"stage_version": stage_data.stage_version,
		"generation_profile_id": String(generated_layout.profile_id),
		"generation_profile_version": generated_layout.profile_version,
		"terrain_seed": generated_layout.terrain_seed,
		"height_grid_checksum": generated_layout.checksum,
		"target_mask_checksum": generated_layout.target_mask_checksum,
		"coverage_metric_version": generated_layout.coverage_metric_version,
		"total_target_surface_area": generated_layout.total_target_surface_area,
		"target_surface_area_checksum": generated_layout.target_surface_area_checksum,
		"reachability_checksum": (
			certificate.reachable_target_checksum if has_full_certificate else 0
		),
		"play_bounds_checksum": generated_layout.play_bounds.checksum(),
		"placement_checksum": generated_layout.placement_checksum(),
		"layout_admission": "certificate" if has_full_certificate else "structural",
		"generated_default_aim": {
			"yaw": default_aim.yaw_degrees,
			"elevation": default_aim.elevation_degrees,
			"power": default_aim.power_percent,
		},
		"physics_fps": 60,
		"wind_schedule_identity": String(resolved_wind_identity),
		"wind_schedule_seed": physics_seed,
		"actions": [],
		"expected_observations": [],
		"final_result": {},
		"attempt_observation": _attempt_observation.to_dictionary(),
	}
	reset_playback()
	return true


func record_aim(yaw: float, elevation: float, power: float) -> void:
	var physics_tick := _append_action({
		"kind": "aim",
		"yaw": yaw,
		"elevation": elevation,
		"power": power,
	})
	if physics_tick >= 0 and _attempt_observation != null:
		_attempt_observation.record_aim(yaw, elevation, power, physics_tick)


func record_fire(shot_id: int = 0) -> void:
	# Runtime callers pass the authoritative root-family ID. Small isolated
	# recorder tests may omit it, so assign the same deterministic sequence they
	# would receive from a fresh ProjectileManager attempt.
	var resolved_shot_id := shot_id if shot_id > 0 else _recorded_fire_count + 1
	_recorded_fire_count = maxi(_recorded_fire_count, resolved_shot_id)
	var physics_tick := _append_action({"kind": "fire", "shot_id": resolved_shot_id})
	if physics_tick >= 0 and _attempt_observation != null:
		_attempt_observation.record_fire(resolved_shot_id, physics_tick)


func record_finish(reason: StringName = &"manual") -> void:
	var physics_tick := _append_action({"kind": "finish"})
	if physics_tick >= 0 and _attempt_observation != null:
		_attempt_observation.record_finish(reason, physics_tick)


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
	if _attempt_observation != null:
		_attempt_observation.record_shot_observation(observation)


func current_attempt_observation() -> AttemptObservation:
	return _attempt_observation


func store_attempt_observation(observation: AttemptObservation) -> bool:
	if attempt.is_empty() or observation == null or not AttemptObservation.dictionary_is_valid(
		observation.to_dictionary()
	):
		return false
	if observation.stage_id != StringName(String(attempt.stage_id)) \
			or observation.wind_schedule_identity \
					!= StringName(String(attempt.wind_schedule_identity)) \
			or observation.wind_schedule_seed != int(attempt.wind_schedule_seed):
		return false
	_attempt_observation = observation
	_sync_attempt_observation()
	return true


func store_final_result(
		result: Dictionary,
		observation: AttemptObservation = null
) -> bool:
	if attempt.is_empty() or not _result_dictionary_is_valid(result):
		return false
	var resolved_observation := observation if observation != null else _attempt_observation
	if resolved_observation == null or resolved_observation.stage_id \
			!= StringName(String(attempt.stage_id)) \
			or resolved_observation.wind_schedule_identity \
					!= StringName(String(attempt.wind_schedule_identity)) \
			or resolved_observation.wind_schedule_seed != int(attempt.wind_schedule_seed):
		return false
	var reason := StringName(String(
		result.get("finish_reason", result.get("result_reason", ""))
	))
	if not resolved_observation.is_sealed and not resolved_observation.seal(
		reason,
		int(result.paint_mask_checksum),
		float(result.coverage),
		int(result.elapsed_ticks)
	):
		return false
	if not _result_matches_observation(result, resolved_observation):
		return false
	_attempt_observation = resolved_observation
	attempt["final_result"] = _json_safe_dictionary(result)
	_sync_attempt_observation()
	return true


func update_latest_result_state(result_state: int) -> void:
	if attempt.is_empty():
		return
	var expected: Array = attempt.expected_observations
	for observation in expected:
		if observation is Dictionary:
			observation["result_state"] = result_state


func load_attempt(data: Dictionary) -> bool:
	if int(data.get("format_version", -1)) != FORMAT_VERSION:
		return false
	if not _is_json_safe(data):
		return false
	if String(data.get("stage_id", "")).is_empty() \
			or not data.has("stage_version") \
			or not data.has("generation_profile_id") \
			or not data.has("generation_profile_version") \
			or not data.has("terrain_seed") \
			or not data.has("height_grid_checksum") \
			or not data.has("target_mask_checksum") \
			or not data.has("coverage_metric_version") \
			or not data.has("total_target_surface_area") \
			or not data.has("target_surface_area_checksum") \
			or not data.has("reachability_checksum") \
			or not data.has("play_bounds_checksum") \
			or not data.has("placement_checksum") \
			or not data.has("layout_admission") \
			or not data.get("generated_default_aim", {}) is Dictionary \
			or int(data.get("physics_fps", 0)) != 60 \
			or String(data.get("wind_schedule_identity", "")).is_empty() \
			or not data.has("wind_schedule_seed") \
			or not data.get("actions", []) is Array \
			or not data.get("expected_observations", []) is Array \
			or not data.get("final_result", {}) is Dictionary \
			or not data.get("attempt_observation", {}) is Dictionary:
		return false
	if not _layout_metadata_is_valid(data):
		return false
	var previous_action_tick := -1
	for action in data.actions:
		if not action is Dictionary or not _action_is_valid(action) \
				or int(action.physics_tick) < previous_action_tick:
			return false
		previous_action_tick = int(action.physics_tick)
	for observation in data.expected_observations:
		if not observation is Dictionary or not _sealed_observation_is_valid(observation):
			return false
	var loaded_observation := AttemptObservation.new()
	if not loaded_observation.load_dictionary(data.attempt_observation) \
			or loaded_observation.stage_id != StringName(String(data.stage_id)) \
			or loaded_observation.wind_schedule_identity \
					!= StringName(String(data.wind_schedule_identity)) \
			or loaded_observation.wind_schedule_seed != int(data.wind_schedule_seed) \
			or not _action_observation_order_matches(data.actions, loaded_observation.events):
		return false
	var final_result: Dictionary = data.final_result
	if final_result.is_empty():
		if loaded_observation.is_sealed:
			return false
	elif not _result_dictionary_is_valid(final_result) \
			or not _result_matches_observation(final_result, loaded_observation):
		return false
	attempt = data.duplicate(true)
	_attempt_observation = loaded_observation
	_recording_start_tick = Engine.get_physics_frames()
	_recorded_fire_count = 0
	for action in attempt.actions:
		if String(action.kind) == "fire":
			_recorded_fire_count = maxi(_recorded_fire_count, int(action.shot_id))
	reset_playback()
	return true


func export_attempt() -> Dictionary:
	_sync_attempt_observation()
	return attempt.duplicate(true)


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


func _append_action(fields: Dictionary) -> int:
	if attempt.is_empty():
		return -1
	var action := fields.duplicate(true)
	action["physics_tick"] = maxi(0, Engine.get_physics_frames() - _recording_start_tick)
	var actions: Array = attempt.actions
	actions.append(action)
	return int(action.physics_tick)


func _action_is_valid(action: Dictionary) -> bool:
	if int(action.get("physics_tick", -1)) < 0:
		return false
	match String(action.get("kind", "")):
		"aim":
			return action.size() == 5 and action.has("yaw") \
					and action.has("elevation") and action.has("power") \
					and is_finite(float(action.yaw)) \
					and is_finite(float(action.elevation)) \
					and is_finite(float(action.power))
		"camera":
			return action.size() == 3 and action.has("mode")
		"restart":
			return action.size() == 2
		"fire":
			return action.size() == 3 and action.has("shot_id") and int(action.shot_id) > 0
		"finish":
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
			or int(data.get("terrain_seed", -1)) \
					!= StageProgressionData.CANONICAL_TERRAIN_SEED \
			or int(data.get("height_grid_checksum", 0)) == 0 \
			or int(data.get("target_mask_checksum", 0)) == 0 \
			or not TargetSurfaceCoverage.metadata_is_valid(
				int(data.get("coverage_metric_version", -1)),
				float(data.get("total_target_surface_area", -1.0)),
				int(data.get("target_surface_area_checksum", 0))
			) \
			or int(data.get("play_bounds_checksum", 0)) == 0 \
			or int(data.get("placement_checksum", 0)) == 0:
		return false
	var admission := String(data.get("layout_admission", ""))
	var reachability_checksum := int(data.get("reachability_checksum", 0))
	if admission == "certificate":
		if reachability_checksum == 0:
			return false
	elif admission == "structural":
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
		or int(observation.get("shot_id", 0)) <= 0 \
		or not observation.get("commanded_aim", {}) is Dictionary \
		or not observation.has("coverage_before") \
		or not observation.has("coverage_after") \
		or not observation.has("coverage_gain") \
		or int(observation.get("coverage_metric_version", -1)) \
				!= TargetSurfaceCoverage.METRIC_VERSION \
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


func _sync_attempt_observation() -> void:
	if attempt.is_empty() or _attempt_observation == null:
		return
	attempt["attempt_observation"] = _attempt_observation.to_dictionary()


func _action_observation_order_matches(actions: Array, events: Array[Dictionary]) -> bool:
	var replay_actions: Array[Dictionary] = []
	for action_variant in actions:
		var action := action_variant as Dictionary
		if action != null and String(action.get("kind", "")) in ["aim", "fire", "finish"]:
			replay_actions.append(action)
	var observed_actions: Array[Dictionary] = []
	for event in events:
		if String(event.get("kind", "")) in [
			AttemptObservation.EVENT_AIM,
			AttemptObservation.EVENT_FIRE,
			AttemptObservation.EVENT_FINISH,
		]:
			observed_actions.append(event)
	if replay_actions.size() != observed_actions.size():
		return false
	for index in range(replay_actions.size()):
		var action := replay_actions[index]
		var event := observed_actions[index]
		if String(action.kind) != String(event.kind) \
				or int(action.physics_tick) != int(event.physics_tick):
			return false
		match String(action.kind):
			"aim":
				if not is_equal_approx(float(action.yaw), float(event.yaw)) \
						or not is_equal_approx(
							float(action.elevation), float(event.elevation)
						) \
						or not is_equal_approx(float(action.power), float(event.power)):
					return false
			"fire":
				if int(action.shot_id) != int(event.shot_id):
					return false
	return true


func _result_dictionary_is_valid(result: Dictionary) -> bool:
	var reason := String(result.get("finish_reason", result.get("result_reason", "")))
	var coverage := float(result.get("coverage", -1.0))
	return _is_json_safe(_json_safe_dictionary(result)) \
			and not reason.is_empty() \
			and int(result.get("paint_mask_checksum", 0)) != 0 \
			and int(result.get("coverage_metric_version", -1)) \
					== TargetSurfaceCoverage.METRIC_VERSION \
			and is_finite(coverage) and coverage >= 0.0 and coverage <= 100.0 \
			and int(result.get("elapsed_ticks", -1)) >= 0


func _result_matches_observation(
		result: Dictionary,
		observation: AttemptObservation
) -> bool:
	if observation == null or not observation.is_sealed:
		return false
	var final := observation.final_result
	var reason := String(result.get("finish_reason", result.get("result_reason", "")))
	return (not result.has("stage_id") or String(result.stage_id) == String(observation.stage_id)) \
			and String(final.get("reason", "")) == reason \
			and int(final.get("coverage_metric_version", -1)) \
					== int(result.get("coverage_metric_version", -2)) \
			and int(final.get("paint_mask_checksum", 0)) \
					== int(result.get("paint_mask_checksum", 0)) \
			and is_equal_approx(
				float(final.get("coverage", -1.0)), float(result.get("coverage", -2.0))
			) \
			and int(final.get("elapsed_ticks", -1)) == int(result.get("elapsed_ticks", -2))


static func _default_wind_schedule_identity(schedule_seed: int) -> StringName:
	return StringName("wind-v%d-%d" % [DEFAULT_WIND_SCHEDULE_VERSION, schedule_seed])


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
	if value is PackedInt32Array or value is PackedInt64Array:
		return Array(value)
	return value


func _json_safe_dictionary(source: Dictionary) -> Dictionary:
	var converted := {}
	for key in source:
		converted[String(key)] = _json_safe_value(source[key])
	return converted


func _is_json_safe(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(float(value))
		TYPE_ARRAY:
			for entry in value:
				if not _is_json_safe(entry):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not key is String or not _is_json_safe(value[key]):
					return false
			return true
		_:
			return false
