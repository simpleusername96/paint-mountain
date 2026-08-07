extends Node

const BACKGROUND_CAPTURE_SIZE := Vector2i(1280, 720)
const BACKGROUND_CAPTURE_POSITION := Vector2i(-32000, -32000)
const TIMEOUT_CAPTURE_TIME_SCALE := 8.0
const STAGE_PREPARATION_TIMEOUT_MSEC := 180_000

var _app: AppRoot
var _screen: String = ""
var _capture_stage: StringName = &"stage_01"
var _output_path: String = ""
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
		elif argument.begins_with("--capture-size="):
			_capture_size = _parse_capture_size(argument.trim_prefix("--capture-size="))
		elif argument == "--capture-background":
			_background_capture = true
	if _screen.is_empty() or _output_path.is_empty():
		return
	if StageCatalog.get_stage(_capture_stage) == null:
		push_error("Unknown capture stage: %s" % _capture_stage)
		get_tree().quit(1)
		return
	_configure_capture_window()
	_app = get_parent() as AppRoot
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run_capture.call_deferred()


func _run_capture() -> void:
	_configure_capture_window()
	var game_state := get_node("/root/GameState")
	game_state.persistence_enabled = false
	_initialize_capture_game_state(game_state, get_node("/root/SaveSystem").default_data())
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
		"wind_flag_weak":
			await _capture_wind_flag(_capture_stage, false)
		"wind_flag_strong":
			await _capture_wind_flag(_capture_stage, true)
		"shot_follow_midflight":
			await _capture_shot_follow_midflight(_capture_stage)
		"shot_follow_impact_hold":
			await _capture_shot_follow_impact_hold(_capture_stage)
		"shot_follow_returned":
			await _capture_shot_follow_returned(_capture_stage)
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
			if paused_gameplay == null:
				return
			(paused_gameplay.get_node("StageController") as StageController).toggle_pause()
			await get_tree().process_frame
		"settings":
			var settings_gameplay := await _start_stage(&"stage_01", true)
			if settings_gameplay == null:
				return
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
	if _screen in [
		"next_aim_pending",
		"next_aim_ready",
		"scale_contact",
		"shot_follow_midflight",
		"shot_follow_impact_hold",
		"shot_follow_returned",
	]:
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
	# Paused captures can retain one deferred RefCounted object when the process
	# quits in the same frame. Tear down gameplay on the normal AppRoot boundary
	# and allow that queue to drain after the image has been saved.
	if _app != null:
		_app._remove_gameplay()
	await get_tree().process_frame
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


func _start_stage(stage_id: StringName, begin_aiming: bool) -> Node3D:
	var game_state := get_node("/root/GameState")
	var data: Dictionary = get_node("/root/SaveSystem").default_data()
	data.selected_stage_id = stage_id
	_initialize_capture_game_state(game_state, data)
	_configure_capture_window()
	_app._start_stage(stage_id)
	var gameplay := await _wait_for_active_gameplay(stage_id)
	if gameplay == null:
		return null
	print("Delivery stage entry ready: stage=%s" % StageCatalog.canonical_id(stage_id))
	if begin_aiming:
		gameplay.get_node("StageController").begin_aiming()
	return gameplay


func _initialize_capture_game_state(game_state: GameState, data: Dictionary) -> void:
	if _background_capture:
		# SettingsScreen reapplies the initialized display preference when it opens.
		# Keep that preference aligned with the requested off-screen capture size.
		var settings := Dictionary(data.get("settings", {})).duplicate(true)
		settings["fullscreen"] = false
		settings["resolution"] = "%dx%d" % [_capture_size.x, _capture_size.y]
		data["settings"] = settings
	game_state.initialize_from_data(data)


func _wait_for_active_gameplay(stage_id: StringName) -> Node3D:
	var canonical_stage_id := StageCatalog.canonical_id(stage_id)
	var deadline := Time.get_ticks_msec() + STAGE_PREPARATION_TIMEOUT_MSEC
	while Time.get_ticks_msec() < deadline:
		var gameplay := _app.get_node_or_null("ActiveGameplay") as Node3D
		var active_stage := gameplay.get("stage_data") as StageData \
				if gameplay != null and not gameplay.is_queued_for_deletion() else null
		if active_stage != null \
				and StageCatalog.canonical_id(active_stage.stage_id) == canonical_stage_id:
			return gameplay
		await get_tree().process_frame
	_fail_capture("stage %s did not finish background preparation" % canonical_stage_id)
	return null


