extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	var stage := load("res://resources/stages/first_descent.tres") as StageData
	hud.configure(stage)
	hud.show_state(StageController.State.AIMING)
	var hud_root := hud.get_node("HUDRoot") as Control
	var status := hud_root.get_node("RunStatusCard") as RunStatusCard
	_assert_true(status.visible and status.get_global_rect().get_center().x > 640.0, "run status must stay on the right edge during play")
	_assert_true(status.size.x < 1280.0 * 0.25, "run status must remain compact instead of spanning the mountain")
	_assert_true(not status.finish_is_available(), "Finish must be disabled before the first shot starts the clock")
	var finish_button := status.get_node("Margin/Content/Finish") as Button
	var finish_key := finish_button.shortcut.events[0] as InputEventKey
	_assert_true(finish_button.focus_mode != Control.FOCUS_NONE and finish_key.physical_keycode == KEY_F, "Finish must be keyboard-focusable and expose the F shortcut")

	hud.update_clock({
		"started": true,
		"duration_ticks": 5400,
		"remaining_ticks": 3600,
		"ticks_per_second": 60,
	})
	hud.update_shots(3, 4)
	hud.update_resident_activity(2, 1)
	_assert_true(status.finish_is_available(), "Finish must enable once the run clock has started")
	_assert_true(status.get_node("Margin/Content/TimeMetric/Value").text == "01:00", "clock must display the authoritative remaining time")
	_assert_true("2" in status.get_node("Margin/Content/ActivityMetric/Value").text and "1" in status.get_node("Margin/Content/ActivityMetric/Value").text, "resident activity must show moving and resting counts")

	var wind := WindSnapshot.new(
		1620,
		Vector3(4.2, 0.0, 0.0),
		Vector3(-5.0, 0.0, -1.0),
		0.70,
		0.84,
		3.0,
		0.5,
		&"hud-test"
	)
	hud.update_wind(wind, Vector2.RIGHT, RunStatusCard.DepthCue.NONE, Vector2.UP)
	_assert_true(status.get_node("Margin/Content/WindBox/WindArrow").text == "→", "wind arrow must show projectile push direction")
	_assert_true("오른쪽" in status.get_node("Margin/Content/WindBox/WindText/WindDirection").text, "wind must also state its direction in plain text")
	_assert_true(status.get_node("Margin/Content/WindForecast").visible, "the final transition window must reveal the next wind")
	var same_display_wind := WindSnapshot.new(
		1621,
		wind.acceleration,
		wind.next_acceleration,
		wind.normalized_strength,
		wind.next_normalized_strength,
		wind.seconds_until_change,
		wind.transition_progress,
		wind.schedule_identity
	)
	_assert_true(
		RunStatusCard.wind_display_key(
			wind,
			Vector2.RIGHT,
			RunStatusCard.DepthCue.NONE,
			Vector2.UP,
			RunStatusCard.DepthCue.NONE
		) == RunStatusCard.wind_display_key(
			same_display_wind,
			Vector2.RIGHT,
			RunStatusCard.DepthCue.NONE,
			Vector2.UP,
			RunStatusCard.DepthCue.NONE
		),
		"physics-tick-only wind changes must reuse the same pure HUD display key"
	)

	var finish_state := {"emitted": false}
	hud.finish_requested.connect(func() -> void: finish_state.emitted = true)
	finish_button.pressed.emit()
	_assert_true(bool(finish_state.emitted), "the focusable Finish button must expose one HUD intent")

	hud.show_coverage_result(37.4, 2, 31.0, 64.0, 3, &"timeout")
	hud.show_state(StageController.State.RESULT)
	var result := hud_root.get_node("ResultPanel") as ResultPanel
	_assert_true(result.visible and not status.visible, "RESULT must replace live status with the coverage result panel")
	_assert_true(not status.finish_is_available(), "Finish must be unavailable after the result is fixed")
	_assert_true(result.title.text == "시간 종료", "timeout result must state its terminal reason without failure language")
	var result_copy := _collect_label_text(result)
	_assert_true("37.4%" in result_copy and "★★☆" in result_copy, "result must present final coverage and grade")
	_assert_true("목표 미달" not in result_copy and "부족 면적" not in result_copy, "coverage result must not use pass/fail or missing-target copy")

	hud.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Wind/result HUD passed: edge status, Finish gating, forecast, and coverage-only RESULT are coherent.")
	quit(1 if _failed else 0)


func _collect_label_text(parent: Node) -> String:
	var values: Array[String] = []
	for label in parent.find_children("*", "Label", true, false):
		values.append((label as Label).text)
	return "\n".join(values)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
