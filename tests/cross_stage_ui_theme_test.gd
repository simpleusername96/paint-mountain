extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	var hud_root := hud.get_node("HUDRoot") as Control
	var score_scale := hud_root.get_node("ScoreScale") as ScoreScale
	var queue := hud_root.get_node("BallQueue") as BallQueue
	var result := hud_root.get_node("ResultPanel") as ResultPanel
	_assert(hud_root.find_children("*", "ScoreScale", true, false).size() == 2,
		"HUD must retain one live scale and one result-summary scale")
	_assert(hud_root.find_children("*", "BallQueue", true, false).size() == 1,
		"HUD must retain one shared queue owner")
	_assert(result.get_node("Margin/Content/Summary") is ResultSummary,
		"every stage result must use the shared summary")

	var stages := StageCatalog.all_stages()
	_assert(stages.size() == 30, "catalog must provide all 30 stages")
	for stage in stages:
		_assert(stage != null and stage.has_valid_rule_contract(),
			"%s must provide a valid authoritative UI model" % stage.stage_id)
		if stage == null:
			continue
		hud.configure(stage)
		hud.set_camera_mode(CameraDirector.Mode.BRIEFING)
		hud.show_state(StageController.State.BRIEFING)
		await process_frame
		_assert(score_scale.visible, "%s briefing must expose ScoreScale" % stage.stage_id)
		_assert(score_scale.preset == ScoreScale.Preset.HORIZONTAL_SUMMARY,
			"%s briefing must use the horizontal score preset" % stage.stage_id)
		_assert(_range_is_valid(score_scale.target_range()),
			"%s briefing target must stay in the 0-100 domain" % stage.stage_id)
		_assert(queue.visible == stage.uses_target_band(),
			"%s queue visibility must follow its rule family" % stage.stage_id)

		hud.show_state(StageController.State.AIMING)
		hud.set_camera_mode(CameraDirector.Mode.AIMING)
		await process_frame
		_assert(score_scale.visible and score_scale.preset == ScoreScale.Preset.VERTICAL_LIVE,
			"%s aiming must use the shared vertical score preset" % stage.stage_id)
		_assert(_range_is_valid(score_scale.target_range()),
			"%s aiming target must stay in the 0-100 domain" % stage.stage_id)

		hud.set_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION)
		_assert(score_scale.visible, "%s map inspection must retain score truth" % stage.stage_id)
		_assert(not hud_root.get_node("AimControls").visible
				and not hud_root.get_node("ActionButtons").visible,
			"%s map inspection must remove cannon actions" % stage.stage_id)
		hud.set_camera_mode(CameraDirector.Mode.FOLLOW)
		_assert(score_scale.visible, "%s shot follow must retain score truth" % stage.stage_id)
		_assert(hud_root.get_node("ReturnToCannon").visible,
			"%s shot follow must expose the sole legal return action" % stage.stage_id)

		if stage.uses_target_band():
			result.show_target_band_result(
				false, 0.0, stage.target_band, 0, PaintCoverageSnapshot.new(), 30.0, 1
			)
		else:
			result.show_coverage_result(0.0, 0, 0.0, 30.0, 1)
		hud.show_state(StageController.State.RESULT)
		await process_frame
		_assert(result.visible and result.get_node("WorldScrim") is ContrastScrim,
			"%s result must use the direct shared world overlay" % stage.stage_id)
		var summary_scale := result.get_node("Margin/Content/Summary/ScoreScale") as ScoreScale
		_assert(_range_is_valid(summary_scale.target_range()),
			"%s result target must stay in the 0-100 domain" % stage.stage_id)

	hud.queue_free()
	await process_frame
	if not _failed:
		print("Cross-stage UI theme passed: all 30 stages share Cannon Focus state owners.")
	quit(1 if _failed else 0)


func _range_is_valid(target: Vector2) -> bool:
	return target.x >= 0.0 and target.y <= 100.0 and target.x <= target.y


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Cross-stage UI theme failed: %s" % message)
