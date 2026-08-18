extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false
var _public_stage_finished: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var paint := gameplay.get_node("PaintSystem") as PaintSystem
	var agent := gameplay.get_node("GameplayAgentApi") as GameplayAgentApi
	agent.gameplay_event.connect(_on_agent_event)
	_assert(controller.begin_aiming(), "prototype must enter aiming")
	_assert(not controller.finish_stage(), "Finish must reject before first shot")
	_assert(controller.request_fire(), "first target-band shot must launch")
	manager.cleanup()
	paint.clear()
	await physics_frame
	await physics_frame
	var blocked := controller.finish_readiness_snapshot()
	_assert(bool(blocked.get("board_quiet", false)), "cleaned projectile and paint queues must be quiet")
	_assert(not bool(blocked.get("in_target_band", true)), "zero score must remain outside the authored 7–11 band")
	_assert(not controller.finish_stage(), "manual Finish must reject outside band")

	controller.stage_data.target_band.target_min = -1.0
	controller.stage_data.target_band.target_max = 1.0
	var ready := controller.finish_readiness_snapshot()
	_assert(bool(ready.get("ready", false)), "in-band quiet board after first shot must enable Finish")
	_assert(controller.finish_stage(), "authoritative Finish must accept only when ready")
	var manual := controller.result_snapshot()
	_assert(bool(manual.get("cleared", false)) and int(manual.get("stars", 0)) == 3, "centered manual result must clear with three stars")
	_assert(not Dictionary(agent.get_observation().get("result", {})).has("deal_seed"), "public terminal observation must not expose the private deal seed")
	_assert(not _public_stage_finished.has("deal_seed"), "public terminal event must not expose the private deal seed")

	var completed_seed := controller.deal_seed()
	_assert(controller.restart_new_deal(false), "New Deal must work from the target-band result screen")
	_assert(controller.deal_seed() != completed_seed, "result-screen New Deal must advance to a different deal")
	controller.stage_data.target_band.target_min = -100.0
	controller.stage_data.target_band.target_max = 100.0
	for shot_index in range(controller.stage_data.maximum_shots):
		_assert(controller.request_fire(), "queue shot %d must launch" % shot_index)
		manager.cleanup()
		paint.clear()
		await physics_frame
		await physics_frame
		if controller.current_state == StageController.State.RESULT:
			break
	var budget := 30
	while controller.current_state != StageController.State.RESULT and budget > 0:
		await physics_frame
		budget -= 1
	_assert(controller.current_state == StageController.State.RESULT, "quiet exhausted queue must auto-finish")
	var exhausted := controller.result_snapshot()
	_assert(exhausted.get("finish_reason") == StageController.FINISH_REASON_QUEUE_EXHAUSTED, "auto result must retain queue-exhausted reason")
	_assert(bool(exhausted.get("cleared", false)), "queue exhaustion still clears when final score is in band")

	gameplay.queue_free()
	await process_frame
	if not _failed:
		print("stage_finish_readiness_test passed: quiet gate, band gate, manual Finish, and exhaustion")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage Finish readiness check failed: %s" % message)


func _on_agent_event(event_name: StringName, payload: Dictionary) -> void:
	if event_name == &"stage_finished":
		_public_stage_finished = payload.duplicate(true)
