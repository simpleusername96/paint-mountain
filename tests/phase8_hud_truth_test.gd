extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")
const REPLAY_BAR_SCENE := preload("res://scenes/ui/hud/replay_bar.tscn")
const NAVY := Color("172538")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var replay_default := REPLAY_BAR_SCENE.instantiate() as ReplayBar
	_assert_true(not replay_default.visible, "ReplayBar scene must default hidden")
	replay_default.free()

	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	var hud_root := hud.get_node("HUDRoot") as Control
	var replay := hud_root.get_node("ReplayBar") as ReplayBar
	var actions := hud_root.get_node("ActionButtons") as ActionButtons
	_assert_true(not replay.visible, "HUD initialization must keep replay controls hidden")
	_assert_true(
		hud_root.get_node_or_null("TopStatusBar/TargetChip") == null,
		"Target coverage must have one owner in the left coverage meter"
	)

	hud.show_state(StageController.State.AIMING)
	_assert_true(not replay.visible and actions.visible, "normal Aiming must expose Fire without replay controls")
	hud.set_replay_active(true)
	_assert_true(replay.visible and not actions.visible, "only active replay mode may expose replay controls")
	hud.set_replay_active(false)
	_assert_true(not replay.visible and actions.visible, "leaving replay must restore normal Aiming controls")

	var settings := hud_root.get_node("TopStatusBar/SettingsButton") as Button
	_assert_true(settings.icon != null, "Settings must keep the approved icon asset")
	for state_name in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		_assert_true(settings.has_theme_color_override(state_name), "Settings icon must own %s" % state_name)
		_assert_true(settings.get_theme_color(state_name).is_equal_approx(NAVY), "Settings %s must use the navy token" % state_name)

	hud.queue_free()
	await process_frame
	if not _failed:
		print("Phase 8 HUD truth passed: coverage has one owner, replay controls stay state-gated, and settings remains legible.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
