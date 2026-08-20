extends SceneTree

const STAGE_SELECT_SCENE := preload("res://scenes/ui/screens/stage_select.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")

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
	var first_node := stage_select._stage_nodes[0]
	_assert(first_node.button_pressed,
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

	stage_select.set_page_for_capture(1)
	await process_frame
	_assert(stage_select._stage_nodes[0].button_pressed,
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

	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	hud.configure(StageCatalog.get_stage(&"stage_01"))
	hud.show_state(StageController.State.BRIEFING)
	var score_scale := hud.get_node("HUDRoot/ScoreScale") as ScoreScale
	_assert(score_scale.visible and score_scale.target_range().is_equal_approx(Vector2(7.0, 11.0)),
		"prototype briefing must introduce its active rule through the shared scale")
	hud.configure(StageCatalog.get_stage(&"stage_09"))
	hud.show_state(StageController.State.BRIEFING)
	_assert(score_scale.visible \
			and score_scale.target_range().is_equal_approx(Vector2(7.0, 11.0)),
		"later briefing must present its target band through the same scale")

	TranslationServer.set_locale(previous_locale)
	game_state.persistence_enabled = true
	stage_select.queue_free()
	hud.queue_free()
	await process_frame
	if not _failed:
		print("Stage-selection truth passed: early and later target-band rules use shared scale and deal detail.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage-selection rule truth failed: %s" % message)
