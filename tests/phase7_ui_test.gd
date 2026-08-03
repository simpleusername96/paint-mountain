extends SceneTree

const APP_SCENE := preload("res://scenes/app/app.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var unlocked: Dictionary = root.get_node("/root/SaveSystem").default_data()
	unlocked.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(unlocked)
	var app := APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var main_menu: MainMenuScreen = app.get_node("MainMenu")
	var stage_select: StageSelectScreen = app.get_node("StageSelect")
	var settings: SettingsScreen = app.get_node("Settings")
	_assert_true(ProjectSettings.get_setting("display/window/size/viewport_width") == 1280 and ProjectSettings.get_setting("display/window/size/viewport_height") == 720, "UI must use the 1280x720 logical viewport")
	_assert_theme_contract()
	_assert_true(main_menu.visible and not stage_select.visible and not settings.visible, "app must open on a separate main-menu screen")

	app._show_stage_select()
	await process_frame
	_assert_true(stage_select.visible and not main_menu.visible, "stage select must replace the main menu")
	for card in stage_select._cards:
		_assert_true(not card.disabled, "unlocked stage cards must be keyboard-selectable")
	stage_select._cards[1].pressed.emit()
	_assert_true(stage_select.selected_stage_id() == &"burst_basin" and stage_select._cards[1].button_pressed, "stage selection must expose a visible selected state")

	app._show_settings(&"stage_select")
	await process_frame
	_assert_true(settings.visible and not stage_select.visible, "settings must be a separate full-screen interface")
	settings.visible = false
	settings.close_requested.emit()
	await process_frame
	_assert_true(stage_select.visible, "closing settings must return to its calling screen")

	app._start_stage(&"first_descent")
	await process_frame
	await process_frame
	var gameplay := app.get_node("ActiveGameplay")
	var controller: StageController = gameplay.get_node("StageController")
	var hud_root := gameplay.get_node("HUD/HUDRoot")
	_assert_hud_rect(hud_root.get_node("TopStatusBar/StageChip"), Rect2(24, 16, 128, 44), "stage chip")
	_assert_hud_rect(hud_root.get_node("TopStatusBar/TargetChip"), Rect2(497, 16, 286, 44), "target chip")
	_assert_hud_rect(hud_root.get_node("TopStatusBar/ShotsChip"), Rect2(1086, 16, 170, 44), "shots chip")
	_assert_hud_rect(hud_root.get_node("TopStatusBar/ModeChip"), Rect2(24, 72, 128, 40), "mode chip")
	_assert_hud_rect(hud_root.get_node("AimControls"), Rect2(24, 586, 300, 110), "aim controls")
	_assert_hud_rect(hud_root.get_node("CoverageMeter"), Rect2(410, 640, 460, 56), "coverage meter")
	_assert_hud_rect(hud_root.get_node("ActionButtons/Restart"), Rect2(1028, 584, 88, 112), "restart action")
	_assert_hud_rect(hud_root.get_node("ActionButtons/FireButton"), Rect2(1128, 584, 128, 112), "fire action")
	_assert_accessible_controls(hud_root)
	_assert_true(controller.current_state == StageController.State.BRIEFING, "stage start must enter the separate briefing interface")
	_assert_true(hud_root.get_node("BriefingPanel").visible, "briefing panel must be visible before aiming")
	_assert_true(controller.begin_aiming(), "UI flow test must enter aiming")
	_assert_true(controller.toggle_pause(), "pause must be reachable from gameplay")
	_assert_true(hud_root.get_node("PauseOverlay").visible, "pause overlay must expose its own screen")
	app._on_gameplay_navigation(&"settings")
	await process_frame
	_assert_true(settings.visible, "paused gameplay must be able to open full settings")
	settings.visible = false
	settings.close_requested.emit()
	controller.toggle_pause()
	controller.force_stage_clear()
	await process_frame
	_assert_true(hud_root.get_node("ResultPanel").visible, "clear must show the result interface")
	_assert_true(hud_root.get_node("ResultPanel").size.x <= 1280.0 * 0.35, "result panel must use no more than 35 percent of the viewport width")
	var result_content := hud_root.get_node("ResultPanel/Margin/Content")
	_assert_true(result_content.get_node("Retry") is Button, "result must expose retry as a real button")

	app._on_gameplay_navigation(&"stage_select")
	await process_frame
	_assert_true(stage_select.visible and app.get_node_or_null("ActiveGameplay") == null, "stage select navigation must cleanly leave gameplay")
	if not _failed:
		print("Phase 7 UI flow passed: menu, stage select, settings, briefing, pause, result, and clean navigation.")
	game_state.persistence_enabled = true
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true


func _assert_theme_contract() -> void:
	var theme: Theme = load("res://resources/ui/paint_mountain_theme.tres")
	_assert_true(theme.default_font_size == 16, "theme body type must be at least 16px")
	var panel := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	var primary := theme.get_stylebox("normal", "PrimaryButton") as StyleBoxFlat
	var focus := theme.get_stylebox("focus", "Button") as StyleBoxFlat
	_assert_true(panel.corner_radius_top_left == 12, "panel radius must be 12px")
	_assert_true(primary.corner_radius_top_left == 16, "primary radius must be 16px")
	_assert_true(focus.border_width_left == 2 and focus.border_color.is_equal_approx(Color("70aaff")), "keyboard focus must use the 2px focus token")


func _assert_hud_rect(control: Control, expected: Rect2, label: String) -> void:
	var actual := control.get_global_rect()
	_assert_true(actual.position.distance_to(expected.position) <= 2.0 and actual.size.distance_to(expected.size) <= 2.0, "%s rect must match %s, got %s" % [label, expected, actual])
	for resolution in [Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080)]:
		var scale: float = resolution.x / 1280.0
		var physical: Rect2 = Rect2(actual.position * scale, actual.size * scale)
		var expected_physical: Rect2 = Rect2(expected.position * scale, expected.size * scale)
		_assert_true(physical.position.distance_to(expected_physical.position) <= 3.0 and physical.size.distance_to(expected_physical.size) <= 3.0, "%s must preserve aspect-scaled geometry at %s" % [label, resolution])
		_assert_true(physical.position.x >= 0.0 and physical.position.y >= 0.0 and physical.end.x <= resolution.x and physical.end.y <= resolution.y, "%s must remain onscreen at %s" % [label, resolution])


func _assert_accessible_controls(node: Node) -> void:
	if node is Button:
		_assert_true(node.size.y >= 40.0, "%s button must be at least 40px tall" % node.name)
		_assert_true(node.get_theme_font_size("font_size") >= 16, "%s button type must be at least 16px" % node.name)
		_assert_true(node.focus_mode == Control.FOCUS_ALL, "%s must expose keyboard focus" % node.name)
	elif node is Label:
		_assert_true(node.get_theme_font_size("font_size") >= 14, "%s label type must be at least 14px" % node.name)
	for child in node.get_children():
		_assert_accessible_controls(child)
