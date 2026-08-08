extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")
const NAVY := Color("172538")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	var hud_root := hud.get_node("HUDRoot") as Control
	var actions := hud_root.get_node("ActionButtons") as ActionButtons
	var status := hud_root.get_node("RunStatusCard") as RunStatusCard
	_assert_true(
		 hud_root.get_node_or_null("TopStatusBar/TargetChip") == null,
		"Target coverage must have one owner in the left coverage meter"
	)
	var coverage_caption := hud_root.get_node("CoverageMeter/Content/CoverageCaption") as Label
	_assert_true(coverage_caption.text == "hud.coverage", "CoverageMeter must retain the shared target-area caption key")

	hud.show_state(StageController.State.AIMING)
	hud.set_camera_mode(CameraDirector.Mode.AIMING)
	_assert_true(actions.visible and status.visible, "normal Aiming must expose Fire and edge status")
	hud.show_state(StageController.State.RESULT)
	var result_panel := hud_root.get_node("ResultPanel") as ResultPanel
	_assert_true(result_panel.visible, "the completed run must expose the result panel")
	_assert_true(result_panel.get_node_or_null("Margin/Content/Replay") == null,
		"the result panel must not retain a replay action")
	for action_path in ["Margin/Content/Retry", "Margin/Content/Row/Next", "Margin/Content/Row/Stages"]:
		_assert_true(result_panel.get_node(action_path) is Button,
			"the result panel must retain %s" % action_path)

	var settings := hud_root.get_node("TopStatusBar/SettingsButton") as Button
	_assert_true(settings.icon != null, "Settings must keep the approved icon asset")
	_assert_true(settings.theme_type_variation == &"HudIconButton", "Settings must use the shared icon-button variation")
	for state_name in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		_assert_true(not settings.has_theme_color_override(state_name), "Settings must not duplicate shared %s styling" % state_name)
		_assert_true(settings.get_theme_color(state_name).is_equal_approx(NAVY), "Shared Settings %s must use the navy token" % state_name)
	_assert_true(hud_root.get_node_or_null("TopStatusBar/ShotsChip") == null, "remaining shots must have one owner in the run-status card")

	hud.queue_free()
	await process_frame
	if not _failed:
		print("Phase 8 HUD truth passed: coverage and run status have one owner, and settings remains legible.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
