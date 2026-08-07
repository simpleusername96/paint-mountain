extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	var stage := catalog.get_stage(&"stage_01")
	var baked := load(catalog.get_layout_path(stage.stage_id)) as BakedStageLayoutData
	var layout := StageLayoutBakeCodec.hydrate(baked, stage)
	_assert(layout != null and layout.is_runtime_ready(), "the active v9 baked layout must hydrate")

	var recorder := ReplayRecorder.new()
	root.add_child(recorder)
	_assert(
		recorder.start_attempt(
			stage,
			layout.terrain_seed,
			layout,
			&"wind-v1-1347223552"
		),
		"recording must bind to the fixed terrain seed and active v9 layout"
	)
	var default_aim := layout.default_aim
	recorder.record_aim(
		default_aim.yaw_degrees,
		default_aim.elevation_degrees,
		default_aim.power_percent
	)
	recorder.record_camera(CameraDirector.InteractionMode.AIM_LOCKED)
	recorder.record_fire(1)
	recorder.record_finish()
	var exported := recorder.export_attempt()
	_assert(int(exported.format_version) == 9, "the current replay schema must be format 9")
	_assert(
		int(exported.terrain_seed) == StageProgressionData.CANONICAL_TERRAIN_SEED \
				and int(exported.play_bounds_checksum) == layout.play_bounds.checksum(),
		"format 9 must store fixed terrain identity and open play bounds"
	)
	for obsolete_key in ["accepted_seed", "candidate_index", "generation_attempt", "containment_checksum"]:
		_assert(not exported.has(obsolete_key), "format 9 must omit obsolete key '%s'" % obsolete_key)

	var json_round_trip := JSON.parse_string(JSON.stringify(exported)) as Dictionary
	var loaded := ReplayRecorder.new()
	root.add_child(loaded)
	_assert(loaded.load_attempt(json_round_trip), "JSON-safe format-9 data must load without repair")
	var loaded_attempt := loaded.export_attempt()
	_assert(
		int(loaded_attempt.format_version) == int(json_round_trip.format_version) \
				and String(loaded_attempt.stage_id) == String(json_round_trip.stage_id) \
				and int(loaded_attempt.terrain_seed) == int(json_round_trip.terrain_seed) \
				and int(loaded_attempt.play_bounds_checksum) \
						== int(json_round_trip.play_bounds_checksum) \
				and Array(loaded_attempt.actions) == Array(json_round_trip.actions),
		"loading must preserve v9 identity and the ordered action stream"
	)

	var legacy := json_round_trip.duplicate(true)
	legacy["format_version"] = 8
	_assert(not loaded.load_attempt(legacy), "format 8 must fail closed after v9 promotion")
	var random_seed := json_round_trip.duplicate(true)
	random_seed["terrain_seed"] = int(json_round_trip.terrain_seed) + 1
	_assert(not loaded.load_attempt(random_seed), "a runtime-rerolled terrain seed must fail closed")
	var missing_bounds := json_round_trip.duplicate(true)
	missing_bounds.erase("play_bounds_checksum")
	_assert(not loaded.load_attempt(missing_bounds), "missing open-play identity must fail closed")

	recorder.queue_free()
	loaded.queue_free()
	await process_frame
	if not _failed:
		print("Replay recorder v9 passed: fixed seed, open bounds, JSON round-trip, and legacy rejection.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Replay recorder v9 check failed: %s" % message)
