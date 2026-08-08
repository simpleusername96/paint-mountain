extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.select_stage(&"stage_01")
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	_assert_true(gameplay != null, "shot feedback requires the baked Stage 01 layout")
	if gameplay == null:
		quit(1)
		return
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	var controller: StageController = gameplay.get_node("StageController")
	var hud: HUDController = gameplay.get_node("HUD")
	var hud_root: Control = gameplay.get_node("HUD/HUDRoot")
	_assert_true(controller.begin_aiming(), "feedback fixture must enter aiming")
	await process_frame
	_assert_true(
		hud_root.get_node_or_null("FirstSessionHint") == null,
		"obsolete four-second help must be removed after persistent prompts exist"
	)
	var hint := hud_root.get_node("ContextLine") as Control
	var fire := hud_root.get_node("ActionButtons/FireButton") as Button
	var aim_controls := hud_root.get_node("AimControls") as Control
	var coverage_panel := hud_root.get_node("CoverageMeter") as Control
	_assert_true(
			not hint.get_global_rect().intersects(fire.get_global_rect()) \
					and not hint.get_global_rect().intersects(aim_controls.get_global_rect()) \
					and not hint.get_global_rect().intersects(coverage_panel.get_global_rect()),
			"persistent aim context must remain clear of Fire, aim controls, and coverage"
	)
	var power_decrease := hud_root.get_node("AimControls/Content/PowerDecrease") as Button
	var power_increase := hud_root.get_node("AimControls/Content/PowerIncrease") as Button
	_assert_true(power_decrease.tooltip_text == "파워 2% 낮추기" and power_increase.tooltip_text == "파워 2% 높이기", "power controls must expose localized tooltips")
	_assert_true(power_decrease.get_theme_color("icon_normal_color").is_equal_approx(Color("172538")), "power glyphs must use the navy icon tint")
	hud.update_aim(-7.5, 41.0, 72.0)
	_assert_true("왼쪽" in hud_root.get_node("AimControls/Content/DirectionValue").text and "41.0°" in hud_root.get_node("AimControls/Content/ElevationValue").text, "aim panel must expose direction and elevation independently")
	var interaction_control := hud_root.get_node("CameraInteractionControl") as CameraInteractionControl
	_assert_true(
		interaction_control != null and interaction_control.visible \
				and interaction_control.custom_minimum_size.y >= 40.0,
		"Aiming must expose one focusable interaction-mode control"
	)
	_assert_true(
		hud_root.get_node_or_null("ObservationControls") == null \
				and not interaction_control.text.contains("추적") \
				and not interaction_control.text.contains("대포"),
		"normal gameplay must not expose camera presets, speed, or Pause strips"
	)
	hud.set_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION)
	_assert_true(
		interaction_control.visible and "지도 보기" in interaction_control.text \
				and not hud_root.get_node("AimControls").visible \
				and not hud_root.get_node("ActionButtons").visible \
				and hud_root.get_node("ContextLine").text == "드래그 회전 · 휠 확대",
		"Map Inspection must identify itself and hide aim-only actions"
	)
	hud.set_interaction_mode(CameraDirector.InteractionMode.AIM_LOCKED)
	_assert_true(
		"조준" in interaction_control.text \
				and hud_root.get_node("AimControls").visible \
				and hud_root.get_node("ActionButtons").visible \
				and hud_root.get_node("ContextLine").text \
						== "지형 클릭·드래그 · W S 각도 · 휠 파워",
		"Aim Lock must restore aim and Fire controls"
	)
	var coverage: CoverageMeter = hud_root.get_node("CoverageMeter")
	hud.update_coverage(2.0)
	await process_frame
	_assert_true(
		is_equal_approx(coverage.progress.max_value, 100.0)
		and is_equal_approx(coverage.progress.value, 2.0)
		and "목표" in coverage.target_label.text,
		"coverage must show the authoritative absolute 0..100 value with a visible target label"
	)
	var observation := ShotObservation.new()
	observation.configure(1, -7.5, 41.0, 72.0, 12.0)
	observation.record_mechanism_activation(
		0,
		&"Splitter",
		MechanismData.Kind.SPLITTER,
		Engine.get_physics_frames()
	)
	for ordinal in range(1, 4):
		observation.record_child_spawn(ordinal, 1, Engine.get_physics_frames(), 3)
	observation.seal(20.4, -1, 0x12345678)
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
		print("Shot feedback passed: direction, camera interaction state, target, causal summary, callout timing, and replay controls.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
