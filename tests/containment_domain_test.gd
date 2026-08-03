extends SceneTree

const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const FIRST_DESCENT := preload("res://resources/stages/first_descent.tres")
const CONTAINMENT_DOMAIN_PROOF := preload("res://src/terrain/containment_domain_proof.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var cannon := CANNON_SCENE.instantiate() as CannonController
	root.add_child(cannon)
	cannon.global_transform = FIRST_DESCENT.cannon_transform
	await process_frame
	var result: Dictionary = CONTAINMENT_DOMAIN_PROOF.evaluate(cannon, ContainmentSpec.new())
	_assert_true(bool(result.get("valid", false)), "continuous aim envelope must fit the physical containment: %s" % str(result))
	_assert_true(int(result.get("exact_lattice_candidate_count", -1)) == 0, "a passing continuous proof must dominate the complete canonical lattice")
	_assert_true(float(result.get("rear_lateral_clearance", -INF)) >= 0.0, "the sphere envelope must fit inside the wall width")
	_assert_true(float(result.get("upper_clearance", -INF)) >= 0.0, "the no-damping apex must stay below the wall top")
	_assert_true(float(result.get("wall_bottom_overlap", -INF)) >= 0.0, "the wall and apron catch volumes must overlap vertically")
	_assert_true(float(result.get("lower_clearance", -INF)) >= 0.0, "the apron must catch a sphere before the lower bound")
	_assert_true(float(result.get("rear_clearance", -INF)) >= 0.0, "the wall must catch a sphere before the rear bound")
	_assert_true(float(result.get("front_clearance", -INF)) >= 0.0, "every muzzle origin must start inside the front bound")
	_assert_true(bool(result.get("all_launches_move_rearward", false)), "the complete yaw/elevation domain must launch away from the front bound")
	_assert_true(bool(result.get("apron_covers_side_and_front_bounds", false)), "the apron must cover the fixed side/front XZ bounds")
	var gravity_setting := "physics/3d/default_gravity_vector"
	var original_gravity_direction = ProjectSettings.get_setting(gravity_setting, Vector3.DOWN)
	ProjectSettings.set_setting(gravity_setting, Vector3.RIGHT)
	var unsupported_gravity: Dictionary = CONTAINMENT_DOMAIN_PROOF.evaluate(
		cannon,
		ContainmentSpec.new()
	)
	ProjectSettings.set_setting(gravity_setting, original_gravity_direction)
	_assert_true(
		not bool(unsupported_gravity.get("valid", true)) \
				and unsupported_gravity.get("rejection", &"") == &"invalid_gravity",
		"the analytic proof must fail closed when project gravity is not world-down"
	)
	if not _failed:
		print(
			"Containment domain proof passed: apex=%.3f rear_abs_x=%.3f clearances(side/top/bottom/rear/front)=%.3f/%.3f/%.3f/%.3f/%.3f exact_candidates=0" % [
				float(result.maximum_apex_y),
				float(result.maximum_rear_abs_x),
				float(result.rear_lateral_clearance),
				float(result.upper_clearance),
				float(result.lower_clearance),
				float(result.rear_clearance),
				float(result.front_clearance),
			]
		)
	cannon.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Containment-domain check failed: %s" % message)
