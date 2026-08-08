extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	_assert_tuple_precision()
	await _assert_human_revision_transaction()
	if not _failed:
		print("aim_precision_revision_test passed: tenth-percent runtime power and human revision admission are deterministic.")
	quit(1 if _failed else 0)


func _assert_tuple_precision() -> void:
	var whole := AimTuple.canonicalize(1.04, 37.96, 68.04)
	_assert(whole != null and whole.stable_key() == &"10:380:68", "whole power keys must remain byte-identical")
	var fractional := AimTuple.canonicalize(1.04, 37.96, 68.05)
	_assert(fractional != null and is_equal_approx(fractional.power_percent, 68.1), "runtime power must snap to 0.1%")
	_assert(fractional != null and fractional.stable_key() == &"10:380:68.1", "fractional power needs a distinct deterministic key")
	_assert(fractional != null and fractional.is_valid(), "canonical fractional power must remain valid")


func _assert_human_revision_transaction() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.select_stage(&"stage_01")
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	_assert(gameplay != null, "revision fixture must load")
	if gameplay == null:
		game_state.persistence_enabled = true
		return
	root.add_child(gameplay)
	await physics_frame
	var controller := gameplay.get_node("StageController") as StageController
	var cannon := gameplay.get_node("Cannon") as CannonController
	if controller == null or cannon == null:
		_assert(false, "revision fixture must expose StageController and CannonController")
		gameplay.queue_free()
		await process_frame
		game_state.persistence_enabled = true
		return
	_assert(controller.begin_aiming(), "revision fixture must enter aiming")
	var committed := Vector3(cannon.yaw_degrees, cannon.elevation_degrees, cannon.power_percent)
	_assert(controller.begin_human_aim_revision(7), "human revision must begin")
	var pending := controller.fire_readiness_snapshot(StageController.ActionOrigin.HUMAN)
	_assert(
		not bool(pending.get("fireable", true)) \
				and bool(pending.get("aim_revision_pending", false)) \
				and pending.get("reason_key", "") == "aim_revision_pending",
		"only an explicit human revision may gate Human Fire"
	)
	var agent_pending := controller.fire_readiness_snapshot(StageController.ActionOrigin.AGENT)
	_assert(bool(agent_pending.get("fireable", false)), "revision pending must not gate agent Fire")
	_assert(not controller.request_fire(StageController.ActionOrigin.HUMAN), "Human Fire must reject a pending revision")
	_assert(controller.begin_human_aim_revision(8), "a newer revision must supersede pending work")
	_assert(not controller.restore_human_aim_revision(7), "a stale revision must not restore the newer transaction")
	_assert(controller.restore_human_aim_revision(8), "same latest revision must restore committed aim")
	_assert(is_equal_approx(cannon.yaw_degrees, committed.x) and is_equal_approx(cannon.power_percent, committed.z), "restore must retain the prior committed aim")
	_assert(controller.begin_human_aim_revision(9), "a later revision must begin after restore")
	_assert(controller.commit_human_aim_revision(9, committed.x + 0.1, committed.y, committed.z + 0.1), "same revision must commit atomically")
	var expected := AimTuple.canonicalize(committed.x + 0.1, committed.y, committed.z + 0.1)
	_assert(
		expected != null and is_equal_approx(cannon.power_percent, expected.power_percent),
		"committed fractional power must reach the cannon (%s vs %s)" % [
			cannon.power_percent,
			expected.power_percent if expected != null else -1.0,
		]
	)
	_assert(bool(controller.fire_readiness_snapshot().get("fireable", false)), "committing must re-enable Human Fire")
	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Aim precision/revision test failed: %s" % message)
