extends SceneTree

## Consolidated version-7 progression gate. The default mode is cheap and
## checks the serialized catalog; --full-generation additionally rebuilds all
## thirty accepted layouts headlessly for the longer offline acceptance pass.

func _initialize() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	_assert(catalog != null and catalog.is_valid(), "serialized version-7 catalog must be valid")
	_assert(catalog.stage_ids.size() == StageProgressionData.STAGE_COUNT, "catalog must expose thirty numeric stage IDs")
	_assert(catalog.get_stage(&"first_descent").stage_id == &"stage_01", "legacy first_descent must map to stage_01")
	_assert(catalog.get_stage(&"burst_basin").stage_id == &"stage_02", "legacy burst_basin must map to stage_02")
	_assert(catalog.get_stage(&"split_ridge").stage_id == &"stage_03", "legacy split_ridge must map to stage_03")
	_assert(StageProgressionData.target_for(1) == 4.0 and StageProgressionData.target_for(30) == 15.0, "target endpoints must match the locked ladder")
	_assert(StageProgressionData.shots_for(1) == 4 and StageProgressionData.shots_for(30) == 7, "shot endpoints must match the locked ladder")
	_assert(StageProgressionData.terrain_size_for(1) == Vector2(180.0, 120.0), "stage 01 terrain endpoint must match")
	_assert(StageProgressionData.terrain_size_for(30) == Vector2(240.0, 160.0), "stage 30 terrain endpoint must match")
	_assert(StageProgressionData.cell_count_for(1) == Vector2i(72, 48), "stage 01 cell endpoint must match")
	_assert(StageProgressionData.cell_count_for(30) == Vector2i(96, 64), "stage 30 cell endpoint must match")
	_assert(is_equal_approx(StageProgressionData.difficulty_score_for(4), 5.15), "stage 04 canary difficulty must be 5.15")
	_assert(is_equal_approx(StageProgressionData.difficulty_score_for(5), 6.00), "stage 05 canary difficulty must be 6.00")

	var previous_score := -INF
	var profile_ids: Dictionary = {}
	var seeds: Dictionary = {}
	for index in range(catalog.stages.size()):
		var stage := catalog.stages[index]
		var expected_number := index + 1
		_assert(stage.stage_id == StringName("stage_%02d" % expected_number), "stage IDs must be numeric and ordered")
		_assert(stage.stage_number == expected_number, "stage numbers must be contiguous")
		_assert(stage.terrain_seed == StageProgressionData.requested_seed_for(expected_number), "accepted seed must be persisted from the locked candidate map")
		_assert(stage.generation_profile.ridge_count == StageProgressionData.ridge_count_for(expected_number), "ridge count must consume the progression formula")
		_assert(stage.generation_profile.basin_count == StageProgressionData.basin_count_for(expected_number), "basin count must consume the progression formula")
		_assert(stage.generation_profile.pass_count == StageProgressionData.pass_count_for(expected_number), "pass count must consume the progression formula")
		_assert(is_equal_approx(stage.generation_profile.undulation_amplitude, StageProgressionData.undulation_for(expected_number)), "undulation must consume the progression formula")
		_assert(is_equal_approx(stage.generation_profile.route_width, StageProgressionData.route_width_for(expected_number)), "route width must consume the progression formula")
		_assert(stage.generation_profile.routes.size() == StageProgressionData.route_count_for(expected_number), "route count must consume the progression formula")
		_assert(stage.mechanism_loadout.size() == StageProgressionData.mechanism_count_for(expected_number), "mechanism count must consume the progression formula")
		var score := StageProgressionData.difficulty_score_for(expected_number)
		if index > 0:
			_assert(score - previous_score >= 0.35 and score - previous_score <= 5.0, "adjacent difficulty score must change gradually")
		previous_score = score
		_assert(not profile_ids.has(stage.generation_profile.profile_id), "profile IDs must be unique")
		_assert(not seeds.has(stage.terrain_seed), "accepted seeds must be unique")
		profile_ids[stage.generation_profile.profile_id] = true
		seeds[stage.terrain_seed] = true
	_assert(catalog.stages[3].terrain_size == Vector2(186.0, 124.0), "stage 04 canary dimensions must match")
	_assert(catalog.stages[3].generation_profile.generation_contract.cell_count == Vector2i(74, 50), "stage 04 canary cells must match")
	_assert(catalog.stages[4].generation_profile.generation_contract.cell_count == Vector2i(76, 50), "stage 05 canary cells must match")
	_assert(catalog.stages[3].generation_profile.nominal_peak == 77.5, "stage 04 canary peak must match")
	_assert(catalog.stages[4].generation_profile.nominal_peak == 79.5, "stage 05 canary peak must match")
	_assert(is_equal_approx(catalog.stages[3].generation_profile.undulation_amplitude, 2.6), "stage 04 canary undulation must match")
	_assert(is_equal_approx(catalog.stages[4].generation_profile.undulation_amplitude, 2.8), "stage 05 canary undulation must match")

	if "--full-generation" in OS.get_cmdline_user_args():
		var checksums: Dictionary = {}
		var previous_layout: GeneratedStageLayout
		var previous_stage: StageData
		var generation_stages: Array[StageData] = catalog.stages
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--generation-stage="):
				var requested_number := clampi(
					argument.trim_prefix("--generation-stage=").to_int(),
					1,
					StageProgressionData.STAGE_COUNT
				)
				generation_stages = [catalog.get_stage(StringName("stage_%02d" % requested_number))]
				break
		for stage in generation_stages:
			var layout := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
			_assert(layout != null and layout.is_valid() and layout.has_valid_target_mask(), "stage %s must rebuild from its persisted seed" % stage.stage_id)
			if layout != null:
				_assert(layout.summit_triangle_ids().size() > 0 and layout.summit_region_checksum() != 0, "stage %s must expose a stable non-empty summit region" % stage.stage_id)
				_assert(layout.containment != null and layout.containment.is_valid(), "stage %s must retain a closed containment domain" % stage.stage_id)
				_assert(layout.route_graph.pad_nodes().size() == stage.mechanism_loadout.size(), "stage %s mechanism pads must match the persisted loadout" % stage.stage_id)
				_assert(int(layout.metrics.get("ridge_count", -1)) == stage.generation_profile.ridge_count, "stage %s ridge metrics must consume the profile" % stage.stage_id)
				_assert(int(layout.metrics.get("basin_count", -1)) == stage.generation_profile.basin_count, "stage %s basin metrics must consume the profile" % stage.stage_id)
				_assert(int(layout.metrics.get("pass_count", -1)) == stage.generation_profile.pass_count, "stage %s pass metrics must consume the profile" % stage.stage_id)
				_assert(float(layout.metrics.get("maximum_route_slope", INF)) <= stage.generation_profile.route_core_p95_slope_max * 1.5, "stage %s generated route slope must stay bounded" % stage.stage_id)
			if previous_layout != null and layout != null:
				var rms := _normalized_height_rms(previous_layout, layout)
				_assert(rms >= 1.0 and rms <= 18.0, "adjacent normalized height RMS must stay in the 1..18 m gate; got %.3f between %s and %s" % [rms, previous_stage.stage_id, stage.stage_id])
			_assert(absf(stage.terrain_size.x - (previous_stage.terrain_size.x if previous_stage != null else stage.terrain_size.x)) <= 4.0, "adjacent terrain X delta must be bounded")
			if previous_stage != null:
				_assert(absf(stage.terrain_size.y - previous_stage.terrain_size.y) <= 4.0, "adjacent terrain Z delta must be bounded")
			_assert(layout.route_graph.route_count() == StageProgressionData.route_count_for(stage.stage_number), "generated route count must match the profile formula")
			_assert(layout.decoration_placements.size() == 10 + roundi(22.0 * StageProgressionData.normalized_t(stage.stage_number)), "generated decoration count must match the progression formula")
			_assert(not checksums.has(layout.checksum), "accepted height checksums must be unique")
			checksums[layout.checksum] = true
			previous_layout = layout
			previous_stage = stage

	if not _failed:
		print("stage30_progression_test passed: serialized catalog, endpoints, canaries, and adjacent score gates")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _normalized_height_rms(first: GeneratedStageLayout, second: GeneratedStageLayout) -> float:
	var sum_squared := 0.0
	var sample_count := 64 * 48
	for z_index in range(48):
		var normalized_z := float(z_index) / 47.0
		for x_index in range(64):
			var normalized_x := float(x_index) / 63.0
			var first_point := first.local_bounds.position + Vector2(normalized_x, normalized_z) * first.local_bounds.size
			var second_point := second.local_bounds.position + Vector2(normalized_x, normalized_z) * second.local_bounds.size
			var delta := first.height_at_local(first_point.x, first_point.y) - second.height_at_local(second_point.x, second_point.y)
			sum_squared += delta * delta
	return sqrt(sum_squared / float(sample_count))
var _failed := false
