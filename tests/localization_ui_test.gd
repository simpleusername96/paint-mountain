extends SceneTree

const STAGE_SELECT_SCENE := preload("res://scenes/ui/screens/stage_select.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings.tscn")
const AIM_CONTROLS_SCENE := preload("res://scenes/ui/hud/aim_controls.tscn")
const MIGRATION_PATH := "user://paint_mountain_localization_v1.json"

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node("/root/SaveSystem")
	var defaults: Dictionary = save_system.default_data()
	_assert_true(defaults.version == 5, "current saves must use format 5")
	_assert_true(
		int(defaults.coverage_metric_version) == TargetSurfaceCoverage.METRIC_VERSION,
		"current saves must identify the physical-area coverage metric"
	)
	_assert_true(defaults.settings.language == "ko", "new installs must default to Korean")
	_assert_true(not defaults.settings.language_user_selected, "new installs must not claim an explicit language choice")
	_assert_true(not defaults.settings.reduced_motion, "decorative motion must remain enabled by default")
	_assert_true(
		not defaults.settings.has("aim_sensitivity_percent"),
		"new saves must omit the retired mouse aim sensitivity setting"
	)

	_write_v1_fixture()
	var migrated: Dictionary = save_system.load_data(MIGRATION_PATH)
	_assert_true(migrated.version == 5, "format 1 saves must migrate to format 5")
	_assert_true(not migrated.has("unlocked_stages"), "all-open migration must discard the obsolete lock list")
	_assert_true(
		migrated.best_results.is_empty() \
				and is_equal_approx(
					float(migrated.legacy_best_results.first_descent.coverage), 14.25
				),
		"metric-1 best results must be preserved only in the legacy envelope"
	)
	_assert_true(is_equal_approx(float(migrated.settings.master_volume), 0.37), "migration must preserve settings")
	_assert_true(migrated.settings.language == "ko" and not migrated.settings.language_user_selected, "migration must add the Korean default without fabricating a choice")
	_assert_true(not migrated.settings.has("aim_sensitivity_percent"), "format-5 migration must ignore the retired sensitivity key")

	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.initialize_from_data(defaults)
	_assert_true(TranslationServer.get_locale().begins_with("ko"), "the runtime locale must initialize in Korean")
	_assert_true(tr("ui.play") == "플레이", "Korean translations must be available")
	_assert_translation_contract("ko")

	var stage_select := STAGE_SELECT_SCENE.instantiate() as StageSelectScreen
	var settings := SETTINGS_SCENE.instantiate() as SettingsScreen
	var aim_controls := AIM_CONTROLS_SCENE.instantiate() as AimControls
	root.add_child(stage_select)
	root.add_child(settings)
	root.add_child(aim_controls)
	await process_frame
	await process_frame
	stage_select.visible = true
	stage_select.refresh()
	await process_frame
	_assert_true(not stage_select._cards.is_empty(), "stage select must build its card controls")
	if not stage_select._cards.is_empty():
		_assert_true("첫 번째 하강" in stage_select._cards[0].text, "stage cards must render in Korean")

	game_state.update_setting(&"language", "en", false)
	await process_frame
	aim_controls.refresh_locale()
	_assert_true(tr("ui.play") == "PLAY", "English translations must be available")
	_assert_translation_contract("en")
	if not stage_select._cards.is_empty():
		_assert_true("FIRST DESCENT" in stage_select._cards[0].text, "dynamic stage cards must update immediately after a locale switch")
	var language_option: OptionButton = settings._controls.get(&"language")
	_assert_true(language_option.get_item_text(0) == "KOREAN" and language_option.get_item_text(1) == "ENGLISH", "language option labels must update immediately")
	var quality_option: OptionButton = settings._controls.get(&"quality")
	var resolution_option: OptionButton = settings._controls.get(&"resolution")
	var display_mutations_before_passive_sync := settings.display_mutation_count()
	settings._sync_from_state()
	settings._apply_setting(&"master_volume", 0.5)
	settings._apply_setting(&"quality", "medium")
	_assert_true(
		settings.display_mutation_count() == display_mutations_before_passive_sync,
		"passive settings synchronization and non-display changes must not mutate window geometry"
	)
	_assert_true(quality_option.get_item_text(1) == "MEDIUM", "quality display text must localize without changing metadata")
	_assert_true(quality_option.get_item_metadata(1) == "medium", "quality metadata must remain stable")
	_assert_true(resolution_option.get_item_text(0) == "1280 × 720" and resolution_option.get_item_metadata(0) == "1280x720", "resolution display formatting must preserve stored metadata")
	_assert_true(
		aim_controls.get_node("Content/ElevationCaption").text == "∠" \
				and aim_controls.get_node("Content/PowerCaption").text == "▰",
		"Aim controls must use locale-independent instrument symbols"
	)
	_assert_true(
		(aim_controls.get_node("Content/AngleDecrease") as Button).size.y >= 40.0,
		"angle controls must retain a 40px focusable target"
	)
	_assert_true(
		(aim_controls.get_node("Content/AngleDecrease") as Button).tooltip_text == "DECREASE ANGLE",
		"angle controls must refresh English tooltips"
	)
	var angle_steps: Array[float] = []
	var power_steps: Array[float] = []
	aim_controls.angle_step_requested.connect(func(step: float) -> void: angle_steps.append(step))
	aim_controls.power_step_requested.connect(func(step: float) -> void: power_steps.append(step))
	(aim_controls.get_node("Content/AngleIncrease") as Button).button_down.emit()
	(aim_controls.get_node("Content/AngleIncrease") as Button).button_up.emit()
	(aim_controls.get_node("Content/PowerDecrease") as Button).button_down.emit()
	(aim_controls.get_node("Content/PowerDecrease") as Button).button_up.emit()
	aim_controls.update_aim(0.0, 38.0, 68.1)
	_assert_true(angle_steps == [1.0] and power_steps == [-2.0], "Aim controls must emit target-preserving angle direction and 2-percent step intents")
	_assert_true(
		aim_controls.get_node("Content/ElevationValue").text == "38.0°" \
				and aim_controls.get_node("Content/PowerValue").text == "68.1%",
		"Aim controls must display elevation and solved power to one decimal"
	)

	game_state.update_setting(&"language", "ko", false)
	await process_frame
	aim_controls.refresh_locale()
	if not stage_select._cards.is_empty():
		_assert_true("첫 번째 하강" in stage_select._cards[0].text, "switching back to Korean must refresh dynamic UI")
	_assert_true(quality_option.get_item_text(1) == "보통", "Korean quality display must refresh immediately")
	game_state.update_setting(&"resolution", "1600x900", false)
	game_state.update_setting(&"fullscreen", true, false)
	settings._apply_setting(&"fullscreen", true)
	await process_frame
	_assert_true(resolution_option.disabled, "Resolution must disable while fullscreen is stored")
	game_state.update_setting(&"fullscreen", false, false)
	settings._apply_setting(&"fullscreen", false)
	await process_frame
	_assert_true(not resolution_option.disabled, "Resolution must re-enable after returning to windowed mode")
	if DisplayServer.get_name() != "headless":
		_assert_true(DisplayServer.window_get_size() == Vector2i(1600, 900), "leaving fullscreen must reapply the stored windowed resolution")
	else:
		_assert_true(game_state.settings.resolution == "1600x900", "headless display checks must preserve the requested windowed resolution")
	game_state.update_setting(&"resolution", "1280x720", false)
	_assert_control_inside_viewport(settings.get_node("SettingsRoot/Panel"), "settings panel")

	_cleanup_fixture()
	stage_select.queue_free()
	settings.queue_free()
	aim_controls.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Localization UI passed: Korean default, format 1 migration, live locale switching, and 720p-safe settings bounds.")
	quit(1 if _failed else 0)


