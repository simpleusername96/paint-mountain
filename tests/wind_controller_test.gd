extends SceneTree

const STANDARD_WIND: WindProfile = preload("res://resources/wind/standard_wind.tres")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	_assert_true(STANDARD_WIND.is_valid(), "standard wind profile must be valid")
	var controller := WindController.new()
	root.add_child(controller)
	_assert_true(controller.configure(STANDARD_WIND, 8421), "wind controller must accept the standard profile")
	var first := controller.current_snapshot()
	var retry := WindController.sample_for_tick(STANDARD_WIND, 8421, first.physics_tick)
	_assert_true(
		first != null and retry != null and first.acceleration.is_equal_approx(retry.acceleration),
		"the same stage seed and tick must reproduce the same wind"
	)
	var before_change := WindController.sample_for_tick(STANDARD_WIND, 8421, 28 * 60)
	var after_change := WindController.sample_for_tick(STANDARD_WIND, 8421, 31 * 60)
	_assert_true(
		before_change.is_transitioning() and not before_change.next_acceleration.is_equal_approx(first.acceleration),
		"the end of a wind interval must visibly transition toward the next target"
	)
	_assert_true(
		not after_change.acceleration.is_equal_approx(first.acceleration),
		"a completed interval must use the next deterministic wind target"
	)
	controller.start()
	controller._physics_process(1.0 / 60.0)
	var running_tick := controller.elapsed_ticks()
	controller.stop()
	controller._physics_process(1.0 / 60.0)
	_assert_true(
		controller.elapsed_ticks() == running_tick,
		"a stopped or paused run must not advance the wind schedule"
	)
	controller.queue_free()
	await process_frame
	if not _failed:
		print("Wind controller checks passed: seeded schedule, natural transition, change, and pause.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Wind controller check failed: %s" % message)
