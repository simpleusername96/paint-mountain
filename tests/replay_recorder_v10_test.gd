extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	var stage := catalog.get_stage(&"stage_01")
	var baked := load(catalog.get_layout_path(stage.stage_id)) as BakedStageLayoutData
	var layout := StageLayoutBakeCodec.hydrate(baked, stage)
	_assert(layout != null and layout.is_runtime_ready(), "the active v10 baked layout must hydrate")

	var recorder := ReplayRecorder.new()
	root.add_child(recorder)
	_assert(
		recorder.start_attempt(
			stage, layout.terrain_seed, layout, &"wind-v1-1347223552"
		),
		"recording must bind to the fixed terrain seed and active v10 layout"
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
	_assert(int(exported.format_version) == 10, "the current replay schema must be format 10")
	_assert(
		int(exported.terrain_seed) == StageProgressionData.CANONICAL_TERRAIN_SEED \
				and int(exported.play_bounds_checksum) == layout.play_bounds.checksum() \
				and int(exported.coverage_metric_version) \
						== TargetSurfaceCoverage.METRIC_VERSION \
				and is_equal_approx(
					float(exported.total_target_surface_area),
					layout.total_target_surface_area
				) \
				and int(exported.target_surface_area_checksum) \
						== layout.target_surface_area_checksum,
		"format 10 must store fixed terrain, open bounds, and metric-2 identity"
	)
	for obsolete_key in [
		"accepted_seed", "candidate_index", "generation_attempt", "containment_checksum"
	]:
		_assert(not exported.has(obsolete_key), "format 10 must omit obsolete key '%s'" % obsolete_key)

	var json_round_trip := JSON.parse_string(JSON.stringify(exported)) as Dictionary
	var loaded := ReplayRecorder.new()
	root.add_child(loaded)
	_assert(loaded.load_attempt(json_round_trip), "JSON-safe format-10 data must load without repair")
	var loaded_attempt := loaded.export_attempt()
	_assert(
		int(loaded_attempt.format_version) == int(json_round_trip.format_version) \
				and String(loaded_attempt.stage_id) == String(json_round_trip.stage_id) \
				and int(loaded_attempt.terrain_seed) == int(json_round_trip.terrain_seed) \
				and int(loaded_attempt.coverage_metric_version) \
						== int(json_round_trip.coverage_metric_version) \
				and int(loaded_attempt.target_surface_area_checksum) \
						== int(json_round_trip.target_surface_area_checksum) \
				and Array(loaded_attempt.actions) == Array(json_round_trip.actions),
		"loading must preserve v10 metric identity and ordered actions"
	)

	var legacy := json_round_trip.duplicate(true)
	legacy["format_version"] = 9
	_assert(not loaded.load_attempt(legacy), "format 9 must fail closed after v10 promotion")
	var random_seed := json_round_trip.duplicate(true)
	random_seed["terrain_seed"] = int(json_round_trip.terrain_seed) + 1
	_assert(not loaded.load_attempt(random_seed), "a runtime-rerolled terrain seed must fail closed")
	var missing_metric := json_round_trip.duplicate(true)
	missing_metric.erase("coverage_metric_version")
	_assert(not loaded.load_attempt(missing_metric), "missing coverage metric identity must fail closed")
	var corrupt_total := json_round_trip.duplicate(true)
	corrupt_total["total_target_surface_area"] = float(
		json_round_trip.total_target_surface_area
	) + 1.0
	_assert(not loaded.load_attempt(corrupt_total), "corrupt surface-area total must fail closed")

	recorder.queue_free()
	loaded.queue_free()
	await process_frame
	if not _failed:
		print("Replay recorder v10 passed: fixed terrain, metric-2 identity, round-trip, and legacy rejection.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Replay recorder v10 check failed: %s" % message)