func _write_v1_fixture() -> void:
	var absolute_path := ProjectSettings.globalize_path(MIGRATION_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var fixture := {
		"version": 1,
		"unlocked_stages": ["first_descent", "burst_basin"],
		"best_results": {"first_descent": {"coverage": 14.25, "stars": 2}},
		"settings": {
			"master_volume": 0.37,
			"quality": "high",
			"aim_sensitivity_percent": 50,
		},
	}
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture))
	file.close()


func _cleanup_fixture() -> void:
	var absolute_path := ProjectSettings.globalize_path(MIGRATION_PATH)
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(absolute_path + suffix):
			DirAccess.remove_absolute(absolute_path + suffix)


func _assert_control_inside_viewport(control: Control, label: String) -> void:
	var viewport_size := root.get_viewport().get_visible_rect().size
	var rect := control.get_global_rect()
	_assert_true(rect.position.x >= 0.0 and rect.position.y >= 0.0, "%s must not clip above or left: rect=%s viewport=%s" % [label, rect, viewport_size])
	_assert_true(rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y, "%s must not clip below or right: rect=%s viewport=%s" % [label, rect, viewport_size])


func _assert_translation_contract(locale: String) -> void:
	var required := [
		"hud.direction", "hud.direction_left", "hud.direction_right", "hud.direction_center",
		"hud.coverage", "hud.coverage_format", "hud.summary_split", "hud.summary_balls",
		"hud.summary_direct", "hud.aim_context", "hud.map_context", "hud.aim_lock", "hud.map_inspection",
		"hud.switch_to_map_inspection", "hud.switch_to_aim_lock", "mechanism.burst.description",
		"hud.time", "hud.resident_balls", "hud.resident_activity_format", "hud.resident_total_format", "hud.wind",
		"hud.wind_right", "hud.wind_into_screen", "hud.wind_out_of_screen",
		"hud.wind_strength_format", "hud.wind_change_format", "hud.wind_next_format",
		"hud.finish_tooltip", "hud.finish_disabled_tooltip", "ui.finish",
		"fire.aim_revision_pending",
		"result.completed", "result.time_expired", "result.final", "result.grade", "result.elapsed",
		"mechanism.splitter.description", "mechanism.uphill_rebound.description", "mechanism.activated",
		"settings.reduced_motion",
		"settings.quality_low", "settings.quality_medium", "settings.quality_high",
		"hud.angle_decrease", "hud.angle_increase", "hud.power_decrease", "hud.power_increase",
		"ui.previous", "ui.loading_stage", "ui.stage_load_failed", "ui.retry_stage_load",
	]
	for key in required:
		_assert_true(tr(key) != key, "%s translation must define %s" % [locale, key])
	if locale == "ko":
		_assert_true(tr("hud.coverage") == "목표 영역", "Korean coverage caption must name the target area")
		_assert_true(tr("hud.coverage_format") == "목표 영역 %.1f%% / 목표 %.1f%%", "Korean coverage format must distinguish the target area from its goal")
		_assert_true(tr("hud.finish_tooltip") == "목표 영역 칠함으로 완료 (F)", "Korean Finish tooltip must state that it scores target-area coverage")
		_assert_true(tr("result.final") == "최종 목표 영역", "Korean result caption must name target coverage")
		_assert_true(tr("stage.first_descent.objective") == "넓은 경사면의 높은 지점을 노리고 공이 구르며 칠하게 하세요.", "First Descent Korean copy must describe rolling contact paint")
		_assert_true(tr("stage.split_ridge.objective") == "분열과 오르막 반동 문양으로 세 갈래 경로를 모두 공략하세요.", "Split Ridge Korean copy must name the surface glyphs")
		_assert_true(tr("mechanism.burst.description") == "명중하면 주변 목표 표면에 넓은 자국을 칠합니다.", "Burst Korean copy must match continuous-paint terminology")
		_assert_true(tr("mechanism.splitter.description") == "각자 칠하는 공 세 개를 만들어 여러 경로로 보냅니다.", "Splitter Korean copy must describe independent painters")
		_assert_true(tr("mechanism.uphill_rebound.description") == "공을 지형에서 가장 높은 오르막 방향으로 다시 튕겨 보냅니다.", "Uphill Rebound Korean copy must explain its useful direction")
	else:
		_assert_true(tr("hud.coverage") == "TARGET AREA", "English coverage caption must name the target area")
		_assert_true(tr("hud.coverage_format") == "Target area %.1f%% / Goal %.1f%%", "English coverage format must distinguish the target area from its goal")
		_assert_true(tr("hud.finish_tooltip") == "Finish and score target-area coverage (F)", "English Finish tooltip must state that it scores target-area coverage")
		_assert_true(tr("result.final") == "FINAL TARGET COVERAGE", "English result caption must name target coverage")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
