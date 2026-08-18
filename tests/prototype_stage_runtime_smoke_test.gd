extends SceneTree

const FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")
const STAGES: Array[StringName] = [
	&"stage_01", &"stage_02", &"stage_03",
	&"stage_04", &"stage_05", &"stage_06",
]

var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for stage_id in STAGES:
		var gameplay := FIXTURE.instantiate(stage_id)
		_assert(gameplay != null, "stage must instantiate: %s" % stage_id)
		if gameplay == null:
			continue
		root.add_child(gameplay)
		await physics_frame
		await physics_frame
		var controller := gameplay.get_node("StageController") as StageController
		var initial_deal := controller.attempt_deal_snapshot()
		_assert(controller.stage_data.uses_target_band(),
			"prototype stage must use target-band scoring: %s" % stage_id)
		_assert(initial_deal.size() == controller.stage_data.maximum_shots,
			"runtime deal must match the authored shot count: %s" % stage_id)
		_assert(controller.visible_queue_snapshot().size() == mini(3, initial_deal.size()),
			"runtime must publish only the current-plus-two horizon: %s" % stage_id)
		_assert(controller.begin_aiming(), "stage must enter aiming: %s" % stage_id)
		_assert(controller.current_state == StageController.State.AIMING,
			"stage must remain in aiming: %s" % stage_id)
		_assert(controller.request_fire(), "stage must admit its first dealt root: %s" % stage_id)
		_assert(controller.queue_cursor() == 1,
			"accepted root must consume exactly one token: %s" % stage_id)
		var shot := controller.current_shot_observation()
		_assert(shot != null and int(initial_deal[0].get("kind", -1)) == shot.ball_kind,
			"shot must inherit the admitted token kind: %s" % stage_id)
		_assert(shot != null and int(initial_deal[0].get("channel", -1)) == shot.paint_channel,
			"shot must inherit the admitted token channel: %s" % stage_id)
		gameplay.queue_free()
		await process_frame
	if not _failed:
		print("Prototype runtime smoke passed: stages 01-06 instantiate, publish a bounded queue, and admit one typed root.")
	quit(1 if _failed else 0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Prototype runtime smoke failed: %s" % message)
