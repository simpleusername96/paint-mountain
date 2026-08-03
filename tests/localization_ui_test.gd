extends SceneTree

const APP_SCENE := preload("res://scenes/app/app.tscn")
const MIGRATION_PATH := "user://paint_mountain_localization_v1.json"

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node("/root/SaveSystem")
	var defaults: Dictionary = save_system.default_data()
	_assert_true(defaults.version == 2, "current saves must use format 2")
	_assert_true(defaults.settings.language == "ko", "new installs must default to Korean")
	_assert_true(not defaults.settings.language_user_selected, "new installs must not claim an explicit language choice")

	_write_v1_fixture()
	var migrated: Dictionary = save_system.load_data(MIGRATION_PATH)
	_assert_true(migrated.version == 2, "format 1 saves must migrate to format 2")
	_assert_true(migrated.unlocked_stages.size() == 2, "migration must preserve unlocked stages")
	_assert_true(is_equal_approx(float(migrated.best_results.first_descent.coverage), 14.25), "migration must preserve best results")
	_assert_true(is_equal_approx(float(migrated.settings.master_volume), 0.37), "migration must preserve settings")
	_assert_true(migrated.settings.language == "ko" and not migrated.settings.language_user_selected, "migration must add the Korean default without fabricating a choice")

	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.initialize_from_data(defaults)
	_assert_true(TranslationServer.get_locale().begins_with("ko"), "the runtime locale must initialize in Korean")
	_assert_true(tr("ui.play") == "플레이", "Korean translations must be available")
	_assert_translation_contract("ko")

	var app := APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var stage_select: StageSelectScreen = app.get_node("StageSelect")
	var settings: SettingsScreen = app.get_node("Settings")
	app._show_stage_select()
	await process_frame
	_assert_true("첫 번째 하강" in stage_select._cards[0].text, "stage cards must render in Korean")

	game_state.update_setting(&"language", "en", false)
	await process_frame
	_assert_true(tr("ui.play") == "PLAY", "English translations must be available")
	_assert_translation_contract("en")
	_assert_true("FIRST DESCENT" in stage_select._cards[0].text, "dynamic stage cards must update immediately after a locale switch")
	var language_option: OptionButton = settings._controls.get(&"language")
	_assert_true(language_option.get_item_text(0) == "KOREAN" and language_option.get_item_text(1) == "ENGLISH", "language option labels must update immediately")

	game_state.update_setting(&"language", "ko", false)
	await process_frame
	_assert_true("첫 번째 하강" in stage_select._cards[0].text, "switching back to Korean must refresh dynamic UI")
	_assert_control_inside_viewport(settings.get_node("SettingsRoot/Panel"), "settings panel")

	_cleanup_fixture()
	app.queue_free()
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
		"settings": {"master_volume": 0.37, "quality": "high"},
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
		"hud.payload", "hud.coverage_format", "hud.summary_split", "hud.summary_balls",
		"hud.summary_direct", "hud.first_hint", "mechanism.burst.description",
		"mechanism.splitter.description", "mechanism.bumper.description", "mechanism.activated",
		"replay.label", "replay.pause", "replay.play", "replay.restart", "replay.exit",
		"replay.incompatible_format",
	]
	for key in required:
		_assert_true(tr(key) != key, "%s translation must define %s" % [locale, key])
	if locale == "ko":
		_assert_true(tr("mechanism.burst.description") == "명중하면 주변 유효 경로에 페인트를 퍼뜨립니다.", "Burst Korean copy must match the frozen brief")
		_assert_true(tr("mechanism.splitter.description") == "남은 페인트를 세 공으로 나눠 여러 경로로 보냅니다.", "Splitter Korean copy must match the frozen brief")
		_assert_true(tr("mechanism.bumper.description") == "공을 화살표 방향의 다음 경사로 되돌려 보냅니다.", "Bumper Korean copy must match the frozen brief")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
