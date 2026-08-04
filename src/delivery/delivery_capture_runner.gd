extends Node

const BACKGROUND_CAPTURE_SIZE := Vector2i(1280, 720)
const BACKGROUND_CAPTURE_POSITION := Vector2i(-32000, -32000)

var _app: AppRoot
var _screen: String = ""
var _output_path: String = ""
var _background_capture := false
var _failed: bool = false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-screen="):
			_screen = argument.trim_prefix("--capture-screen=")
		elif argument.begins_with("--capture-output="):
			_output_path = argument.trim_prefix("--capture-output=")
		elif argument == "--capture-background":
			_background_capture = true
	if _screen.is_empty() or _output_path.is_empty():
		return
	_configure_capture_window()
	_app = get_parent() as AppRoot
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	paint.force_flush_paint_texture()
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
