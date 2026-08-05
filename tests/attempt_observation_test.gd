extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var observation := AttemptObservation.new()
	_assert_true(
		observation.configure(&"stage_04", &"wind-v1-4007", 4007, 0),
		"an attempt requires stable stage and wind identities"
	)
	_assert_true(observation.record_aim(12.0, 41.0, 73.0, 0), "aim must record")
	_assert_true(observation.record_fire(1, 0), "Fire must record after aim")
	var wind := WindSnapshot.new(
		1800,
		Vector3(2.0, 0.0, -1.0),
		Vector3(-3.0, 0.0, 2.0),
		0.4,
		0.7,
		30.0,
		0.0,
		&"wind-v1-4007"
	)
	wind.strong_episode_id = 2
	_assert_true(observation.record_wind_transition(wind, 1), "wind transition must record")
	_assert_true(observation.record_projectile_rest(1, 0, 2), "terrain rest must record")
	_assert_true(
		observation.record_projectile_wake(1, 0, &"strong_wind", 2, 3),
		"strong-wind wake must record"
	)
	_assert_true(
		observation.record_terrain_recovery(1, 0, &"surface_clearance", 4),
		"terrain recovery must record"
	)
	_assert_true(
		observation.record_mechanism_activation(1, 0, &"splitter_02", 1, 5),
		"mechanism activation must record"
	)
	_assert_true(
		observation.record_projectile_terminal(
			1, 0, ProjectileSettlementReason.CONSUMED, 6
		),
		"terminal reason must record"
	)
	var shot := _sealed_shot_observation()
	_assert_true(
		observation.record_shot_observation(shot),
		"sealed initial-flight diagnostics must remain attached"
	)
	_assert_true(observation.record_finish(&"manual", 7), "Finish must remain ordered")
	_assert_true(observation.seal(&"manual", 912345, 18.25, 420, 8), "result must seal")
	_assert_true(
		not observation.record_fire(2, 9),
		"a sealed attempt must reject later gameplay events"
	)

	var serialized := observation.to_dictionary()
	var parsed = JSON.parse_string(JSON.stringify(serialized))
	_assert_true(parsed is Dictionary, "attempt observation must be JSON-safe")
	_assert_true(
		AttemptObservation.dictionary_is_valid(parsed),
		"serialized schema 1 must validate"
	)
	var kinds: Array[String] = []
	for index in range(serialized.events.size()):
		var event: Dictionary = serialized.events[index]
		kinds.append(String(event.kind))
		_assert_true(int(event.sequence) == index, "same-tick ordering must use stable sequence")
	_assert_true(
		kinds == [
			"aim",
			"fire",
			"wind_transition",
			"projectile_rest",
			"projectile_wake",
			"terrain_recovery",
			"mechanism_activation",
			"projectile_terminal",
			"finish",
			"result",
		],
		"schema 1 must retain the representative event order"
	)
	_assert_true(
		int(serialized.final_result.paint_mask_checksum) == 912345 \
				and is_equal_approx(float(serialized.final_result.coverage), 18.25) \
				and String(serialized.final_result.reason) == "manual",
		"the sealed result must retain authoritative paint identity and coverage"
	)

	var shot_facts := shot.to_dictionary()
	_assert_true(
		int(shot_facts.invalid_geometry_count) == 1 \
				and not shot_facts.has("penetration_guard_count"),
		"shot diagnostics must use the explicit invalid-geometry terminal reason"
	)

	var out_of_order := AttemptObservation.new()
	out_of_order.configure(&"stage_04", &"wind-v1-4007", 4007, 0)
	_assert_true(out_of_order.record_aim(0.0, 40.0, 70.0, 5), "first event must record")
	_assert_true(
		not out_of_order.record_fire(1, 4),
		"an event with an earlier tick must not be appended after a later event"
	)

	if not _failed:
		print("Attempt observation checks passed: schema, event order, wind/lifecycle facts, and authoritative result.")
	quit(1 if _failed else 0)


func _sealed_shot_observation() -> ShotObservation:
	var shot := ShotObservation.new()
	shot.configure(1, 12.0, 41.0, 73.0, 0.0, 1)
	shot.record_settlement(1, ProjectileSettlementReason.INVALID_GEOMETRY, 6)
	shot.seal(18.25, 6, 912345)
	return shot


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Attempt observation check failed: %s" % message)
