extends SceneTree

const STAGE_SELECT_SCENE := preload("res://scenes/ui/screens/stage_select.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings.tscn")
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
			await _check_stage_select(viewport_size, locale)
			await _check_settings(viewport_size, locale)
	TranslationServer.set_locale(previous_locale)
	game_state.persistence_enabled = true
	if not _failed:
		print("Responsive screen layout passed: Stage Select and Settings remain safe, readable, and focusable across locale/viewport matrix.")
	quit(1 if _failed else 0)


func _check_stage_select(viewport_size: Vector2i, locale: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	root.add_child(viewport)
	var screen := STAGE_SELECT_SCENE.instantiate() as StageSelectScreen
	viewport.add_child(screen)
	await process_frame
	await process_frame
	var cards := screen.get_node("Root/CardsPanel/Scroll/Margin/Content/Cards") as GridContainer
	var cards_scroll := screen.get_node("Root/CardsPanel/Scroll") as ScrollContainer
	_assert(cards_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s Stage Select must show a scrollbar only for real overflow" % locale)
	var expected_columns := 1 if viewport_size.x < 900 or viewport_size.y < 480 else (4 if viewport_size.x >= 1500 and viewport_size.y >= 700 else 2)
	_assert(cards.columns == expected_columns, "%s %s Stage Select must retain its compact card grid" % [locale, viewport_size])
	_assert_safe(screen.get_node("Root/Back") as Control, viewport_size, "%s %s Back" % [locale, viewport_size])
	_assert_safe(screen.get_node("Root/Heading") as Control, viewport_size, "%s %s heading" % [locale, viewport_size])
	_assert_safe(screen.get_node("Root/CardsPanel") as Control, viewport_size, "%s %s cards region" % [locale, viewport_size])
	_assert_safe(screen.get_node("Root/PreviewPanel") as Control, viewport_size, "%s %s preview region" % [locale, viewport_size])
	_assert((screen.get_node("Root/CardsPanel/Scroll/Margin/Content/PageFooter/PreviousPage") as Button).custom_minimum_size.y >= 40.0, "%s pager targets must remain usable" % locale)
	screen.focus_primary()
	await process_frame
	_assert((screen._cards[0] as Control).has_focus(), "%s %s Stage Select primary focus must remain first card" % [locale, viewport_size])
	_assert_safe(screen._cards[0] as Control, viewport_size, "%s %s selected card" % [locale, viewport_size])
	_assert_safe(screen._start_button, viewport_size, "%s %s Start" % [locale, viewport_size])
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
	screen.queue_free()
	viewport.queue_free()
	await process_frame


func _assert_safe(control: Control, viewport_size: Vector2i, label: String) -> void:
	var rect := control.get_global_rect()
	_assert(rect.position.x >= SAFE_MARGIN - 0.5, "%s escapes the left safe margin" % label)
	_assert(rect.position.y >= SAFE_MARGIN - 0.5, "%s escapes the top safe margin" % label)
	_assert(rect.end.x <= float(viewport_size.x) - SAFE_MARGIN + 0.5, "%s escapes the right safe margin" % label)
	_assert(rect.end.y <= float(viewport_size.y) - SAFE_MARGIN + 0.5, "%s escapes the bottom safe margin" % label)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Responsive screen layout failed: %s" % message)
