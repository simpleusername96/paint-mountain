extends Node

const BACKGROUND_CAPTURE_SIZE := Vector2i(1280, 720)
const BACKGROUND_CAPTURE_POSITION := Vector2i(-32000, -32000)
const RESPONSIVENESS_WARMUP_FRAMES := 24
const RESPONSIVENESS_TRANSITION_FRAMES := 6
const RESPONSIVENESS_FLIGHT_FRAME_BUDGET := 720
const RESPONSIVENESS_REQUIRED_SWEEPS := 120

var _app: AppRoot
var _screen: String = ""
var _output_path: String = ""
var _responsiveness_output_path: String = ""
var _background_capture := false
var _failed: bool = false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-screen="):
			_screen = argument.trim_prefix("--capture-screen=")
		elif argument.begins_with("--capture-output="):
			_output_path = argument.trim_prefix("--capture-output=")
		elif argument.begins_with("--responsiveness-output="):
			_responsiveness_output_path = argument.trim_prefix("--responsiveness-output=")
		elif argument == "--capture-background":
			_background_capture = true
	if _responsiveness_output_path.is_empty() and (_screen.is_empty() or _output_path.is_empty()):
		return
	_configure_capture_window()
	_app = get_parent() as AppRoot
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _responsiveness_output_path.is_empty():
		_run_responsiveness_probe.call_deferred()
	else:
		_run_capture.call_deferred()


