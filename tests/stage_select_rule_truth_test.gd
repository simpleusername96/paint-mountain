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

	var preview_stats := stage_select.get_node("Root/PreviewPanel/Margin/Content/PreviewStats") as Label
	var first_card := stage_select.get_node(
		"Root/CardsPanel/Margin/Content/Cards/StageCardButton"
	) as StageCardButton
	_assert(first_card.get_node("Margin/Content/Header/RuleBadge").visible,
		"prototype cards must carry a visible rule badge")
	_assert(tr("stage.target_band") in preview_stats.text,
		"prototype preview must name the target-band rule")
	_assert(tr("stage.allowed_balls") in preview_stats.text,
		"prototype preview must list allowed kinds")
	_assert("Impact Burst" not in preview_stats.text,
		"stage 1 must not expose a kind that its profile does not allow")

	stage_select.set_page_for_capture(1)
	await process_frame
	_assert(not first_card.get_node("Margin/Content/Header/RuleBadge").visible,
		"legacy cards must not carry the prototype badge")
	_assert(tr("stage.target") in preview_stats.text and tr("stage.mechanisms") in preview_stats.text,
		"legacy preview must retain scalar target and glyph mechanism facts")
	_assert(tr("stage.target_band") not in preview_stats.text,
		"legacy preview must not claim target-band scoring")

	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	hud.configure(StageCatalog.get_stage(&"stage_01"))
	hud.show_state(StageController.State.BRIEFING)
	var briefing_rule := hud.get_node("HUDRoot/BriefingRule") as PanelContainer
	var briefing_text := hud.get_node("HUDRoot/BriefingRule/Margin/Content/Text") as Label
	_assert(briefing_rule.visible and not briefing_text.text.is_empty(),
		"prototype briefing must introduce its active rule")
	hud.configure(StageCatalog.get_stage(&"stage_09"))
	hud.show_state(StageController.State.BRIEFING)
	_assert(not briefing_rule.visible,
		"legacy briefing must not show target-band prototype copy")

	TranslationServer.set_locale(previous_locale)
	game_state.persistence_enabled = true
	stage_select.queue_free()
	hud.queue_free()
	await process_frame
	if not _failed:
		print("Stage-selection truth passed: prototype rule/kinds and legacy glyph facts stay distinct.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage-selection rule truth failed: %s" % message)
