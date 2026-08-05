extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var stage := StageData.new()
	stage.stage_id = &"stage_04"
	stage.stage_version = StageGenerationContract.CONTRACT_VERSION
	stage.stage_number = 4
	var layout := _runtime_ready_layout()
	_assert_true(layout.is_runtime_ready(), "recorder fixture must be runtime-ready")

	var recorder := ReplayRecorder.new()
	root.add_child(recorder)
	_assert_true(
		recorder.start_attempt(stage, 4007, layout),
		"the legacy three-argument start call must resolve wind deterministically"
	)
	recorder.record_aim(12.0, 41.0, 73.0)
	recorder.record_fire(1)
	recorder.record_observation(_sealed_shot_observation())
	recorder.record_finish()
	_assert_true(
		recorder.store_final_result({
			"stage_id": &"stage_04",
			"finish_reason": &"manual",
			"coverage": 18.25,
			"elapsed_ticks": 420,
			"paint_mask_checksum": 912345,
		}),
		"the recorder must store the authoritative result and seal its attempt observation"
	)

	var exported := recorder.export_attempt()
	_assert_true(
		int(exported.format_version) == 8 \
				and String(exported.wind_schedule_identity) == "wind-v1-4007" \
				and int(exported.wind_schedule_seed) == 4007,
		"format 8 must include deterministic wind identity and seed"
	)
	var action_kinds: Array[String] = []
	for action in exported.actions:
		action_kinds.append(String(action.kind))
	_assert_true(
		action_kinds == ["aim", "fire", "finish"],
		"format 8 must retain ordered aim, Fire, and Finish actions"
	)
	_assert_true(
		exported.expected_observations.size() == 1 \
				and exported.attempt_observation.shot_observations.size() == 1,
		"per-shot initial-flight diagnostics must remain available"
	)

	var json_round_trip = JSON.parse_string(JSON.stringify(exported))
	var loaded := ReplayRecorder.new()
	root.add_child(loaded)
	_assert_true(
		json_round_trip is Dictionary and loaded.load_attempt(json_round_trip),
		"a JSON round-tripped format-8 attempt must validate"
	)
	var legacy: Dictionary = exported.duplicate(true)
	legacy.format_version = 7
	_assert_true(not loaded.load_attempt(legacy), "format 7 must be rejected after the wind/Finish schema change")
	var mismatched_order: Dictionary = exported.duplicate(true)
	var first: Dictionary = mismatched_order.actions[0]
	mismatched_order.actions[0] = mismatched_order.actions[1]
	mismatched_order.actions[1] = first
	_assert_true(
		not loaded.load_attempt(mismatched_order),
		"replay action order must agree with the attempt observation"
	)
	recorder.queue_free()
	loaded.queue_free()
	await process_frame
	if not _failed:
		print("Replay recorder checks passed: format 8, wind identity, Finish order, result storage, and v7 rejection.")
	quit(1 if _failed else 0)


func _runtime_ready_layout() -> GeneratedStageLayout:
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	layout.profile_id = &"stage_04_v7"
	layout.terrain_seed = 4000
	layout.accepted_seed = 4000
	layout.checksum = 74004
	layout.generated_default_aim = AimTuple.new(12.0, 41.0, 73)
	var target_mask := PackedByteArray()
	target_mask.resize(
		StageGenerationContract.REQUIRED_MASK_SIZE \
				* StageGenerationContract.REQUIRED_MASK_SIZE
	)
	target_mask.fill(255)
	var checksum := TargetMaskRasterizer.byte_checksum(target_mask)
	_assert_true(layout.install_target_mask(target_mask, checksum), "fixture target mask must install")
	return layout


func _sealed_shot_observation() -> ShotObservation:
	var observation := ShotObservation.new()
	observation.configure(1, 12.0, 41.0, 73.0, 0.0, 1)
	observation.seal(18.25, 6, 912345)
	return observation


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Replay recorder check failed: %s" % message)
