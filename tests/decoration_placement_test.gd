extends SceneTree

const STAGES: Array[StageData] = [
	preload("res://resources/stages/first_descent.tres"),
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	for stage in STAGES:
		var layout_seed := stage.terrain_seed + 30 * 7919 if stage.stage_number == 3 else stage.terrain_seed
		var layout := SeededStageGenerator.generate(stage.generation_profile, layout_seed)
		_assert_true(layout != null, "%s requires a base layout" % stage.stage_id)
		if layout == null:
			continue
		if not stage.mechanism_loadout.is_empty():
			layout.mechanism_placements = MechanismPlacementGenerator.generate(stage, layout)
		var decorations := SeededStageGenerator._generate_decorations(stage, layout)
		var expected_count: int = [10, 14, 18][stage.stage_number - 1]
		_assert_true(decorations.size() == expected_count, "%s must place %d decorations, got %d" % [stage.stage_id, expected_count, decorations.size()])
		for index in range(decorations.size()):
			var decoration: DecorationPlacement = decorations[index]
			_assert_true(layout.height_at_local(decoration.local_xz.x, decoration.local_xz.y) >= 1.1, "decoration must remain above the skirt")
			_assert_true(layout.normal_at_local(decoration.local_xz.x, decoration.local_xz.y).y >= cos(deg_to_rad(42.0)), "decoration slope must pass")
			for prior_index in range(index):
				_assert_true(decoration.local_xz.distance_to(decorations[prior_index].local_xz) >= 4.0, "decorations must preserve spacing")
		print("%s decorations: %s" % [stage.stage_id, decorations.map(func(item: DecorationPlacement) -> String: return "%s@%s" % [item.model_id, item.local_xz])])
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Decoration placement check failed: %s" % message)
