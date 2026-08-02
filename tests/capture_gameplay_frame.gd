extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested_state := "briefing"
	var output_path := ProjectSettings.globalize_path("res://.godot/capture-temp/gameplay_capture.png")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--state="):
			requested_state = argument.trim_prefix("--state=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var controller: StageController = gameplay.get_node("StageController")
	match requested_state:
		"aiming":
			controller.begin_aiming()
		"pause":
			controller.begin_aiming()
			controller.toggle_pause()
		"clear":
			controller.force_stage_clear()
	for _frame in range(40):
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Could not save gameplay capture to %s (error %d)." % [output_path, error])
		quit(1)
		return
	print("Captured gameplay state '%s' to %s." % [requested_state, output_path])
	paused = false
	quit(0)