func _capture_wind_aiming(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	if gameplay == null:
		return
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


func _capture_wind_flag(stage_id: StringName, strong: bool) -> void:
	var gameplay := await _start_stage(stage_id, true)
	if gameplay == null:
		return
	var snapshot := _seek_crosswind_snapshot(gameplay, strong)
	if snapshot == null:
		_fail_capture("could not find the requested deterministic crosswind snapshot")
		return
	# Match normal Aim captures: the one-time input hint must leave before the
	# flag and fixed HUD are judged together.
	await get_tree().create_timer(4.2).timeout
	var flag := gameplay.get_node("CannonWindFlag") as CannonWindFlag
	if not flag.displayed_direction().is_equal_approx(snapshot.push_direction()) \
			or not is_equal_approx(flag.displayed_strength(), snapshot.normalized_strength):
		_fail_capture("wind flag did not retain the selected authoritative snapshot")


func _capture_shot_follow_midflight(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	if gameplay == null:
		return
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var director := gameplay.get_node("CameraDirector") as CameraDirector
	await _wait_for_cannon_prediction(cannon)
	if not controller.request_fire():
		_fail_capture("mid-flight capture could not fire the default root")
		return
	for _tick in range(45):
		await get_tree().physics_frame
	if director.current_mode != CameraDirector.Mode.FOLLOW \
			or director._follow_projectile == null \
			or director._follow_impact_hold_ticks > 0:
		_fail_capture("mid-flight capture did not retain the airborne root")


func _capture_shot_follow_impact_hold(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	if gameplay == null:
		return
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var director := gameplay.get_node("CameraDirector") as CameraDirector
	await _wait_for_cannon_prediction(cannon)
	if not controller.request_fire():
		_fail_capture("impact-hold capture could not fire the default root")
		return
	var budget := 360
	while director._follow_impact_hold_ticks <= 0 and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	if budget <= 0 or director.current_mode != CameraDirector.Mode.FOLLOW:
		_fail_capture("impact-hold capture did not observe first terrain contact")
		return
	await get_tree().process_frame


func _capture_shot_follow_returned(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	if gameplay == null:
		return
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	var director := gameplay.get_node("CameraDirector") as CameraDirector
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	await _wait_for_cannon_prediction(cannon)
	if not controller.request_fire():
		_fail_capture("returned-Aim capture could not fire the default root")
		return
	for _tick in range(30):
		await get_tree().physics_frame
	var residents_before := manager.active_count()
	if not director.return_to_aim_view(true):
		_fail_capture("returned-Aim capture could not leave Shot Follow")
		return
	for _frame in range(12):
		await get_tree().process_frame
	if director.current_mode != CameraDirector.Mode.AIMING \
			or residents_before <= 0 or manager.active_count() <= 0:
		_fail_capture("returning the camera changed projectile residency")


func _seek_crosswind_snapshot(gameplay: Node3D, strong: bool) -> WindSnapshot:
	var wind := gameplay.get_node("WindController") as WindController
	var profile := gameplay.stage_data.wind_profile as WindProfile
	var interval_ticks := profile.interval_ticks(Engine.physics_ticks_per_second)
	var selected: WindSnapshot
	for keyframe_index in range(64):
		var tick := keyframe_index * interval_ticks
		var candidate := wind.sample_at_tick(tick)
		if candidate == null or absf(candidate.push_direction().x) < 0.72:
			continue
		if strong and candidate.normalized_strength < maxf(
			profile.strong_wind_threshold,
			0.80
		):
			continue
		if not strong and candidate.normalized_strength > 0.35:
			continue
		selected = candidate
		wind._elapsed_ticks = tick
		wind._snapshot = candidate
		wind._update_strong_state()
		wind.snapshot_changed.emit(candidate)
		break
	return selected


func _capture_map_inspection(stage_id: StringName) -> void:
	var gameplay := await _start_stage(stage_id, true)
	if gameplay == null:
		return
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
	if gameplay == null:
		return
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
	if gameplay == null:
		return
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
	if gameplay == null:
		return
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
	if gameplay == null:
		return
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
	var summit_aim := layout.generated_summit_aim
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
	if gameplay == null:
		return
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
	if gameplay == null:
		return
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
	if gameplay == null:
		return
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
	if not controller.request_fire():
		_fail_capture("scale capture could not fire the default aim")
		return
	# Run the real flight at normal speed, then hold just after the first
	# authoritative mark so the frame contains the physical ball and paint.
	var budget := Engine.physics_ticks_per_second * 12
	while not bool(contact_paint_seen.value) and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	if not bool(contact_paint_seen.value):
		_fail_capture("scale capture did not observe a live ball and target paint together")
		return
	Engine.time_scale = 0.08


func _wait_for_cannon_prediction(cannon: CannonController) -> void:
	var budget := 90
	while not cannon.is_aim_valid() and budget > 0:
		await get_tree().process_frame
		budget -= 1


func _capture_continuous_paint() -> void:
	var gameplay := await _start_stage(&"first_descent", true)
	if gameplay == null:
		return
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
