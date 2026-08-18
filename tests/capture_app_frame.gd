extends SceneTree

const APP_SCENE := preload("res://scenes/app/app.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested_screen := "main_menu"
	var requested_locale := "ko"
	var output_path := ProjectSettings.globalize_path("res://.godot/capture-temp/app_capture.png")
	var background_capture := false
	var requested_size := Vector2i.ZERO
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screen="):
			requested_screen = argument.trim_prefix("--screen=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
		elif argument.begins_with("--locale="):
			requested_locale = argument.trim_prefix("--locale=")
		elif argument == "--background":
			background_capture = true
		elif argument.begins_with("--size="):
			var parts := argument.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				requested_size = Vector2i(int(parts[0]), int(parts[1]))
	if requested_size.x > 0 and requested_size.y > 0:
		DisplayServer.window_set_size(requested_size)
	if background_capture:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-32000, -32000))
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var game_state := root.get_node("/root/GameState")
	var capture_data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	capture_data.settings.language = requested_locale
	game_state.initialize_from_data(capture_data)
	var app := APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if requested_screen == "stage_select":
		app._show_stage_select()
	elif requested_screen == "settings":
		app._show_settings(&"main_menu")
	for _frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Could not save app capture to %s (error %d)." % [output_path, error])
		quit(1)
		return
	print("Captured app screen '%s' to %s." % [requested_screen, output_path])
	quit(0)
