extends SceneTree

const WIND_PROFILE: WindProfile = preload("res://resources/wind/standard_wind.tres")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world_host := Node3D.new()
	root.add_child(world_host)
	await physics_frame
	var space_state := world_host.get_world_3d().direct_space_state
	var bounds := AABB(Vector3(-5000.0, -5000.0, -5000.0), Vector3.ONE * 10000.0)
	var origin := Vector3(0.0, 100.0, 0.0)
	var velocity := Vector3(0.0, 40.0, -80.0)
	var calm := TrajectoryPredictor.predict_motion(
		space_state, origin, velocity, 1.2, 0.55, bounds, 0, true
	)
	var windy := TrajectoryPredictor.predict_motion(
		space_state, origin, velocity, 1.2, 0.55, bounds, 0, true,
		WIND_PROFILE, 8421, 0
	)
	var retry := TrajectoryPredictor.predict_motion(
		space_state, origin, velocity, 1.2, 0.55, bounds, 0, true,
		WIND_PROFILE, 8421, 0
	)
	_assert(
		windy.endpoint.distance_to(calm.endpoint) > 5.0,
		"the authoritative wind schedule must materially affect the predicted path"
	)
	_assert(
		windy.endpoint.is_equal_approx(retry.endpoint),
		"the same wind seed and intended launch tick must reproduce the prediction"
	)
	world_host.queue_free()
	await process_frame
	if not _failed:
		print("Wind prediction checks passed: schedule-driven displacement and deterministic retry.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Wind prediction check failed: %s" % message)
