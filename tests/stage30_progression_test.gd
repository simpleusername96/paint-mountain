extends SceneTree

func _initialize() -> void:
	var stages := StageCatalog.all_stages()
	_assert(stages.size() == 30, "catalog must expose thirty stages")
	_assert(StageCatalog.get_stage(&"stage_01").stage_id == &"first_descent", "stage_01 alias must remain compatible")
	_assert(StageCatalog.get_stage(&"stage_30").maximum_shots == 7, "stage 30 must use the final payload band")
	var previous_peak := 0.0
	var probe_indices := range(stages.size())
	for probe_index in probe_indices:
		var stage := stages[probe_index]
		_assert(stage != null and stage.generation_profile != null, "stage resource must be complete")
		_assert(stage.target_coverage > 0.0 and stage.maximum_shots >= 4, "stage rules must be positive")
		var layout := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		_assert(layout != null and layout.is_valid() and layout.has_valid_target_mask(), "stage %s must generate a valid closed layout" % stage.stage_number)
		if layout != null:
			var peak := float(layout.metrics.get("maximum_height", 0.0))
			_assert(peak >= previous_peak - 8.0, "stage geometry must progress without collapsing")
			previous_peak = peak
	print("stage30_progression_test passed: %d catalog IDs, %d generated probes" % [stages.size(), probe_indices.size()])
	quit()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
