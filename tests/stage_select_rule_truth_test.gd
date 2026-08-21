extends SceneTree

const STAGE_SELECT_SCENE := preload("res://scenes/ui/screens/stage_select.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var previous_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	game_state.select_stage(&"stage_01")
	var stage_select := STAGE_SELECT_SCENE.instantiate() as StageSelectScreen
	root.add_child(stage_select)
	await process_frame

	var preview_stats := stage_select.get_node("Root/SelectedInfo/PreviewStats")
	_assert(stage_select._stage_rail.selected_stage_id() == &"stage_01",
		"the selected prototype stage must have one visible active rail node")
	_assert("7-11" in preview_stats.detail_text(),
		"prototype preview must expose its target-band range")
	_assert(tr("ball.standard") in preview_stats.accessibility_name,
		"prototype preview must expose allowed kinds through its detail: %s" % preview_stats.accessibility_name)
	_assert(
		(tr("ball.impact_burst") in preview_stats.accessibility_name) \
				== (BallKind.Value.IMPACT_BURST in StageCatalog.get_stage(&"stage_01").ball_deal_profile.allowed_kinds),
		"prototype preview must match the current allowed-kind profile: %s" % preview_stats.accessibility_name
	)
	var persisted_stage_id := game_state.selected_stage_id
	stage_select._stage_nodes[1].pressed.emit()
	_assert(stage_select.selected_stage_id() == &"stage_02",
		"rail click must select the exact stage")
	stage_select.select_relative_for_capture(-1)
	_assert(stage_select.selected_stage_id() == &"stage_01",
		"terrain-side previous intent must use the same selection owner")
	await process_frame
	var rail := stage_select._stage_rail
	var start := rail._buttons[0].position + rail._buttons[0].size * 0.5
	var destination := rail._buttons[2].position + rail._buttons[2].size * 0.5
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	rail._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = destination
	rail._gui_input(release)
	_assert(stage_select.selected_stage_id() == &"stage_03",
		"rail drag must resolve through the same stage selection owner")
	_assert(game_state.selected_stage_id == persisted_stage_id,
		"preview selection must not commit GameState before Start")

	stage_select.set_page_for_capture(1)
	await process_frame
	_assert(stage_select._stage_rail.selected_stage_id() == &"stage_11",
		"the selected later target-band stage must have one visible active rail node")
	_assert("R" in preview_stats.detail_text() and "G" in preview_stats.detail_text(),
		"later-stage preview must retain target band and both color weights")
	for font_symbol in ["◎", "●", "◉", "◷", "◆", "✹", "♣"]:
		_assert(font_symbol not in preview_stats.detail_text(),
			"rule summary must not depend on a platform font glyph: %s" % font_symbol)
	_assert(tr("ball.impact_burst") in preview_stats.accessibility_name \
			and tr("ball.apex_split") in preview_stats.accessibility_name,
		"later-stage detail must expose both required special kinds")
	preview_stats.configure(StageCatalog.get_stage(&"stage_12"))
	_assert(tr("hud.finish_use_required_balls") in preview_stats.accessibility_name \
			and tr("ball.impact_burst") in preview_stats.accessibility_name \
			and tr("ball.apex_split") in preview_stats.accessibility_name,
		"required glyphs must have equivalent accessible text")

	_assert(stage_select.get_node_or_null("Root/BriefingActions") == null,
		"Stage Select must own briefing truth without a second action screen")
	stage_select._on_stage_requested(&"stage_09")
	_assert("7-11" in preview_stats.detail_text(),
		"later Stage Select briefing truth must update through the same rule summary")

	TranslationServer.set_locale(previous_locale)
	game_state.persistence_enabled = true
	stage_select.queue_free()
	await process_frame
	if not _failed:
		print("Stage-selection truth passed: the merged screen owns early and later rule/deal detail.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage-selection rule truth failed: %s" % message)
