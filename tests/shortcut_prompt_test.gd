extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	root.size = Vector2i(1280, 720)
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.select_stage(&"stage_10")
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_10")
	_assert_true(gameplay != null, "shortcut prompt fixture must load Stage 10")
	if gameplay == null:
		quit(1)
		return
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var hud := gameplay.get_node("HUD") as HUDController
	var root_control := gameplay.get_node("HUD/HUDRoot") as Control
	_assert_true(controller.begin_aiming(), "shortcut fixture must enter Aim View")
	await process_frame
	_assert_keycap(root_control, "ActionButtons/FireButton/FireShortcut", "Space")
	_assert_keycap(root_control, "CameraInteractionControl/ModeShortcut", "Tab")
	_assert_keycap(root_control, "RunStatusCard/Finish/FinishShortcut", "F")
	_assert_keycap(root_control, "TopStatusBar/SettingsButton/SettingsShortcut", "Esc")
	_assert_true(
		root_control.get_node_or_null("AimControls/Content/YawHint") == null,
		"derived target yaw must not advertise unavailable A/D steering"
	)
	_assert_keycap(root_control, "AimControls/Content/AngleDecreaseHint", "S")
	_assert_keycap(root_control, "AimControls/Content/AngleIncreaseHint", "W")
	_assert_icon_prompt(root_control, "AimControls/Content/PowerHint")
	_assert_true(
		root_control.get_node_or_null("ContextLine") == null,
		"normal play must not retain a prose instruction strip"
	)
	_assert_true(
		root_control.get_node_or_null("FirstSessionHint") == null,
		"transient first-session prompt must not remain"
	)

	hud.set_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION)
	_assert_true(
		root_control.get_node("CameraInteractionControl").visible \
				and not root_control.get_node("ActionButtons").visible,
		"Map View must keep its Tab control and hide aim-only actions"
	)
	hud.set_interaction_mode(CameraDirector.InteractionMode.AIM_LOCKED)
	hud.set_camera_mode(CameraDirector.Mode.FOLLOW)
	_assert_keycap(root_control, "ReturnToCannon/ReturnShortcut", "Tab")
	_assert_true(
		root_control.get_node("ReturnToCannon").visible \
				and not root_control.get_node("ActionButtons").visible,
		"Shot Follow must show Return with Tab without aim prompts"
	)
	hud.set_camera_mode(CameraDirector.Mode.AIMING)
	_assert_true(
		controller.toggle_pause(), "Escape prompt fixture must enter pause"
	)
	await process_frame
	_assert_keycap(
		root_control,
		"PauseOverlay/Center/Panel/Margin/Column/Resume/ResumeShortcut",
		"Esc"
	)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	(root_control.get_node("PauseOverlay") as PauseOverlay)._unhandled_input(escape)
	await process_frame
	_assert_true(
		controller.current_state == StageController.State.AIMING,
		"Escape shown on Continue must resume the paused board"
	)

	var aim_before := Vector3(
		gameplay.get_node("Cannon").yaw_degrees,
		gameplay.get_node("Cannon").elevation_degrees,
		gameplay.get_node("Cannon").power_percent
	)
	var restart_key := InputEventKey.new()
	restart_key.keycode = KEY_R
	restart_key.physical_keycode = KEY_R
	restart_key.pressed = true
	gameplay._unhandled_input(restart_key)
	_assert_true(
		controller.current_state == StageController.State.AIMING \
				and Vector3(
					gameplay.get_node("Cannon").yaw_degrees,
					gameplay.get_node("Cannon").elevation_degrees,
					gameplay.get_node("Cannon").power_percent
				).is_equal_approx(aim_before),
		"hidden direct R restart must no longer act"
	)

	TranslationServer.set_locale("en")
	root.size = Vector2i(1920, 1080)
	hud._on_settings_changed(game_state.settings)
	await process_frame
	for path in [
		"ActionButtons/FireButton",
		"CameraInteractionControl",
		"TopStatusBar/SettingsButton",
		"AimControls",
	]:
		_assert_inside_viewport(root_control.get_node(path) as Control, path)
	gameplay.queue_free()
	await process_frame
	TranslationServer.set_locale("ko")
	game_state.persistence_enabled = true
	if not _failed:
		print("Shortcut prompts passed: contextual Space, Tab, F, Escape, pause resume, and no R restart.")
	quit(1 if _failed else 0)


func _assert_keycap(root_control: Control, path: String, expected: String) -> void:
	var hint := root_control.get_node_or_null(path) as ShortcutHint
	var label: Label
	if hint != null:
		label = hint.get_node_or_null("Content/Keycap") as Label
	_assert_true(
		hint != null and label != null and label.text == expected and not label.text.contains("["),
		"%s must expose %s through ShortcutHint" % [path, expected]
	)


func _assert_icon_prompt(root_control: Control, path: String) -> void:
	var hint := root_control.get_node_or_null(path) as ShortcutHint
	var icon: TextureRect
	if hint != null:
		icon = hint.get_node_or_null("Content/Icon") as TextureRect
	_assert_true(
		hint != null and icon != null and icon.visible and icon.texture != null,
		"%s must expose a compact input glyph" % path
	)


func _assert_inside_viewport(control: Control, label: String) -> void:
	var viewport_size := root.get_viewport().get_visible_rect().size
	var rect := control.get_global_rect()
	_assert_true(
		rect.position.x >= 0.0 and rect.position.y >= 0.0 \
				and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y,
		"%s must remain inside the supported viewport" % label
	)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Shortcut prompt check failed: %s" % message)
