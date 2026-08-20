extends SceneTree

const FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")
const CONTACT_BUDGET_TICKS := 900

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_id := &"stage_01"
	var deal_seed := -1
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			stage_id = StringName(argument.trim_prefix("--stage="))
		elif argument.begins_with("--deal-seed="):
			deal_seed = int(argument.trim_prefix("--deal-seed="))
	var gameplay := FIXTURE.instantiate(stage_id, deal_seed)
	_assert(gameplay != null, "stage fixture must instantiate")
	if gameplay == null:
		_finish()
		return
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var layout := gameplay.generated_layout() as GeneratedStageLayout
	var certificate := layout.reachability_certificate as DirectReachabilityCertificate
	var default_aim := layout.default_aim
	_assert(controller.stage_data.uses_target_band(), "witness requires a prototype stage")
	_assert(default_aim != null and default_aim.is_valid(), "witness requires a valid entry aim")
	_assert(controller.begin_aiming(), "witness must enter aiming")
	if _failed:
		gameplay.queue_free()
		await process_frame
		_finish()
		return
	Engine.time_scale = 4.0
	var witnesses: Array[AimTuple] = []
	if certificate != null and certificate.is_valid():
		witnesses = certificate.witnesses
	var shot_scores: Array[float] = []
	var positive_total := 0
	for token in controller._deal:
		if _channel_weight(controller.stage_data.color_score_rule, token.channel) > 0:
			positive_total += 1
	var positive_index := 0
	for shot_index in range(controller.stage_data.maximum_shots):
		if controller.current_state == StageController.State.RESULT:
			break
		var token := controller.current_ball_token()
		var weight := _channel_weight(controller.stage_data.color_score_rule, token.channel)
		var aim := _aim_for_shot(
			default_aim, witnesses, shot_index, controller.stage_data.maximum_shots,
			positive_index, positive_total, weight,
			controller.stage_data.color_score_rule
		)
		if weight > 0:
			positive_index += 1
		_assert(controller.set_aim(
			aim.yaw_degrees, aim.elevation_degrees, aim.power_percent,
			StageController.ActionOrigin.DEBUG
		), "certified witness aim must be accepted for shot %d" % (shot_index + 1))
		_assert(controller.request_fire(StageController.ActionOrigin.DEBUG),
			"typed root must launch for shot %d" % (shot_index + 1))
		if _failed:
			break
		var contact_budget := CONTACT_BUDGET_TICKS
		while manager.active_root_count() > 0 and contact_budget > 0:
			await physics_frame
			contact_budget -= 1
		_assert(contact_budget > 0,
			"shot %d must leave initial flight inside its direct-flight budget" % (shot_index + 1))
		var quiet_budget := 900
		while not controller.board_is_quiet() \
				and controller.current_state != StageController.State.RESULT \
				and quiet_budget > 0:
			await physics_frame
			quiet_budget -= 1
		var score := controller.score_snapshot()
		shot_scores.append(float(score.get("paint_score", 0.0)))
		if controller.current_state == StageController.State.AIMING \
				and bool(score.get("in_target_band", false)) \
				and controller.board_is_quiet():
			_assert(controller.finish_stage(StageController.ActionOrigin.HUMAN),
				"quiet in-band witness must accept Finish")
			break
	var finish_budget := controller.remaining_run_ticks() + 300
	while controller.current_state != StageController.State.RESULT and finish_budget > 0:
		await physics_frame
		finish_budget -= 1
	_assert(controller.current_state == StageController.State.RESULT,
		"completed deal must reach an authoritative result")
	if controller.current_state == StageController.State.RESULT:
		var result := controller.result_snapshot()
		print("PROTOTYPE_WITNESS %s" % JSON.stringify({
			"stage_id": String(stage_id),
			"deal_seed": controller.deal_seed(),
			"cleared": bool(result.get("cleared", false)),
			"paint_score": float(result.get("paint_score", 0.0)),
			"red_percent": float(result.get("red_percent", 0.0)),
			"green_percent": float(result.get("green_percent", 0.0)),
			"target_min": float(result.get("target_min", 0.0)),
			"target_max": float(result.get("target_max", 0.0)),
			"stars": int(result.get("stars", 0)),
			"finish_reason": String(result.get("finish_reason", "")),
			"settled_score_after_each_shot": shot_scores,
		}))
	Engine.time_scale = 1.0
	gameplay.queue_free()
	await process_frame
	_finish()


func _aim_for_shot(
		default_aim: AimTuple,
		witnesses: Array[AimTuple],
		shot_index: int,
		shot_count: int,
		positive_index: int,
		positive_total: int,
		weight: int,
		rule: ColorScoreRuleData
) -> AimTuple:
	if not witnesses.is_empty() and rule.red_weight > 0 and rule.green_weight > 0:
		var witness_index := roundi(
			float(shot_index) * float(witnesses.size() - 1)
			/ float(maxi(shot_count - 1, 1))
		)
		return witnesses[witness_index]
	if weight < 0:
		# Subtractive tokens may be deliberately dropped short of the target;
		# wasting a bad color is part of the authored planning rule.
		return AimTuple.canonicalize(
			default_aim.yaw_degrees,
			AimTuple.MINIMUM_ELEVATION_DEGREES,
			AimTuple.MINIMUM_POWER_PERCENT
		)
	if weight == 0:
		return default_aim
	var progress := float(positive_index) / float(maxi(positive_total - 1, 1))
	var spread := 3.0 if rule.red_weight > 0 and rule.green_weight > 0 else 8.0
	return AimTuple.canonicalize(
		default_aim.yaw_degrees + lerpf(-spread, spread, progress),
		default_aim.elevation_degrees + (3.0 if positive_index % 2 == 1 else 0.0),
		default_aim.power_percent
	)


func _channel_weight(rule: ColorScoreRuleData, channel: int) -> int:
	return rule.red_weight if channel == PaintChannel.Value.RED else rule.green_weight


func _finish() -> void:
	Engine.time_scale = 1.0
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Prototype playable witness failed: %s" % message)
