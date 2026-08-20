extends SceneTree

const STAGE_SELECT_SCENE := preload("res://scenes/ui/screens/stage_select.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/ui/screens/main_menu.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/screens/pause_overlay.tscn")
const SAFE_MARGIN := 24.0

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	var previous_locale := TranslationServer.get_locale()
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1024, 576), Vector2i(1024, 768), Vector2i(1920, 1080), Vector2i(640, 360)]:
			await _check_main_menu(viewport_size, locale)
			await _check_stage_select(viewport_size, locale)
			await _check_pause(viewport_size, locale)
			await _check_settings(viewport_size, locale)
	TranslationServer.set_locale(previous_locale)
	game_state.persistence_enabled = true
	if not _failed:
		print("Responsive screen layout passed: menu, Stage Select, Pause, and Settings stay safe and focusable.")
	quit(1 if _failed else 0)


func _check_main_menu(viewport_size: Vector2i, locale: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	root.add_child(viewport)
	var screen := MAIN_MENU_SCENE.instantiate() as MainMenuScreen
	viewport.add_child(screen)
	await process_frame
	await process_frame
	var compact := viewport_size.x < 900 or viewport_size.y < 520
	var safe_margin := 12.0 if compact else SAFE_MARGIN
	var block := screen.get_node("Root/BrandBlock") as Control
	_assert_safe(block, viewport_size, "%s %s Main Menu block" % [locale, viewport_size], safe_margin)
	for action_name in ["Play", "StageSelect", "Settings", "Quit"]:
		var action := screen.get_node("Root/BrandBlock/Margin/Content/%s" % action_name) as Button
		_assert(block.get_global_rect().encloses(action.get_global_rect()), "%s %s %s must stay inside the menu block" % [locale, viewport_size, action_name])
		_assert(action.custom_minimum_size.y >= 40.0, "%s %s %s must keep a routine target" % [locale, viewport_size, action_name])
	screen.queue_free()
	viewport.queue_free()
	await process_frame


func _check_pause(viewport_size: Vector2i, locale: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	root.add_child(viewport)
	var pause := PAUSE_SCENE.instantiate() as PauseOverlay
	viewport.add_child(pause)
	await process_frame
	await process_frame
	var surface := pause.get_node("Center/Surface") as Control
	var margin := 12.0 if viewport_size.y < 480 else SAFE_MARGIN
	_assert_safe(surface, viewport_size, "%s %s Pause surface" % [locale, viewport_size], margin)
	for action_name in ["Resume", "Restart", "Settings", "Stages", "MainMenu"]:
		var action := pause.get_node("Center/Surface/Margin/Column/%s" % action_name) as Button
		_assert(surface.get_global_rect().encloses(action.get_global_rect()), "%s %s Pause %s must stay inside its interruption surface" % [locale, viewport_size, action_name])
		_assert(action.custom_minimum_size.y >= 40.0, "%s %s Pause %s must keep a routine target" % [locale, viewport_size, action_name])
	pause.focus_resume()
	await process_frame
	_assert((pause.get_node("Center/Surface/Margin/Column/Resume") as Button).has_focus(), "%s %s Pause must focus Resume" % [locale, viewport_size])
	pause.queue_free()
	viewport.queue_free()
	await process_frame


func _check_stage_select(viewport_size: Vector2i, locale: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	root.add_child(viewport)
	var screen := STAGE_SELECT_SCENE.instantiate() as StageSelectScreen
	viewport.add_child(screen)
	await process_frame
	await process_frame
	var compact := viewport_size.x < 900 or viewport_size.y < 480
	var safe_margin := 12.0 if compact else SAFE_MARGIN
	var rail := screen.get_node("Root/StageRail") as StageRail
	_assert(screen._stage_nodes.size() == 8, "%s %s Stage Select must expose eight shared nodes per full page" % [locale, viewport_size])
	_assert_safe(screen.get_node("Root/Back") as Control, viewport_size, "%s %s Back" % [locale, viewport_size], safe_margin)
	_assert_safe(screen.get_node("Root/Heading") as Control, viewport_size, "%s %s heading" % [locale, viewport_size], safe_margin)
	_assert_safe(screen.get_node("Root/SelectedInfo") as Control, viewport_size, "%s %s selected facts" % [locale, viewport_size], safe_margin)
	_assert_safe(rail, viewport_size, "%s %s stage rail" % [locale, viewport_size], safe_margin)
	_assert((rail.get_node("Previous") as Button).custom_minimum_size.y >= 40.0, "%s pager targets must remain usable" % locale)
	screen.focus_primary()
	await process_frame
	_assert((screen._stage_nodes[0] as Control).has_focus(), "%s %s Stage Select primary focus must remain selected node" % [locale, viewport_size])
	_assert_safe(screen._stage_nodes[0] as Control, viewport_size, "%s %s selected node" % [locale, viewport_size], safe_margin)
	_assert_safe(screen._start_button, viewport_size, "%s %s Start" % [locale, viewport_size], safe_margin)
	_assert(screen._stage_name.visible != compact and screen._preview_best.visible != compact,
			"%s %s Stage Select must suppress only secondary selected copy in compact mode" % [locale, viewport_size])
	screen.queue_free()
	viewport.queue_free()
	await process_frame


func _check_settings(viewport_size: Vector2i, locale: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	root.add_child(viewport)
	var screen := SETTINGS_SCENE.instantiate() as SettingsScreen
	viewport.add_child(screen)
	await process_frame
	screen.open()
	await process_frame
	await process_frame
	var panel := screen.get_node("SettingsRoot/Panel") as Control
	var columns := screen.get_node("SettingsRoot/Panel/Margin/Content/Columns") as ScrollContainer
	var layout := screen.get_node("SettingsRoot/Panel/Margin/Content/Columns/Layout") as Control
	var audio := screen.get_node("SettingsRoot/Panel/Margin/Content/Columns/Layout/Audio") as Control
	var display := screen.get_node("SettingsRoot/Panel/Margin/Content/Columns/Layout/Display") as Control
	_assert_safe(panel, viewport_size, "%s %s Settings panel" % [locale, viewport_size])
	_assert(columns.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s Settings must never require horizontal scrolling" % locale)
	_assert(columns.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s Settings must show a scrollbar only for real overflow" % locale)
	var wide_layout := columns.size.x >= 1040.0
	if wide_layout:
		_assert(is_equal_approx(audio.position.y, display.position.y), "%s wide Settings columns must align" % locale)
		_assert(display.position.x >= audio.position.x + audio.size.x, "%s wide Settings columns must not overlap" % locale)
	else:
		_assert(display.position.y >= audio.position.y + audio.size.y, "%s compact Settings must stack columns" % locale)
		_assert(layout.custom_minimum_size.y >= display.position.y + display.size.y, "%s compact Settings scroll extent must include display controls" % locale)
	_assert((screen.get_node("SettingsRoot/Panel/Margin/Content/Footer/Defaults") as Button).custom_minimum_size.y >= 40.0, "%s defaults target must remain usable" % locale)
	_assert((screen.get_node("SettingsRoot/Panel/Margin/Content/Footer/Close") as Button).custom_minimum_size.y >= 40.0, "%s close target must remain usable" % locale)
	_assert((screen.get_node("SettingsRoot/Panel/Margin/Content/Footer/Close") as Button).has_focus(), "%s Settings open must retain Close focus" % locale)
	if viewport_size.y < 620 and layout.custom_minimum_size.y > columns.size.y:
		var language := screen.get_node("SettingsRoot/Panel/Margin/Content/Columns/Layout/Display/Language") as OptionButton
		language.grab_focus()
		await process_frame
		await process_frame
		_assert(columns.scroll_vertical > 0,
				"%s %s Settings must follow keyboard focus through vertical overflow" % [locale, viewport_size])
		_assert(columns.get_global_rect().grow(1.0).intersects(language.get_global_rect()),
				"%s %s focused Settings control must be visible in the scroll viewport" % [locale, viewport_size])
	screen.queue_free()
	viewport.queue_free()
	await process_frame


func _assert_safe(control: Control, viewport_size: Vector2i, label: String, margin: float = SAFE_MARGIN) -> void:
	var rect := control.get_global_rect()
	_assert(rect.position.x >= margin - 0.5, "%s escapes the left safe margin" % label)
	_assert(rect.position.y >= margin - 0.5, "%s escapes the top safe margin" % label)
	_assert(rect.end.x <= float(viewport_size.x) - margin + 0.5, "%s escapes the right safe margin" % label)
	_assert(rect.end.y <= float(viewport_size.y) - margin + 0.5, "%s escapes the bottom safe margin" % label)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Responsive screen layout failed: %s" % message)
