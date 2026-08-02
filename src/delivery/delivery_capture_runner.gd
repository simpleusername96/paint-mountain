extends Node

var _app: AppRoot
var _screen: String = ""
var _output_path: String = ""
var _failed: bool = false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-screen="):
			_screen = argument.trim_prefix("--capture-screen=")
		elif argument.begins_with("--capture-output="):
			_output_path = argument.trim_prefix("--capture-output=")
	if _screen.is_empty() or _output_path.is_empty():
		return
	_app = get_parent() as AppRoot
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run_capture.call_deferred()


func _run_capture() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
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
		"projectile_and_paint_flow":
			await _capture_paint_flow()
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
	var error := image.save_png(absolute_path)
	print("Delivery capture %s -> %s (%dx%d, %s)" % [_screen, absolute_path, image.get_width(), image.get_height(), error_string(error)])
	get_tree().quit(0 if error == OK else 1)


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


func _capture_paint_flow() -> void:
	var gameplay := await _start_stage(&"burst_basin", true)
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var solution := StageCatalog.get_stage(&"burst_basin").reliable_solution
	if solution.is_empty():
		_fail_capture("Burst Basin has no reliable solution for paint-flow capture")
		return
	var shot: Vector3 = solution[0]
	cannon.set_aim(shot.x, shot.y, shot.z)
	controller.request_fire()
	Engine.time_scale = 3.0
	var budget := 60 * 16
	while (paint.coverage_percent() < 20.0 or manager.active_count() == 0) and budget > 0:
		await get_tree().physics_frame
		budget -= 1
	if budget <= 0 or paint.coverage_percent() < 20.0 or manager.active_count() == 0:
		_fail_capture("paint-flow state did not arrive inside the deterministic budget")
		return
	gameplay.get_node("CameraDirector").set_mode(CameraDirector.Mode.WIDE, true)
	var camera: Camera3D = gameplay.get_node("Camera")
	camera.global_position = Vector3(26.0, 55.0, -68.0)
	camera.look_at(Vector3(-16.0, 38.0, -120.0), Vector3.UP)
	Engine.time_scale = 0.4


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
