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
		"Target score must have one owner in the left score scale"
	)
	var score_status := hud_root.get_node("AimScoreStatus") as AimScoreStatus
	score_status.configure_coverage(10.0)
	_assert_true(
		not score_status.accessibility_name.is_empty()
				and score_status.target_range().is_equal_approx(Vector2(10.0, 100.0)),
		"AimScoreStatus must expose its visual range through a localized text alternative"
	)

	hud.show_state(StageController.State.AIMING)
	hud.set_camera_mode(CameraDirector.Mode.AIMING)
	_assert_true(actions.visible and status.visible, "normal Aiming must expose Fire and edge status")
	hud.show_state(StageController.State.RESULT)
	var result_panel := hud_root.get_node("ResultPanel") as ResultPanel
	_assert_true(result_panel.visible, "the completed run must expose the result panel")
	_assert_true(result_panel.get_node_or_null("Margin/Content/Actions/Replay") == null,
		"the result panel must not retain a replay action")
	for action_path in [
		"Margin/Content/Actions/Retry",
		"Margin/Content/Actions/Next",
		"Margin/Content/Actions/Stages",
	]:
		_assert_true(result_panel.get_node(action_path) is Button,
			"the result panel must retain %s" % action_path)
	result_panel.configure_has_next(true)
	result_panel.configure_target(5.0)
	result_panel.show_coverage_result(4.6, 1, 0.0, 60.0, 1, &"manual")
	var summary := result_panel.get_node("Margin/Content/Summary") as ResultSummary
	_assert_true(not summary.get_node("VerdictRow/TimeoutClock").visible,
		"manual results must not show the timeout clock")
	_assert_true(summary.score_scale.target_range().is_equal_approx(Vector2(5.0, 100.0)),
		"result scale must use the configured authoritative target percentage")
	result_panel.show_coverage_result(4.6, 1, 0.0, 60.0, 1, &"timeout")
	_assert_true(summary.get_node("VerdictRow/TimeoutClock").visible,
		"timeout results must show the real clock asset")
	_assert_primary_action(result_panel, "Next")
	result_panel.focus_retry()
	_assert_true((result_panel.get_node("Margin/Content/Actions/Next") as Button).has_focus(),
		"coverage clear must focus the primary Next action")
	result_panel.configure_has_next(false)
	_assert_primary_action(result_panel, "Retry")
	_assert_true(not result_panel.get_node("Margin/Content/Actions/Next").visible,
		"the terminal catalog result must omit unavailable Next")
	var band := TargetBandData.new()
	band.target_min = 7.0
	band.target_max = 11.0
	result_panel.configure_target_band_model(
		band,
		ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.GREEN_ADD_RED_SUBTRACT)
	)
	result_panel.show_target_band_result(
		false, -3.0, band, 0, PaintCoverageSnapshot.new(4.0, 1.0, 5.0), 60.0, 1
	)
	_assert_true((summary.get_node("ValueRow/Value") as Label).text == "-3.0",
		"failed target-band result must preserve the authoritative signed score")
	_assert_true(is_equal_approx(summary.score_scale.value(), -3.0)
			and is_equal_approx(summary.score_scale.marker_value_for_test(), 0.0)
			and summary.score_scale.range_overflow_direction_for_test() == -1,
		"result summary must project only marker geometry to the zero endpoint")
	_assert_primary_action(result_panel, "RetrySameDeal")
	result_panel.configure_has_next(true)
	result_panel.show_target_band_result(
		true, 9.0, band, 3, PaintCoverageSnapshot.new(4.0, 5.0, 9.0), 60.0, 1
	)
	_assert_primary_action(result_panel, "Next")

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


func _assert_primary_action(result_panel: ResultPanel, expected_name: String) -> void:
	var primary_names: Array[String] = []
	for action_name in ["Retry", "Next", "RetrySameDeal", "NewDeal", "Stages"]:
		var action := result_panel.get_node("Margin/Content/Actions/%s" % action_name) as ActionControl
		if action.visible and action.visual_role == ActionControl.VisualRole.PRIMARY:
			primary_names.append(action_name)
	_assert_true(primary_names == [expected_name],
		"result must expose one primary %s action, got %s" % [expected_name, primary_names])
