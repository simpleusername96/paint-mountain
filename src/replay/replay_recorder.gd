class_name ReplayRecorder
extends Node

signal replay_action_ready(action: Dictionary)

const FORMAT_VERSION := 2

var attempt: Dictionary = {}
var playback_index: int = 0
var playback_paused: bool = false
var playback_speed: float = 1.0


func start_attempt(stage_data: StageData, physics_seed: int, generated_layout: GeneratedStageLayout = null) -> void:
	attempt = {
		"format_version": FORMAT_VERSION,
		"stage_id": String(stage_data.stage_id),
		"stage_version": stage_data.stage_version,
		"physics_seed": physics_seed,
		"profile_version": generated_layout.profile_version if generated_layout != null else 0,
		"terrain_seed": generated_layout.terrain_seed if generated_layout != null else physics_seed,
		"accepted_seed": generated_layout.accepted_seed if generated_layout != null else physics_seed,
		"height_grid_checksum": generated_layout.checksum if generated_layout != null else 0,
		"shots": [],
		"events": [],
	}
	reset_playback()


func record_shot(order: int, yaw: float, elevation: float, power: float) -> void:
	if attempt.is_empty():
		return
	var shots: Array = attempt.shots
	shots.append({
		"order": order,
		"yaw": yaw,
		"elevation": elevation,
		"power": power,
	})


func record_event(event_name: StringName, payload: Dictionary = {}) -> void:
	if attempt.is_empty():
		return
	var events: Array = attempt.events
	events.append({"name": String(event_name), "payload": payload.duplicate(true)})


func load_attempt(data: Dictionary) -> bool:
	var source_version := int(data.get("format_version", -1))
	if source_version not in [1, FORMAT_VERSION]:
		return false
	if not data.get("shots", []) is Array or String(data.get("stage_id", "")).is_empty():
		return false
	attempt = data.duplicate(true)
	if source_version == 1:
		attempt["format_version"] = FORMAT_VERSION
		attempt["profile_version"] = 0
		attempt["terrain_seed"] = int(attempt.get("physics_seed", 0))
		attempt["accepted_seed"] = int(attempt.get("physics_seed", 0))
		attempt["height_grid_checksum"] = 0
	reset_playback()
	return true


func export_attempt() -> Dictionary:
	return attempt.duplicate(true)


func reset_playback() -> void:
	playback_index = 0
	playback_paused = false
	playback_speed = 1.0


func set_playback_paused(value: bool) -> void:
	playback_paused = value


func set_playback_speed(value: float) -> void:
	playback_speed = 2.0 if value >= 1.5 else 1.0


func emit_next_action() -> bool:
	if playback_paused or attempt.is_empty():
		return false
	var shots: Array = attempt.get("shots", [])
	if playback_index >= shots.size():
		return false
	var action: Dictionary = shots[playback_index]
	playback_index += 1
	replay_action_ready.emit(action.duplicate(true))
	return true
