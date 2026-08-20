class_name RuntimeDeliveryTelemetry
extends RefCounted

## Local JSON-line markers for delivery captures and explicit profiling runs.
## They never leave the process and stay silent during ordinary play.
static var _next_trace_id := 1
static var _active_fire_trace_id := 0
static var _shot_trace_ids: Dictionary = {}
static var _test_observer := Callable()
static var _command_line_mode := -1


static func enabled() -> bool:
	return _test_observer.is_valid() or _command_line_enabled()


static func _command_line_enabled() -> bool:
	if _command_line_mode >= 0:
		return _command_line_mode == 1
	for argument in OS.get_cmdline_user_args():
		if argument == "--delivery-telemetry" or argument.begins_with("--capture-screen="):
			_command_line_mode = 1
			return true
	_command_line_mode = 0
	return false


static func begin_fire_trace(details: Dictionary = {}) -> int:
	if not enabled():
		return 0
	var trace_id := _next_trace_id
	_next_trace_id += 1
	_active_fire_trace_id = trace_id
	emit_for_trace(&"fire_input_received", trace_id, details)
	return trace_id


static func active_fire_trace_id() -> int:
	return _active_fire_trace_id


static func bind_shot_trace(trace_id: int, shot_id: int) -> void:
	if trace_id > 0 and shot_id > 0:
		_shot_trace_ids[shot_id] = trace_id


static func trace_id_for_shot(shot_id: int) -> int:
	return int(_shot_trace_ids.get(shot_id, 0))


static func end_fire_trace(trace_id: int) -> void:
	if trace_id > 0 and _active_fire_trace_id == trace_id:
		_active_fire_trace_id = 0


static func emit_for_shot(
		marker: StringName,
		shot_id: int,
		details: Dictionary = {}
) -> void:
	var enriched := details.duplicate()
	enriched["shot_id"] = shot_id
	emit_for_trace(marker, trace_id_for_shot(shot_id), enriched)


static func emit_for_trace(
		marker: StringName,
		trace_id: int,
		details: Dictionary = {}
) -> void:
	var enriched := details.duplicate()
	if trace_id > 0:
		enriched["trace_id"] = trace_id
	emit_marker(marker, enriched)


static func emit_marker(marker: StringName, details: Dictionary = {}) -> Dictionary:
	if not enabled():
		return {}
	var payload := {
		"paint_mountain_marker": String(marker),
		"time_usec": Time.get_ticks_usec(),
		"physics_frame": Engine.get_physics_frames(),
		"process_frame": Engine.get_process_frames(),
		"memory_static": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"render_video_memory": int(
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
		),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
	}
	payload.merge(details, true)
	if _test_observer.is_valid():
		_test_observer.call(payload.duplicate(true))
	if _command_line_enabled():
		print(JSON.stringify(payload))
	return payload


## Tests observe the same payloads without enabling noisy command-line output.
## Production code must never install this observer.
static func set_test_observer(observer: Callable) -> void:
	_test_observer = observer


static func clear_test_observer() -> void:
	_test_observer = Callable()
	_active_fire_trace_id = 0
	_shot_trace_ids.clear()


static func test_observer_enabled() -> bool:
	return _test_observer.is_valid()
