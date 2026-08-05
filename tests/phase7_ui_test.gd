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
	var gameplay := await _wait_for_child(app, ^"ActiveGameplay")
	_assert_true(gameplay != null, "stage start must complete after asynchronous layout preparation")
	if gameplay == null:
		game_state.persistence_enabled = true
		app.queue_free()
		await process_frame
		quit(1)
		return
	var controller: StageController = gameplay.get_node("StageController")
	var hud_root := gameplay.get_node("HUD/HUDRoot") as Control
	_assert_true(controller.current_state == StageController.State.BRIEFING, "stage start must enter the separate briefing interface")
	_assert_true(hud_root.get_node("BriefingPanel").visible, "briefing panel must be visible before aiming")
	_assert_true(controller.begin_aiming(), "UI flow test must enter aiming")
	await process_frame
	_assert_aiming_hud_contract(hud_root)
	_assert_true(controller.toggle_pause(), "pause must be reachable from gameplay")
	var pause_overlay := hud_root.get_node("PauseOverlay") as Control
	_assert_true(pause_overlay.visible, "pause overlay must expose its own screen")
	_assert_true(pause_overlay.get_node_or_null("Panel/Margin/Column/Restart") is Button, "Restart must remain available from the paused menu")
	app._on_gameplay_navigation(&"settings")
	await process_frame
	_assert_true(settings.visible, "paused gameplay must be able to open full settings")
	settings.visible = false
	settings.close_requested.emit()
	controller.toggle_pause()
	controller.force_stage_clear()
	await process_frame
	_assert_true(hud_root.get_node("ResultPanel").visible, "terminal coverage snapshot must show the result interface")
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


func _wait_for_child(parent: Node, path: NodePath, timeout_ms: int = 60000) -> Node:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		var child := parent.get_node_or_null(path)
		if child != null:
			return child
		await create_timer(0.01).timeout
	return null


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
	var debug_panel := theme.get_stylebox("panel", "DebugPanel") as StyleBoxFlat
	_assert_true(panel.corner_radius_top_left == 12, "panel radius must be 12px")
	_assert_true(primary.corner_radius_top_left == 16, "primary radius must be 16px")
	_assert_true(focus.border_width_left == 2 and focus.border_color.is_equal_approx(Color("70aaff")), "keyboard focus must use the 2px focus token")
	_assert_true(debug_panel != null and debug_panel.corner_radius_top_left == 10, "debug panel style must remain theme-owned")


func _assert_aiming_hud_contract(hud_root: Control) -> void:
	var hud_rect := hud_root.get_global_rect()
	var hud_center := hud_rect.get_center()
	var coverage := hud_root.get_node("CoverageMeter") as CoverageMeter
	var coverage_value := coverage.get_node_or_null("Content/CoverageValue") as Label
	var target_value := coverage.get_node_or_null("Content/TargetValue") as Label
	var progress := coverage.get_node_or_null("Content/Progress") as ProgressBar
	_assert_true(hud_root.get_node_or_null("TopStatusBar/TargetChip") == null, "the left coverage meter must be the sole target owner")
	_assert_true(coverage_value != null and target_value != null, "the left coverage meter must own both current and target values")
	_assert_true(progress != null and progress.fill_mode == ProgressBar.FILL_BOTTOM_TO_TOP, "the coverage rail must fill from bottom to top")
	_assert_true(coverage.is_visible_in_tree() and coverage.get_global_rect().get_center().x < hud_center.x, "the coverage meter must remain on the left during aiming")

	var actions := hud_root.get_node("ActionButtons") as ActionButtons
	var fire := actions.get_node_or_null("FireButton") as Button
	var fire_rect := fire.get_global_rect()
	_assert_true(actions.find_children("*", "Button", true, false).size() == 1, "Fire must be the sole aiming action")
	_assert_true(actions.find_child("Restart", true, false) == null, "Restart must be absent from the aiming actions")
	_assert_true(fire.is_visible_in_tree() and fire_rect.get_center().x > hud_rect.size.x * 0.35 and fire_rect.get_center().x < hud_rect.size.x * 0.65 and fire_rect.position.y >= hud_rect.size.y * 0.75, "Fire must remain in the lower central action area")
	_assert_true(not (hud_root.get_node("PauseOverlay") as Control).visible, "the paused-menu Restart must stay hidden during aiming")

	var status := hud_root.get_node("RunStatusCard") as RunStatusCard
	var settings := hud_root.get_node("TopStatusBar/SettingsButton") as Button
	var status_rect := status.get_global_rect()
	var settings_rect := settings.get_global_rect()
	_assert_true(status_rect.get_center().x > hud_center.x and status_rect.size.x < hud_rect.size.x * 0.25, "run state must stay in one compact right-edge card")
	_assert_true(settings_rect.get_center().x > hud_center.x and settings_rect.get_center().y < hud_center.y, "settings must stay in the upper-right")
	_assert_true(status_rect.position.y >= settings_rect.end.y, "settings and run status must remain separate, ordered controls")
	for control in [coverage, fire, status, settings]:
		_assert_true(hud_rect.encloses(control.get_global_rect()), "%s must remain inside the logical HUD bounds" % control.name)
