extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.selected_stage_id = &"first_descent"
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	var controller: StageController = gameplay.get_node("StageController")
	var hud: HUDController = gameplay.get_node("HUD")
	var hud_root: Control = gameplay.get_node("HUD/HUDRoot")
	_assert_true(controller.begin_aiming(), "feedback fixture must enter aiming")
	await process_frame
	_assert_true(hud_root.get_node("FirstSessionHint").visible and is_equal_approx(hud_root.get_node("FirstSessionHint/HintTimer").wait_time, 4.0), "Stage 1 must show one four-second aiming hint")
	hud.update_aim(-7.5, 41.0, 72.0)
	_assert_true("왼쪽" in hud_root.get_node("AimControls/Content/DirectionValue").text and "41.0°" in hud_root.get_node("AimControls/Content/ElevationValue").text, "aim panel must expose direction and elevation independently")
	hud.update_payload(156.0, 520.0)
	_assert_true("156 / 520" in hud_root.get_node("ObservationControls/Content/PayloadValue").text, "observation controls must show aggregate remaining payload")
	var coverage: CoverageMeter = hud_root.get_node("CoverageMeter")
	hud.update_coverage(2.0)
	await process_frame
	_assert_true(is_equal_approx(coverage.progress.max_value, 100.0) and coverage.target_marker.size.x == 2.0, "coverage must use an absolute 0..100 scale with a distinct target marker")
	var observation := ShotObservation.new()
	observation.configure(1, -7.5, 41.0, 72.0, 12.0, 520.0)
	observation.record_mechanism_activation(MechanismData.Kind.SPLITTER)
	observation.record_children_spawned(3, 3)
	observation.seal(20.4)
	hud.show_shot_observation(observation)
	var summary: ShotSummary = hud_root.get_node("ShotSummary")
	_assert_true(summary.visible and "분열 1회" in summary.summary.text and "공 3개" in summary.summary.text, "sealed shot summary must explain gain and observed causes")
	_assert_true(absf(summary.timer.wait_time - 1.2) <= 0.1, "shot summary lifetime must be 1.2 ± 0.1 seconds")
	hud.show_mechanism_activation(MechanismData.Kind.SPLITTER)
	var mechanism_card: MechanismInfoCard = hud_root.get_node("MechanismInfoCard")
	_assert_true(mechanism_card.visible and mechanism_card.title.text == "분열", "mechanism callout must show the localized mechanism name")
	_assert_true(absf(mechanism_card.timer.wait_time - 1.2) <= 0.1, "mechanism callout lifetime must be 1.2 ± 0.1 seconds")
	hud.set_replay_active(true)
	_assert_true(hud_root.get_node("ReplayBar").visible and not hud_root.get_node("ActionButtons").visible, "replay state must expose only replay controls")
	hud.set_replay_active(false)
	var shader_source := FileAccess.get_file_as_string("res://src/paint/terrain_paint.gdshader")
	_assert_true(not shader_source.contains("EMISSION"), "terrain shader must not write emission")
	_assert_true(shader_source.contains("mix(0.88, 0.24, painted)"), "terrain shader must bind 0.88 dry and 0.24 painted roughness")
	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Shot feedback passed: direction, payload, target, causal summary, callout timing, and replay controls.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