func _run_capture() -> void:
	_configure_capture_window()
	var game_state := get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.initialize_from_data(get_node("/root/SaveSystem").default_data())
	match _screen:
		"main_menu":
			_app._show_main_menu()
		"stage_select":
			_app._show_stage_select()
		"stage_briefing":
			await _start_stage(&"first_descent", false)
		"aiming":
			await _start_stage(&"first_descent", true)
			# Capture the stable aiming surface after the real first-session hint has
			# completed, rather than hiding or bypassing a reachable UI state.
			await get_tree().create_timer(4.2).timeout
		"aiming_burst":
			await _start_stage(&"burst_basin", true)
			await get_tree().create_timer(4.2).timeout
		"aiming_split":
			await _start_stage(&"split_ridge", true)
			await get_tree().create_timer(4.2).timeout
		"projectile_and_continuous_paint":
			await _capture_continuous_paint()
		"stage_clear":
			await _capture_clear()
		"stage_failed":
			await _capture_failure()
		_:
			push_error("Unknown delivery capture screen: %s" % _screen)
			get_tree().quit(1)
			return
	Engine.time_scale = 1.0
	if _failed:
		get_tree().quit(1)
		return
	for _frame in range(42):
		await get_tree().process_frame
	var absolute_path := ProjectSettings.globalize_path(_output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var image := get_viewport().get_texture().get_image()
	if image.is_empty() or image.get_width() <= 0 or image.get_height() <= 0:
		_fail_capture("The running renderer returned an empty capture image")
		get_tree().quit(1)
		return
	var error := image.save_png(absolute_path)
	print("Delivery capture %s -> %s (%dx%d, %s)" % [_screen, absolute_path, image.get_width(), image.get_height(), error_string(error)])
	get_tree().quit(0 if error == OK else 1)


func _configure_capture_window() -> void:
	if not _background_capture:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	# This remains a real Windows/Compatibility-renderer window. Keeping it
	# windowed, non-focusable, and outside the desktop lets UI work inspect the
	# actual runtime image without taking over the user's screen.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_size(BACKGROUND_CAPTURE_SIZE)
	DisplayServer.window_set_position(BACKGROUND_CAPTURE_POSITION)


## Collects real Compatibility-renderer timing without taking focus or occupying
## visible desktop space. This is delivery telemetry, not a gameplay subsystem.
func _run_responsiveness_probe() -> void:
	if not _background_capture:
		_fail_capture("responsiveness telemetry requires --capture-background")
		get_tree().quit(1)
		return
	_configure_capture_window()
	var game_state := get_node("/root/GameState")
	game_state.persistence_enabled = false
	var data: Dictionary = get_node("/root/SaveSystem").default_data()
	data.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(data)
	for _frame in range(RESPONSIVENESS_WARMUP_FRAMES):
		await get_tree().process_frame

	var transition_results := {}
	transition_results["main_to_stage_select"] = await _measure_transition(
		func() -> void: _app._show_stage_select()
	)
	transition_results["stage_select_to_main"] = await _measure_transition(
		func() -> void: _app._show_main_menu()
	)

	var stage_start_usec := Time.get_ticks_usec()
	_app._start_stage(&"first_descent")
	var stage_start_call_ms := float(Time.get_ticks_usec() - stage_start_usec) / 1000.0
	var gameplay := _app.get_node_or_null("ActiveGameplay") as Node3D
	if gameplay == null:
		_fail_capture("responsiveness probe could not create ActiveGameplay")
		get_tree().quit(1)
		return
	var readiness_samples := PackedFloat64Array()
	var readiness_started_usec := stage_start_usec
	var previous_usec := Time.get_ticks_usec()
	var readiness_budget := 360
	var cannon := gameplay.get_node("Cannon") as CannonController
	while cannon.current_prediction() == null and readiness_budget > 0:
		await get_tree().process_frame
		var now_usec := Time.get_ticks_usec()
		readiness_samples.append(float(now_usec - previous_usec) / 1000.0)
		previous_usec = now_usec
		readiness_budget -= 1
	if readiness_budget <= 0 or cannon.current_prediction() == null:
		_fail_capture("gameplay did not become aim-ready inside the bounded probe")
		get_tree().quit(1)
		return
	transition_results["stage_start"] = {
		"call_ms": stage_start_call_ms,
		"ready_ms": float(Time.get_ticks_usec() - readiness_started_usec) / 1000.0,
		"frames": _frame_stats(readiness_samples),
	}

	var controller := gameplay.get_node("StageController") as StageController
	var paint := gameplay.get_node("PaintSystem") as PaintSystem
	var projectiles := gameplay.get_node("ProjectileManager") as ProjectileManager
	controller.begin_aiming()
	var observed := {
		"drains": 0,
		"commands": 0,
		"sweeps": 0,
		"written_pixels": 0,
	}
	paint.paint_commands_drained.connect(
		func(_tick: int, command_count: int, _checksum: int) -> void:
			observed.drains += 1
			observed.commands += command_count
	)
	paint.paint_command_applied.connect(
		func(command, written_pixel_count: int, _newly_painted_pixel_count: int) -> void:
			observed.written_pixels += written_pixel_count
			if command is SurfacePaintSweep:
				observed.sweeps += 1
	)
	var initial_uploads := paint.texture_upload_batch_count()
	if not controller.request_fire():
		_fail_capture("runtime default aim could not fire during responsiveness probe")
		get_tree().quit(1)
		return
	var flight_samples := PackedFloat64Array()
	var drain_frame_samples := PackedFloat64Array()
	var nondrain_frame_samples := PackedFloat64Array()
	previous_usec = Time.get_ticks_usec()
	var frame_budget := RESPONSIVENESS_FLIGHT_FRAME_BUDGET
	while frame_budget > 0:
		var drains_before_frame := int(observed.drains)
		await get_tree().process_frame
		var now_usec := Time.get_ticks_usec()
		var frame_ms := float(now_usec - previous_usec) / 1000.0
		flight_samples.append(frame_ms)
		if int(observed.drains) > drains_before_frame:
			drain_frame_samples.append(frame_ms)
		else:
			nondrain_frame_samples.append(frame_ms)
		previous_usec = now_usec
		frame_budget -= 1
		if int(observed.sweeps) >= RESPONSIVENESS_REQUIRED_SWEEPS \
				and int(observed.written_pixels) > 0 \
				and paint.texture_upload_batch_count() > initial_uploads \
				and projectiles.active_count() > 0:
			break
	if int(observed.sweeps) < RESPONSIVENESS_REQUIRED_SWEEPS \
			or int(observed.written_pixels) <= 0 \
			or paint.texture_upload_batch_count() <= initial_uploads:
		_fail_capture("probe did not observe verified continuous paint and texture publication")
		get_tree().quit(1)
		return
	var result := {
		"engine": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"physics_interpolation": bool(ProjectSettings.get_setting(
			"physics/common/physics_interpolation", false
		)),
		"transitions": transition_results,
		"flight": {
			"frames": _frame_stats(flight_samples),
			"paint_drain_frames": _frame_stats(drain_frame_samples),
			"non_drain_frames": _frame_stats(nondrain_frame_samples),
			"paint_drains": int(observed.drains),
			"paint_commands": int(observed.commands),
			"surface_sweeps": int(observed.sweeps),
			"written_pixels": int(observed.written_pixels),
			"texture_upload_batches": paint.texture_upload_batch_count() - initial_uploads,
			"projectile_active_at_stop": projectiles.active_count(),
		},
	}
	var absolute_path := ProjectSettings.globalize_path(_responsiveness_output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		_fail_capture("could not open responsiveness telemetry output")
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("Responsiveness telemetry -> %s: %s" % [absolute_path, JSON.stringify(result)])
	get_tree().quit(0)


func _measure_transition(action: Callable) -> Dictionary:
	var started_usec := Time.get_ticks_usec()
	action.call()
	var call_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0
	var samples := PackedFloat64Array()
	var previous_usec := Time.get_ticks_usec()
	for _frame in range(RESPONSIVENESS_TRANSITION_FRAMES):
		await get_tree().process_frame
		var now_usec := Time.get_ticks_usec()
		samples.append(float(now_usec - previous_usec) / 1000.0)
		previous_usec = now_usec
	return {"call_ms": call_ms, "frames": _frame_stats(samples)}


func _frame_stats(samples: PackedFloat64Array) -> Dictionary:
	if samples.is_empty():
		return {
			"count": 0, "average_ms": 0.0, "p95_ms": 0.0,
			"maximum_ms": 0.0, "over_16_7_ms": 0, "over_33_3_ms": 0,
		}
	var ordered: Array[float] = []
	var total := 0.0
	var over_16_7 := 0
	var over_33_3 := 0
	for sample in samples:
		ordered.append(sample)
		total += sample
		if sample > 16.7:
			over_16_7 += 1
		if sample > 33.3:
			over_33_3 += 1
	ordered.sort()
	var p95_index := clampi(ceili(float(ordered.size()) * 0.95) - 1, 0, ordered.size() - 1)
	return {
		"count": ordered.size(),
		"average_ms": total / float(ordered.size()),
		"p95_ms": ordered[p95_index],
		"maximum_ms": ordered[ordered.size() - 1],
		"over_16_7_ms": over_16_7,
		"over_33_3_ms": over_33_3,
	}


func _start_stage(stage_id: StringName, begin_aiming: bool) -> Node3D:
	var game_state := get_node("/root/GameState")
	var data: Dictionary = get_node("/root/SaveSystem").default_data()
	data.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(data)
	_app._start_stage(stage_id)
	await get_tree().process_frame
	await get_tree().process_frame
	var gameplay: Node3D = _app.get_node("ActiveGameplay")
	if begin_aiming:
		gameplay.get_node("StageController").begin_aiming()
	return gameplay


func _capture_continuous_paint() -> void:
	var gameplay := await _start_stage(&"first_descent", true)
	var controller: StageController = gameplay.get_node("StageController")
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var observed := {"written_pixels": 0, "sweep_count": 0}
	paint.paint_command_applied.connect(
		func(command, written_pixel_count: int, _newly_painted_pixel_count: int) -> void:
			observed.written_pixels += written_pixel_count
			if command is SurfacePaintSweep:
				observed.sweep_count += 1
	)
	var initial_upload_count := paint.texture_upload_batch_count()
	if not controller.request_fire():
		_fail_capture("First Descent runtime default aim could not fire")
		return
	Engine.time_scale = 3.0
	var budget := 60 * 12
	while (
		int(observed.written_pixels) < 400
		or int(observed.sweep_count) < 72
		or manager.active_count() == 0
	) and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	if budget <= 0 or int(observed.written_pixels) < 400 \
			or int(observed.sweep_count) < 72 or manager.active_count() == 0:
		_fail_capture("continuous paint did not arrive while the projectile was active")
		return
	if paint.texture_upload_batch_count() <= initial_upload_count:
		_fail_capture("continuous paint mask was not published to the terrain material")
		return
	gameplay.get_node("CameraDirector").set_mode(CameraDirector.Mode.AIMING, true)
	Engine.time_scale = 0.25


func _capture_clear() -> void:
	var gameplay := await _start_stage(&"burst_basin", true)
	await _play_solution(gameplay, StageCatalog.get_stage(&"burst_basin").reliable_solution)
	if gameplay.get_node("StageController").current_state != StageController.State.STAGE_CLEAR:
		_fail_capture("clear solution did not reach STAGE_CLEAR")


func _capture_failure() -> void:
	var gameplay := await _start_stage(&"first_descent", true)
	var miss := Vector3(28, 18, 0)
	var repeated: Array[Vector3] = [miss, miss, miss, miss]
	await _play_solution(gameplay, repeated)
	if gameplay.get_node("StageController").current_state != StageController.State.STAGE_FAILED:
		_fail_capture("failure sequence did not reach STAGE_FAILED")


func _play_solution(gameplay: Node3D, shots: Array[Vector3]) -> void:
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	for shot in shots:
		if controller.current_state in [StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED]:
			break
		cannon.set_aim(shot.x, shot.y, shot.z)
		controller.request_fire()
		Engine.time_scale = 3.0
		var budget := 60 * 24
		while controller.current_state not in [StageController.State.AIMING, StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED] and budget > 0:
			await get_tree().physics_frame
			budget -= 1
		if budget <= 0:
			_fail_capture("solution shot did not settle inside the deterministic budget")
			break
	Engine.time_scale = 1.0


func _fail_capture(message: String) -> void:
	push_error("Delivery capture failed: %s" % message)
	_failed = true
