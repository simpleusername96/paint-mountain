class_name MainMenuScreen
extends CanvasLayer

signal play_requested
signal stage_select_requested
signal settings_requested
signal quit_requested

var _play_ready := false
var _play_failed := false
var _keyboard_navigation_started := false
var _loading_fallback_owns_focus := false


func _ready() -> void:
	(%StageSelect as MenuActionItem).configure(
		"ui.stage_select", ActionControl.IconKind.STAGES
	)
	(%Settings as MenuActionItem).configure(
		"ui.settings", ActionControl.IconKind.SETTINGS
	)
	(%Quit as MenuActionItem).configure(
		"ui.quit", ActionControl.IconKind.QUIT, ActionControl.VisualRole.DESTRUCTIVE
	)
	%Play.pressed.connect(func() -> void: play_requested.emit())
	%StageSelect.pressed.connect(func() -> void: stage_select_requested.emit())
	%Settings.pressed.connect(func() -> void: settings_requested.emit())
	if OS.has_feature("web"):
		%Quit.hide()
	else:
		%Quit.pressed.connect(func() -> void: quit_requested.emit())
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_play_preparation_state()
	_apply_responsive_layout.call_deferred()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var window_size := viewport_size if get_viewport() is SubViewport \
			else Vector2(DisplayServer.window_get_size())
	var compact := window_size.x < 900.0 or window_size.y < 520.0
	var density := _display_density(viewport_size, window_size) if compact else 1.0
	var block := %BrandBlock as Control
	var content := %Content as VBoxContainer
	var title := %Title as Label
	var spacer := %ActionSpacer as Control
	block.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if compact:
		var safe := 12.0 * density
		block.position = Vector2(safe, safe)
		block.size = Vector2(minf(380.0 * density, viewport_size.x - safe * 2.0), viewport_size.y - safe * 2.0)
		content.add_theme_constant_override(&"separation", 8)
		title.theme_type_variation = &"MenuTitleCompact"
		spacer.custom_minimum_size.y = 8.0 * density
	else:
		block.position = Vector2(56.0, maxf(24.0, (viewport_size.y - 528.0) * 0.5))
		block.size = Vector2(414.0, minf(528.0, viewport_size.y - block.position.y - 24.0))
		content.add_theme_constant_override(&"separation", 16)
		title.theme_type_variation = &"MenuTitle"
		spacer.custom_minimum_size.y = 48.0
	for action_item in [%Play, %StageSelect, %Settings, %Quit]:
		(action_item as MenuActionItem).set_compact(compact, density)


func set_play_preparation_state(ready: bool, failed: bool = false) -> void:
	var play_became_ready := ready and not _play_ready
	_play_ready = ready
	_play_failed = failed
	_apply_play_preparation_state(play_became_ready)


func focus_primary() -> void:
	if not (%Play as MenuActionItem).action.disabled:
		(%Play as MenuActionItem).focus_action()
	else:
		(%StageSelect as MenuActionItem).focus_action()


func begin_passive_focus_session() -> void:
	_keyboard_navigation_started = false
	_loading_fallback_owns_focus = false
	get_viewport().gui_release_focus()


func _input(event: InputEvent) -> void:
	if _loading_fallback_owns_focus and _is_keyboard_navigation(event):
		# Any later navigation makes the player's focus choice authoritative, even
		# when it eventually returns to Stage Select before preparation finishes.
		_loading_fallback_owns_focus = false


func _unhandled_key_input(event: InputEvent) -> void:
	if _keyboard_navigation_started or not _is_keyboard_navigation(event):
		return
	_keyboard_navigation_started = true
	# Passive and pointer-led launches keep the menu visually quiet. The first
	# keyboard navigation establishes the normal visible focus origin instead.
	focus_primary()
	_loading_fallback_owns_focus = not _play_ready and not _play_failed \
			and (%StageSelect as MenuActionItem).action_has_focus()
	get_viewport().set_input_as_handled()


func _apply_play_preparation_state(play_became_ready: bool = false) -> void:
	var play := %Play as MenuActionItem
	if _play_failed:
		play.configure(
			"ui.retry_stage_load", ActionControl.IconKind.RETRY, ActionControl.VisualRole.PRIMARY
		)
	elif not _play_ready:
		play.configure(
			"ui.loading_stage", ActionControl.IconKind.PLAY, ActionControl.VisualRole.PRIMARY
		)
	else:
		play.configure("ui.play", ActionControl.IconKind.PLAY, ActionControl.VisualRole.PRIMARY)
	play.set_readiness(_play_ready or _play_failed,
			tr("ui.stage_load_failed") if _play_failed else "")
	if play_became_ready and _loading_fallback_owns_focus \
			and (%StageSelect as MenuActionItem).action_has_focus():
		# Only replace the loading fallback. Any later player focus movement wins.
		_loading_fallback_owns_focus = false
		(%Play as MenuActionItem).focus_action()


func _is_keyboard_navigation(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:
		return false
	return event.keycode in [KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT] \
			or event.is_action_pressed(&"ui_focus_next") \
			or event.is_action_pressed(&"ui_focus_prev") \
			or event.is_action_pressed(&"ui_up") \
			or event.is_action_pressed(&"ui_down") \
			or event.is_action_pressed(&"ui_left") \
			or event.is_action_pressed(&"ui_right")


func _on_settings_changed(_settings: Dictionary) -> void:
	_apply_play_preparation_state()
	for action_item in [%StageSelect, %Settings, %Quit]:
		(action_item as MenuActionItem).refresh_locale()


func _display_density(viewport_size: Vector2, window_size: Vector2) -> float:
	if get_viewport() is SubViewport or window_size.x <= 0.0 or window_size.y <= 0.0:
		return 1.0
	return clampf(minf(viewport_size.x / window_size.x, viewport_size.y / window_size.y), 1.0, 2.0)
