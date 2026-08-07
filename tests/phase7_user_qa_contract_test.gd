extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	var prepared_stage := catalog.get_stage(&"stage_01")
	var prepared_layout := StageLayoutBakeCodec.hydrate(
		load(catalog.get_layout_path(prepared_stage.stage_id)) as BakedStageLayoutData,
		prepared_stage
	)
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.prepare_stage(prepared_stage, prepared_layout)
	root.add_child(gameplay)
	await process_frame
	_assert(gameplay.get_node_or_null("OpenPlayEnvironment") is OpenPlayEnvironment, "gameplay must use the open environment")
	_assert(gameplay.get_node_or_null("BackstopEnvironment") == null, "gameplay must not contain a backstop")
	_assert(gameplay.get_node_or_null("CannonWindFlag") is CannonWindFlag, "gameplay must show a cannon-side wind flag")
	_assert(gameplay.get_node_or_null("WindDebrisField") == null, "gameplay must not retain wind debris")
	var hud := gameplay.get_node_or_null("HUD") as HUDController
	_assert(hud != null and hud.get_node_or_null("HUDRoot/ReturnToCannon") is Button, "HUD must expose a contextual return-to-cannon action")
	var translations := FileAccess.get_file_as_string("res://translations/ui.csv")
	_assert(translations.contains("hud.return_to_cannon") and translations.contains("Aim View") \
			and translations.contains("지도 보기"), "current camera vocabulary must be localized")
	_assert(not translations.contains("Aim Lock") and not translations.contains("Map Inspection"), "obsolete player-facing camera labels must be absent")
	for stage_id in [&"stage_01", &"stage_30"]:
		var stage := catalog.get_stage(stage_id)
		var layout := StageLayoutBakeCodec.hydrate(
			load(catalog.get_layout_path(stage_id)) as BakedStageLayoutData,
			stage
		)
		_assert(layout != null and layout.is_runtime_ready(), "%s must enter from its persisted fixed layout" % stage_id)
	gameplay.queue_free()
	await process_frame
	if not _failed:
		print("phase7_user_qa_contract_test passed: current scene, copy, fixed layouts, flag, and return action")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
