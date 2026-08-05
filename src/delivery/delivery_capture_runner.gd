extends Node

const BACKGROUND_CAPTURE_SIZE := Vector2i(1280, 720)
const BACKGROUND_CAPTURE_POSITION := Vector2i(-32000, -32000)
const RESPONSIVENESS_WARMUP_FRAMES := 24
const RESPONSIVENESS_TRANSITION_FRAMES := 6
const RESPONSIVENESS_FLIGHT_FRAME_BUDGET := 720
const RESPONSIVENESS_REQUIRED_SWEEPS := 120
const DIRTY_FIRE_MAX_MILLISECONDS := 2.0
const READY_FIRE_MAX_MILLISECONDS := 8.0
const DRAIN_P95_MAX_MILLISECONDS := 4.0
const DRAIN_MAX_MILLISECONDS := 8.0
const DRAIN_FRAME_P95_DELTA_MAX_MILLISECONDS := 4.0
const TIMEOUT_CAPTURE_TIME_SCALE := 8.0

var _app: AppRoot
var _screen: String = ""
var _capture_stage: StringName = &"stage_01"
var _output_path: String = ""
var _responsiveness_output_path: String = ""
var _background_capture := false
var _capture_size := BACKGROUND_CAPTURE_SIZE
var _failed: bool = false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-screen="):
			_screen = argument.trim_prefix("--capture-screen=")
		elif argument.begins_with("--capture-stage="):
			_capture_stage = StringName(argument.trim_prefix("--capture-stage="))
		elif argument.begins_with("--capture-output="):
			_output_path = argument.trim_prefix("--capture-output=")
		elif argument.begins_with("--responsiveness-output="):
			_responsiveness_output_path = argument.trim_prefix("--responsiveness-output=")
		elif argument.begins_with("--capture-size="):
			_capture_size = _parse_capture_size(argument.trim_prefix("--capture-size="))
		elif argument == "--capture-background":
			_background_capture = true
	if _responsiveness_output_path.is_empty() and (_screen.is_empty() or _output_path.is_empty()):
		return
	if StageCatalog.get_stage(_capture_stage) == null:
		push_error("Unknown capture stage: %s" % _capture_stage)
		get_tree().quit(1)
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
		"stage_select_page_2":
			_app._show_stage_select()
			await get_tree().process_frame
			_app.get_node("StageSelect").set_page_for_capture(1)
		"briefing":
			await _start_stage(_capture_stage, false)
		"stage_briefing":
			await _start_stage(_capture_stage, false)
		"aiming":
			await _capture_wind_aiming(_capture_stage)
		"wind_aiming":
			await _capture_wind_aiming(_capture_stage)
		"progression_aiming":
			await _start_stage(_capture_stage, true)
			await get_tree().create_timer(1.0).timeout
		"map_inspection":
			await _capture_map_inspection(_capture_stage)
		"aim_return":
			await _capture_aim_return(_capture_stage)
		"summit_hit":
			await _capture_summit_hit()
		"next_aim_pending":
			await _capture_next_aim(false)
		"next_aim_ready":
			await _capture_next_aim(true)
		"two_family":
			await _capture_two_family()
		"scale_contact":
			await _capture_scale_contact()
		"aiming_burst":
			var burst_stage := _capture_stage
			if StageCatalog.canonical_id(burst_stage) == &"stage_01":
				burst_stage = &"stage_02"
			await _capture_wind_aiming(burst_stage)
		"aiming_split":
			var split_stage := _capture_stage
			if StageCatalog.canonical_id(split_stage) == &"stage_01":
				split_stage = &"stage_03"
			await _capture_wind_aiming(split_stage)
		"projectile_and_continuous_paint":
			await _capture_continuous_paint()
		"observation":
			await _capture_continuous_paint()
		"pause":
			var paused_gameplay := await _start_stage(&"stage_01", true)
			(paused_gameplay.get_node("StageController") as StageController).toggle_pause()
			await get_tree().process_frame
		"settings":
			var settings_gameplay := await _start_stage(&"stage_01", true)
			(settings_gameplay.get_node("StageController") as StageController).toggle_pause()
			_app._show_settings(&"gameplay")
			await get_tree().process_frame
		"ancillary_replay":
			await _capture_continuous_paint()
		"manual_result":
			await _capture_manual_result(_capture_stage)
		"timeout_result":
			await _capture_timeout_result(_capture_stage)
		_:
			push_error("Unknown delivery capture screen: %s" % _screen)
			get_tree().quit(1)
			return
	if _screen not in ["projectile_and_continuous_paint", "summit_hit", "next_aim_pending", "next_aim_ready", "two_family", "scale_contact"]:
		Engine.time_scale = 1.0
	if _failed:
		get_tree().quit(1)
		return
	var settle_frames := 42
	if _screen in ["next_aim_pending", "next_aim_ready", "scale_contact"]:
		settle_frames = 0
	elif _screen == "two_family":
		settle_frames = 1
	for _frame in range(settle_frames):
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
	DisplayServer.window_set_size(_capture_size)
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
	var camera_director := gameplay.get_node("CameraDirector") as CameraDirector
	controller.begin_aiming()
	if camera_director.current_interaction_mode != CameraDirector.InteractionMode.AIM_LOCKED:
		_fail_capture("responsiveness probe did not enter the normal Aim Lock interaction")
		get_tree().quit(1)
		return
	var observed := {
		"drains": 0,
		"commands": 0,
		"sweeps": 0,
		"written_pixels": 0,
		"newly_painted_pixels": 0,
		"new_surface_samples": 0,
		"drain_durations_ms": [],
	}
	paint.paint_commands_drained.connect(
		func(_tick: int, command_count: int, _checksum: int) -> void:
			observed.drains += 1
			observed.commands += command_count
			observed.new_surface_samples += paint.last_nonempty_drain_new_surface_sample_count()
			(observed.drain_durations_ms as Array).append(
				paint.last_nonempty_drain_duration_milliseconds()
			)
	)
	paint.paint_command_applied.connect(
		func(command, written_pixel_count: int, newly_painted_pixel_count: int) -> void:
			observed.written_pixels += written_pixel_count
			observed.newly_painted_pixels += newly_painted_pixel_count
			if command is SurfacePaintSweep:
				observed.sweeps += 1
	)
	var shots_before_dirty_fire := controller.shots_remaining
	var dirty_power := cannon.power_percent + 1.0 if cannon.power_percent < 100.0 \
			else cannon.power_percent - 1.0
	if not controller.set_aim(
		cannon.yaw_degrees,
		cannon.elevation_degrees,
		dirty_power
	):
		_fail_capture("responsiveness probe could not dirty the current aim")
		get_tree().quit(1)
		return
	var dirty_fire_started_usec := Time.get_ticks_usec()
	var dirty_fire_result := controller.request_fire()
	var dirty_fire_ms := float(Time.get_ticks_usec() - dirty_fire_started_usec) / 1000.0
	if dirty_fire_result or controller.shots_remaining != shots_before_dirty_fire \
			or projectiles.active_count() != 0:
		_fail_capture("dirty-aim Fire was not rejected without side effects")
		get_tree().quit(1)
		return
	var shots_after_dirty_fire := controller.shots_remaining
	var ready_prediction_budget := 60
	while not cannon.is_aim_valid() and ready_prediction_budget > 0:
		await get_tree().process_frame
		ready_prediction_budget -= 1
	if ready_prediction_budget <= 0 or not cannon.is_aim_valid():
		_fail_capture("dirty aim did not receive the next rendered prediction")
		get_tree().quit(1)
		return
	var initial_uploads := paint.texture_upload_batch_count()
	var initial_cache_misses := paint.surface_sample_cache_miss_count()
	var ready_fire_started_usec := Time.get_ticks_usec()
	var ready_fire_result := controller.request_fire()
	var ready_fire_ms := float(Time.get_ticks_usec() - ready_fire_started_usec) / 1000.0
	if not ready_fire_result:
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
			or int(observed.newly_painted_pixels) <= 0 \
			or paint.texture_upload_batch_count() <= initial_uploads \
			or projectiles.active_count() <= 0:
		_fail_capture("probe did not observe verified continuous paint and texture publication")
		get_tree().quit(1)
		return
	var drain_duration_samples := PackedFloat64Array()
	for duration_ms in observed.drain_durations_ms:
		drain_duration_samples.append(float(duration_ms))
	var drain_duration_stats := _frame_stats(drain_duration_samples)
	var drain_frame_stats := _frame_stats(drain_frame_samples)
	var nondrain_frame_stats := _frame_stats(nondrain_frame_samples)
	var threshold_failures: Array[String] = []
	if dirty_fire_ms > DIRTY_FIRE_MAX_MILLISECONDS:
		threshold_failures.append("dirty Fire exceeded %.1f ms" % DIRTY_FIRE_MAX_MILLISECONDS)
	if ready_fire_ms > READY_FIRE_MAX_MILLISECONDS:
		threshold_failures.append("ready Fire exceeded %.1f ms" % READY_FIRE_MAX_MILLISECONDS)
	if float(drain_duration_stats.p95_ms) > DRAIN_P95_MAX_MILLISECONDS \
			or float(drain_duration_stats.maximum_ms) > DRAIN_MAX_MILLISECONDS:
		threshold_failures.append("nonempty paint drain exceeded its duration budget")
	if float(drain_frame_stats.p95_ms) - float(nondrain_frame_stats.p95_ms) \
			> DRAIN_FRAME_P95_DELTA_MAX_MILLISECONDS:
		threshold_failures.append("paint-drain frame p95 exceeded the non-drain delta budget")
	var result := {
		"engine": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"physics_interpolation": bool(ProjectSettings.get_setting(
			"physics/common/physics_interpolation", false
		)),
		"transitions": transition_results,
		"fire": {
			"dirty_aim_rejected": not dirty_fire_result,
			"dirty_fire_ms": dirty_fire_ms,
			"dirty_fire_shots_unchanged": shots_after_dirty_fire == shots_before_dirty_fire,
			"ready_fire_succeeded": ready_fire_result,
			"ready_fire_ms": ready_fire_ms,
		},
		"flight": {
			"interaction_mode": camera_director.interaction_mode_name(),
			"frames": _frame_stats(flight_samples),
			"paint_drain_frames": drain_frame_stats,
			"non_drain_frames": nondrain_frame_stats,
			"paint_drains": int(observed.drains),
			"paint_commands": int(observed.commands),
			"surface_sweeps": int(observed.sweeps),
			"written_pixels": int(observed.written_pixels),
			"newly_painted_pixels": int(observed.newly_painted_pixels),
			"texture_upload_batches": paint.texture_upload_batch_count() - initial_uploads,
			"projectile_active_at_stop": projectiles.active_count(),
			"nonempty_drain_duration_ms": drain_duration_stats,
			"new_surface_samples": int(observed.new_surface_samples),
			"surface_sample_cache_miss_delta": paint.surface_sample_cache_miss_count() \
					- initial_cache_misses,
		},
		"acceptance": {
			"passed": threshold_failures.is_empty(),
			"failures": threshold_failures,
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
	if not threshold_failures.is_empty():
		_fail_capture("; ".join(threshold_failures))
	get_tree().quit(0 if threshold_failures.is_empty() else 1)


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
	data.selected_stage_id = stage_id
	game_state.initialize_from_data(data)
	_app._start_stage(stage_id)
	await get_tree().process_frame
	await get_tree().process_frame
	var gameplay: Node3D = _app.get_node("ActiveGameplay")
	if begin_aiming:
		gameplay.get_node("StageController").begin_aiming()
	return gameplay


func _capture_wind_aiming(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	var director := gameplay.get_node("CameraDirector") as CameraDirector
	var wind := gameplay.get_node("WindController") as WindController
	if director.current_interaction_mode != CameraDirector.InteractionMode.AIM_LOCKED:
		_fail_capture("wind aiming capture did not enter Aim Lock")
		return
	if wind.current_snapshot() == null:
		_fail_capture("wind aiming capture did not expose a current wind snapshot")
		return
	# Keep the first-session hint honest, then capture the stable current HUD.
	await get_tree().create_timer(4.2).timeout


func _capture_map_inspection(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	var director := gameplay.get_node("CameraDirector") as CameraDirector
	var terrain := gameplay.get_node("TerrainSurface") as TerrainSurface
	var center := terrain.global_position
	if not director.set_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION, true):
		_fail_capture("map inspection capture could not leave Aim Lock")
		return
	if not director.focus_inspection_target(
		terrain.world_surface_point(Vector2(center.x, center.z))
	):
		_fail_capture("map inspection capture could not focus the terrain")
		return
	if not director.orbit_inspection(Vector2(42.0, -14.0)) \
			or not director.zoom_inspection(-1.0):
		_fail_capture("map inspection capture could not apply orbit and zoom")
		return
	await get_tree().create_timer(4.2).timeout
	if director.current_interaction_mode != CameraDirector.InteractionMode.MAP_INSPECTION:
		_fail_capture("map inspection capture did not retain Map Inspection")


func _capture_aim_return(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	var director := gameplay.get_node("CameraDirector") as CameraDirector
	if not director.set_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION, true):
		_fail_capture("aim return capture could not enter Map Inspection")
		return
	if not director.orbit_inspection(Vector2(-36.0, 12.0)) \
			or not director.zoom_inspection(-1.0):
		_fail_capture("aim return capture could not exercise map navigation")
		return
	for _frame in range(12):
		await get_tree().process_frame
	if not director.set_interaction_mode(CameraDirector.InteractionMode.AIM_LOCKED, true):
		_fail_capture("aim return capture could not restore Aim Lock")
		return
	await get_tree().create_timer(4.2).timeout
	if director.current_interaction_mode != CameraDirector.InteractionMode.AIM_LOCKED:
		_fail_capture("aim return capture did not retain Aim Lock")


func _capture_manual_result(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	if not await _fire_until_target_paint(gameplay):
		return
	var controller := gameplay.get_node("StageController") as StageController
	if not controller.finish_stage(StageController.ActionOrigin.HUMAN):
		_fail_capture("manual result capture could not accept Finish")
		return
	await get_tree().process_frame
	_validate_result_capture(controller, StageController.FINISH_REASON_MANUAL)


func _capture_timeout_result(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	await _wait_for_cannon_prediction(cannon)
	if not controller.request_fire():
		_fail_capture("timeout result capture could not fire the first root")
		return
	Engine.time_scale = TIMEOUT_CAPTURE_TIME_SCALE
	var budget := controller.remaining_run_ticks() + Engine.physics_ticks_per_second * 5
	while controller.current_state != StageController.State.RESULT and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	Engine.time_scale = 1.0
	if budget <= 0:
		_fail_capture("timeout result capture did not reach RESULT inside its stage clock")
		return
	await get_tree().process_frame
	_validate_result_capture(controller, StageController.FINISH_REASON_TIMEOUT)


func _fire_until_target_paint(gameplay: Node3D) -> bool:
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var paint := gameplay.get_node("PaintSystem") as PaintSystem
	await _wait_for_cannon_prediction(cannon)
	if not controller.request_fire():
		_fail_capture("manual result capture could not fire the first root")
		return false
	Engine.time_scale = 3.0
	var budget := Engine.physics_ticks_per_second * 12
	while paint.painted_target_pixels() <= 0 \
			and controller.current_state == StageController.State.AIMING \
			and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	Engine.time_scale = 1.0
	if paint.painted_target_pixels() <= 0:
		_fail_capture("manual result capture did not paint the target before Finish")
		return false
	return true


func _validate_result_capture(controller: StageController, expected_reason: StringName) -> void:
	if controller.current_state != StageController.State.RESULT:
		_fail_capture("result capture did not enter RESULT")
		return
	var result := controller.result_snapshot()
	if StringName(result.get("finish_reason", &"")) != expected_reason:
		_fail_capture("result capture stored the wrong finish reason")


func _capture_summit_hit() -> void:
	var gameplay := await _start_stage(_capture_stage, true)
	await get_tree().process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var terrain := gameplay.get_node("TerrainSurface") as TerrainSurface
	var layout := gameplay.generated_layout() as GeneratedStageLayout
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var contact_state := {"seen": false}
	manager.projectile_contact_reported.connect(
		func(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
			if contact != null and terrain.is_top_collider(contact.collider):
				contact_state.seen = true
	)
	var summit_aim := DefaultAimSolver.find_runtime_summit_aim(
		gameplay.get_world_3d().direct_space_state,
		cannon,
		terrain,
		layout
	)
	if summit_aim == null:
		_fail_capture("summit capture could not resolve a legal summit aim")
		return
	controller.set_aim(summit_aim.yaw_degrees, summit_aim.elevation_degrees, summit_aim.power_percent)
	await _wait_for_cannon_prediction(cannon)
	if not controller.request_fire():
		_fail_capture("summit capture could not fire the resolved summit aim")
		return
	var budget := 600
	while not bool(contact_state.seen) and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	if not bool(contact_state.seen):
		_fail_capture("summit capture did not observe a real terrain contact")


func _capture_next_aim(wait_until_ready: bool) -> void:
	var gameplay := await _start_stage(_capture_stage, true)
	await get_tree().process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var changed_yaw := cannon.yaw_degrees + 7.0
	controller.set_aim(changed_yaw, cannon.elevation_degrees, cannon.power_percent)
	if not wait_until_ready:
		# Capture immediately after the input invalidates the old prediction. The
		# short delivery hold lets the real HUD render the PENDING readiness
		# surface before the coalesced predictor publishes the new key.
		gameplay.hold_prediction_refresh_for_delivery()
		await get_tree().process_frame
		return
	await _wait_for_cannon_prediction(cannon)
	if not cannon.is_aim_valid() or not controller.fire_readiness_snapshot().fireable:
		_fail_capture("changed aim did not become fire-ready")


func _capture_two_family() -> void:
	var gameplay := await _start_stage(_capture_stage, true)
	await get_tree().process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	if not controller.request_fire():
		_fail_capture("two-family capture could not fire the first root")
		return
	# Capture-only slow motion keeps the first family visible while the
	# coalesced next-aim prediction arrives.
	Engine.time_scale = 0.25
	controller.set_aim(cannon.yaw_degrees + 7.0, cannon.elevation_degrees, cannon.power_percent)
	await _wait_for_cannon_prediction(cannon)
	if not controller.request_fire():
		_fail_capture("two-family capture could not fire the second root")
		return
	if manager.active_root_count() < 2:
		_fail_capture("two-family capture did not retain two active root families")


func _capture_scale_contact() -> void:
	var gameplay := await _start_stage(_capture_stage, true)
	await get_tree().process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var paint := gameplay.get_node("PaintSystem") as PaintSystem
	var contact_paint_seen := {"value": false}
	paint.paint_command_applied.connect(
		func(_command, written_pixel_count: int, _newly_painted_pixel_count: int) -> void:
			if written_pixel_count > 0 and manager.active_count() > 0:
				contact_paint_seen.value = true
	)
	# Hold the real physics just after the first authoritative mark so the
	# rendered evidence contains both the physical ball and the paint response.
	# This is capture-only timing; gameplay keeps its normal configured speed.
	Engine.time_scale = 0.08
	if not controller.request_fire():
		_fail_capture("scale capture could not fire the default aim")
		return
	var budget := 240
	while not bool(contact_paint_seen.value) and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	if not bool(contact_paint_seen.value):
		_fail_capture("scale capture did not observe a live ball and target paint together")


func _wait_for_cannon_prediction(cannon: CannonController) -> void:
	var budget := 90
	while not cannon.is_aim_valid() and budget > 0:
		await get_tree().process_frame
		budget -= 1


func _capture_continuous_paint() -> void:
	var gameplay := await _start_stage(&"first_descent", true)
	var controller: StageController = gameplay.get_node("StageController")
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var observed := {
		"written_pixels": 0,
		"sweep_count": 0,
		"active_sweep_intent_seen": false,
	}
	paint.paint_command_applied.connect(
		func(command, written_pixel_count: int, _newly_painted_pixel_count: int) -> void:
			observed.written_pixels += written_pixel_count
			if command is SurfacePaintSweep:
				observed.sweep_count += 1
	)
	# Record activity at the canonical intent boundary so the evidence proves the
	# persistent body and a real continuous-paint sweep coexisted.
	manager.surface_paint_sweep_ready.connect(
		func(_command: SurfacePaintSweep) -> void:
			if manager.active_count() > 0:
				observed.active_sweep_intent_seen = true
	)
	var initial_upload_count := paint.texture_upload_batch_count()
	if not controller.request_fire():
		_fail_capture("First Descent runtime default aim could not fire")
		return
	# Keep the physical ball on screen long enough to capture the first real
	# contact/sweep, then the outer runner restores normal time before saving.
	Engine.time_scale = 1.0
	var budget := 60 * 12
	while (
		int(observed.written_pixels) < 120
		or int(observed.sweep_count) < 12
		or not bool(observed.active_sweep_intent_seen)
	) and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	if budget <= 0 or int(observed.written_pixels) < 120 \
			or int(observed.sweep_count) < 12 \
			or not bool(observed.active_sweep_intent_seen):
		_fail_capture("continuous paint did not arrive while the projectile was active")
		return
	if paint.texture_upload_batch_count() <= initial_upload_count:
		_fail_capture("continuous paint mask was not published to the terrain material")
		return
	gameplay.get_node("CameraDirector").set_mode(CameraDirector.Mode.AIMING, true)
	Engine.time_scale = 0.25


func _fail_capture(message: String) -> void:
	push_error("Delivery capture failed: %s" % message)
	_failed = true


func _parse_capture_size(value: String) -> Vector2i:
	var pieces := value.to_lower().split("x")
	if pieces.size() != 2:
		return BACKGROUND_CAPTURE_SIZE
	var width := maxi(320, pieces[0].to_int())
	var height := maxi(240, pieces[1].to_int())
	return Vector2i(width, height)
