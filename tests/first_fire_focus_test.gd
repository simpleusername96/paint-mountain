extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.select_stage(&"stage_01")
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	_assert(gameplay != null, "first-fire focus requires the baked Stage 01 layout")
	if gameplay == null:
		_finish()
		return
	root.add_child(gameplay)
	await physics_frame
	await process_frame

	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var aim_input := gameplay.get_node("AimInputController") as AimInputController
	var camera_director := gameplay.get_node("CameraDirector") as CameraDirector
	var fire_button := gameplay.get_node("HUD/HUDRoot/ActionButtons/FireButton") as Button
	var interaction := gameplay.get_node("HUD/HUDRoot/CameraInteractionControl") as Button
	_assert(controller.begin_aiming(), "fixture must enter Aiming without a pointer click")
	await process_frame
	await process_frame
	_assert(
		root.gui_get_focus_owner() == fire_button,
		"Aiming entry must focus Fire after camera and interaction state settle"
	)
	_assert(not fire_button.disabled, "legal untouched default aim must expose an enabled Fire button")
	var shots_before := controller.shots_remaining
	await _push_space()
	_assert(
		controller.shots_remaining == shots_before - 1 \
				and manager.active_root_count() == 1 \
				and camera_director.current_mode == CameraDirector.Mode.FOLLOW,
		"one untouched Space press must admit one family and enter Shot Follow"
	)

	_assert(controller.restart(false), "pointer fixture must restart directly into Aiming")
	await process_frame
	await process_frame
	# The global shortcut intentionally leaves native Space activation intact for
	# a deliberately focused secondary button.
	interaction.grab_focus()
	var roots_before_secondary_space := manager.active_root_count()
	var secondary_space := InputEventKey.new()
	secondary_space.physical_keycode = KEY_SPACE
	secondary_space.keycode = KEY_SPACE
	secondary_space.pressed = true
	_assert(
		not aim_input._handle_key(secondary_space) and manager.active_root_count() == roots_before_secondary_space,
		"the global handler must leave Space unconsumed for a focused secondary button"
	)
	fire_button.grab_focus()
	var pointer_shots_before := controller.shots_remaining
	fire_button.pressed.emit()
	await process_frame
	_assert(
		controller.shots_remaining == pointer_shots_before - 1 \
				and manager.active_root_count() == 1,
		"one pointer Fire activation must admit exactly one root without doubling"
	)
	gameplay.queue_free()
	await process_frame
	_finish()


func _push_space() -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_SPACE
		event.keycode = KEY_SPACE
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _finish() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = true
	if not _failed:
		print("first_fire_focus_test passed: first untouched Space fires once and secondary focus keeps native activation.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("First-fire focus check failed: %s" % message)
