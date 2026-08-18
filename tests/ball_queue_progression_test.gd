extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller := gameplay.get_node("StageController") as StageController
	var agent := gameplay.get_node("GameplayAgentApi") as GameplayAgentApi
	_assert(controller.stage_data.uses_target_band(), "stage 01 must use target-band rule")
	var first_full := controller.attempt_deal_snapshot()
	var first_visible := controller.visible_queue_snapshot()
	_assert(first_full.size() == 4 and first_visible.size() == 3, "four-shot deal must expose only current plus next two")
	var scheduler := gameplay.get_node("TrajectoryPredictionScheduler") as TrajectoryPredictionScheduler
	_assert(scheduler._context_discriminator == controller.current_ball_token().stable_key(), "prediction identity must include the current kind and channel")
	var agent_state := agent.get_observation()
	_assert(Array(agent_state.get("visible_queue", [])).size() == 3, "public agent must see the same three-token horizon")
	_assert(not agent_state.has("deal_seed"), "public agent must not receive a reconstructable deal seed")
	_assert(controller.queue_cursor() == 0 and controller.shots_remaining == 4, "deal must begin at token zero")
	_assert(not controller.request_fire(), "Fire in Briefing must reject")
	_assert(controller.queue_cursor() == 0 and controller.shots_remaining == 4, "rejected Fire must consume nothing")

	_assert(controller.begin_aiming(), "prototype must enter aiming")
	_assert(controller.request_fire(), "valid root admission must succeed")
	_assert(controller.queue_cursor() == 1 and controller.shots_remaining == 3, "accepted root must consume one token and shot")
	_assert(scheduler._context_discriminator == controller.current_ball_token().stable_key(), "queue advancement must refresh full token prediction identity")
	var fired := controller.current_shot_observation()
	_assert(fired != null and BallKind.is_valid(fired.ball_kind), "shot observation must retain fired kind")
	_assert(fired != null and PaintChannel.is_valid(fired.paint_channel), "shot observation must retain fired channel")

	var seed_before := controller.deal_seed()
	_assert(controller.restart(false), "Same Deal must restart directly to aiming")
	_assert(controller.deal_seed() == seed_before, "Same Deal must preserve seed")
	_assert(_same_deal(controller.attempt_deal_snapshot(), first_full), "Same Deal must preserve exact token order")
	_assert(controller.queue_cursor() == 0 and controller.shots_remaining == 4, "Same Deal must restore cursor and shots")

	_assert(controller.restart_new_deal(false), "New Deal must find another constrained deal")
	_assert(controller.deal_seed() != seed_before, "New Deal must advance seed")
	_assert(not _same_deal(controller.attempt_deal_snapshot(), first_full), "New Deal must change token order")
	_assert(Array(agent.get_observation().get("visible_queue", [])).size() == 3, "New Deal must still expose only three tokens")

	gameplay.queue_free()
	await process_frame
	if not _failed:
		print("ball_queue_progression_test passed: admission, hidden horizon, Same Deal, and New Deal")
	quit(1 if _failed else 0)


func _same_deal(left: Array[Dictionary], right: Array[Dictionary]) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if int(left[index].get("kind", -1)) != int(right[index].get("kind", -1)) \
				or int(left[index].get("channel", -1)) != int(right[index].get("channel", -1)):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Ball queue progression check failed: %s" % message)
