extends SceneTree

var _failed := false


func _initialize() -> void:
	var stage := StageCatalog.get_stage(&"stage_02")
	_assert(stage != null, "stage 02 must exist in the current catalog")
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
		"stage 02 persisted seed must retain its structural terrain contract"
	)
	if layout != null:
		var placements := MechanismPlacementGenerator.generate(stage, layout)
		_assert(
			placements.size() == 1
					and placements[0].mechanism_data.canonical_kind() == MechanismData.Kind.BURST,
			"stage 02 must materialize one usable Burst glyph: %s" % str(layout.metrics)
		)
	if not _failed:
		print("Stage 02 Burst glyph contract passed")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
