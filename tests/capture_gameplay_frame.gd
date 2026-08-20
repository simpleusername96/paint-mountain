extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested_stage := &"first_descent"
	var requested_state := "briefing"
	var requested_locale := "ko"
	var background_capture := false
	var requested_size := Vector2i.ZERO
	var output_path := ProjectSettings.globalize_path("res://.godot/capture-temp/gameplay_capture.png")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			requested_stage = StringName(argument.trim_prefix("--stage="))
		elif argument.begins_with("--state="):
			requested_state = argument.trim_prefix("--state=")
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
	var unlocked_data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	unlocked_data.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	unlocked_data.settings.language = requested_locale
	game_state.initialize_from_data(unlocked_data)
	game_state.select_stage(requested_stage)
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(requested_stage)
	if gameplay == null:
		push_error("Could not prepare the persisted layout for %s." % requested_stage)
		quit(1)
		return
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var controller: StageController = gameplay.get_node("StageController")
	match requested_state:
		"aiming":
			controller.begin_aiming()
		"aiming_disabled":
			controller.begin_aiming()
			await process_frame
			# Presentation fixture for the real localized Fire-readiness component.
			(gameplay.get_node("HUD") as HUDController).set_fire_readiness({
				"fireable": false,
				"reason": tr("fire.not_editable"),
			})
		"map_inspection":
			controller.begin_aiming()
			await process_frame
			(gameplay.get_node("CameraDirector") as CameraDirector).set_interaction_mode(
				CameraDirector.InteractionMode.MAP_INSPECTION,
				true
			)
		"pause":
			controller.begin_aiming()
			controller.toggle_pause()
		"clear":
			controller.force_finish_debug()
			await process_frame
			# The capture is a presentation fixture: retain the authored band and
			# overwrite only the result values after the real terminal transition.
			var result := controller.result_snapshot()
			var center := controller.stage_data.target_band.center()
			result.merge({
				"cleared": true,
				"paint_score": center,
				"stars": 3,
				"red_percent": center * 0.5,
				"green_percent": center * 0.5,
				"total_percent": center,
			}, true)
			(gameplay.get_node("HUD") as HUDController).show_target_band_result_snapshot(result)
		"failed":
			controller.force_finish_debug()
		"shot_follow":
			controller.begin_aiming()
			await physics_frame
			if not controller.request_fire():
				push_error("Could not admit the root required for Shot Follow capture.")
				quit(1)
				return
		"late_queue":
			controller.begin_aiming()
			var deal: Array[BallToken] = controller._deal
			controller._queue_cursor = maxi(deal.size() - 1, 0)
			controller._emit_deal_changed()
	for _frame in range(40):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Could not save gameplay capture to %s (error %d)." % [output_path, error])
		quit(1)
		return
	print("Captured %s gameplay state '%s' to %s." % [requested_stage, requested_state, output_path])
	paused = false
	quit(0)
