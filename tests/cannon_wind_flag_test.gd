extends SceneTree

const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cannon := CANNON_SCENE.instantiate() as CannonController
	var wind := WindController.new()
	var flag := CannonWindFlag.new()
	root.add_child(cannon)
	root.add_child(wind)
	root.add_child(flag)
	await process_frame

	var weak := _snapshot(Vector3.RIGHT * 2.0, 0.20)
	wind._snapshot = weak
	flag.configure(cannon, wind)
	flag._physics_process(1.0 / 60.0)
	var streamer := flag.get_node_or_null("WindStreamer") as MeshInstance3D
	_assert(streamer != null, "the cannon-side cue must expose one reusable streamer")
	_assert(
		flag.displayed_direction().is_equal_approx(weak.push_direction()),
		"weak crosswind direction must come from the authoritative snapshot"
	)
	_assert(is_equal_approx(flag.displayed_strength(), 0.20), "weak strength must remain unchanged")
	_assert(
		_horizontal(streamer.position).dot(weak.push_direction()) > 0.999,
		"the streamer's free end must extend in projectile push direction"
	)
	var weak_length := streamer.scale.x
	var mesh_id: int = streamer.mesh.get_instance_id()
	var material_id: int = streamer.mesh.material.get_instance_id()

	var strong := _snapshot(Vector3.LEFT * 8.0, 0.90)
	wind._snapshot = strong
	flag._physics_process(1.0 / 60.0)
	_assert(
		flag.displayed_direction().is_equal_approx(strong.push_direction()),
		"strong crosswind must reverse the same physical flag"
	)
	_assert(is_equal_approx(flag.displayed_strength(), 0.90), "strong strength must remain unchanged")
	_assert(
		_horizontal(streamer.position).dot(strong.push_direction()) > 0.999 \
				and streamer.scale.x > weak_length,
		"strong wind must lengthen the streamer without changing its meaning"
	)
	_assert(
		streamer.mesh.get_instance_id() == mesh_id \
				and streamer.mesh.material.get_instance_id() == material_id,
		"wind changes must reuse the existing mesh and material"
	)

	flag._on_settings_changed({"reduced_motion": true})
	wind._snapshot = weak
	flag._visual_time = 0.37
	flag._physics_process(1.0 / 60.0)
	_assert(
		streamer.rotation.length_squared() < 0.000001,
		"reduced motion must remove flutter while retaining the +X direction"
	)

	cannon.queue_free()
	wind.queue_free()
	flag.queue_free()
	await process_frame
	if not _failed:
		print("Cannon wind flag passed: weak/strong crosswinds, push direction, reduced motion, and resource reuse.")
	quit(1 if _failed else 0)


func _snapshot(acceleration: Vector3, strength: float) -> WindSnapshot:
	return WindSnapshot.new(
		0,
		acceleration,
		acceleration,
		strength,
		strength,
		30.0,
		0.0,
		&"wind-v1-1347223552"
	)


func _horizontal(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z).normalized()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Cannon wind flag check failed: %s" % message)
