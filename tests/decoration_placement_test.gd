extends SceneTree

const STAGES: Array[StageData] = [
	preload("res://resources/stages/first_descent.tres"),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	for stage in STAGES:
		var layout := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		var repeated := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		_assert_true(layout != null and repeated != null, "%s requires a finalized deterministic layout" % stage.stage_id)
		if layout == null or repeated == null:
			continue
		var decorations := layout.decoration_placements
		var expected_count: int = [10, 14, 18][stage.stage_number - 1]
		_assert_true(decorations.size() == expected_count, "%s must place %d decorations, got %d" % [stage.stage_id, expected_count, decorations.size()])
		_assert_true(repeated.decoration_placements.size() == decorations.size(), "%s decoration count must repeat" % stage.stage_id)
		for index in range(decorations.size()):
			var decoration: DecorationPlacement = decorations[index]
			var repeated_decoration: DecorationPlacement = repeated.decoration_placements[index]
			_assert_true(layout.height_at_local(decoration.local_xz.x, decoration.local_xz.y) >= 1.1, "decoration must remain above the skirt")
			_assert_true(layout.normal_at_local(decoration.local_xz.x, decoration.local_xz.y).y >= cos(deg_to_rad(42.0)), "decoration slope must pass")
			_assert_true(decoration.model_id == repeated_decoration.model_id and decoration.local_xz.is_equal_approx(repeated_decoration.local_xz), "%s decorations must be deterministic" % stage.stage_id)
			var nearest := layout.route_graph.nearest_edge(decoration.local_xz)
			_assert_true(nearest.edge is GeneratedRouteEdge, "%s decoration query must resolve through the immutable graph" % stage.stage_id)
			for prior_index in range(index):
				_assert_true(decoration.local_xz.distance_to(decorations[prior_index].local_xz) >= 4.0, "decorations must preserve spacing")
		print("%s decorations=%d accepted=%d attempt=%d" % [stage.stage_id, decorations.size(), layout.accepted_seed, layout.generation_attempt])
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Decoration placement check failed: %s" % message)
