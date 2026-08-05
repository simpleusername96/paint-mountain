extends SceneTree

var _failed := false


func _initialize() -> void:
	var stage := StageCatalog.get_stage(&"stage_08")
	_assert(stage != null, "stage 08 must exist in the current catalog")
	if stage == null:
		quit(1)
		return
	var layout := SeededStageGenerator._build_attempt(
		stage.stage_id,
		stage.generation_profile,
		stage.terrain_seed,
		stage.terrain_seed,
		0
	)
	_assert(
		layout != null and SeededStageGenerator._validate(stage.generation_profile, layout),
		"stage 08 persisted seed must retain its structural terrain contract"
	)
	if layout != null:
		var placements := MechanismPlacementGenerator.generate(stage, layout)
		var uphill_count := 0
		for placement in placements:
			if placement.mechanism_data.canonical_kind() == MechanismData.Kind.UPHILL_REBOUND \
					and not placement.uphill_tangent.is_zero_approx():
				uphill_count += 1
		_assert(
			placements.size() == stage.mechanism_loadout.size() and uphill_count == 1,
			"stage 08 must materialize one usable Uphill Rebound glyph: %s" % str(layout.metrics)
		)
	if not _failed:
		print("Stage 08 Uphill Rebound glyph contract passed")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
