extends SceneTree

var _failed := false


func _initialize() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	_assert(catalog != null and catalog.is_valid(), "v13 catalog must load")
	if catalog == null:
		quit(1)
		return

	var controller := StageController.new()
	controller.stage_data = catalog.get_stage(&"stage_12")
	var red_only := controller._goal_requirements_snapshot(
		PaintCoverageSnapshot.new(2.0, 0.0, 2.0)
	)
	_assert(not bool(red_only.get("goal_requirements_met", true)),
		"red-only target paint must not clear Stage 12")
	_assert(Array(red_only.get("missing_color_ids", [])).has("green"),
		"Stage 12 must report the missing green channel")

	_add_observation(controller, 1, BallKind.Value.IMPACT_BURST, false)
	var outside_target := controller._goal_requirements_snapshot(
		PaintCoverageSnapshot.new(2.0, 2.0, 4.0)
	)
	_assert(Array(outside_target.get("missing_ball_kind_ids", [])).has("impact_burst"),
		"a special ball that paints outside the target must not satisfy the goal")

	_add_observation(controller, 2, BallKind.Value.IMPACT_BURST, true)
	var burst_only := controller._goal_requirements_snapshot(
		PaintCoverageSnapshot.new(2.0, 2.0, 4.0)
	)
	_assert(Array(burst_only.get("missing_ball_kind_ids", [])).has("apex_split"),
		"Stage 12 must still require Apex Split target paint")

	_add_observation(controller, 3, BallKind.Value.APEX_SPLIT, true)
	var complete := controller._goal_requirements_snapshot(
		PaintCoverageSnapshot.new(2.0, 2.0, 4.0)
	)
	_assert(bool(complete.get("goal_requirements_met", false)),
		"both colors and both authored special balls must satisfy Stage 12")

	controller.stage_data = catalog.get_stage(&"stage_06")
	var introduction := controller._goal_requirements_snapshot(PaintCoverageSnapshot.new())
	_assert(bool(introduction.get("goal_requirements_met", false)),
		"introductory stages must keep their existing clear contract")
	controller.free()
	if not _failed:
		print("late_stage_clear_requirements_test passed: target colors and special-ball participation are authoritative")
	quit(1 if _failed else 0)


func _add_observation(
	controller: StageController,
	shot_id: int,
	kind: int,
	changed_target: bool
) -> void:
	var observation := ShotObservation.new()
	observation.shot_id = shot_id
	observation.ball_kind = kind
	observation.paint_command_count = 1
	observation.score_before = {"red_percent": 1.0, "green_percent": 1.0}
	observation.score_after = {
		"red_percent": 1.25 if changed_target else 1.0,
		"green_percent": 1.0,
	}
	observation.is_sealed = true
	controller._shot_observations[shot_id] = observation


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Late-stage clear requirements failed: %s" % message)
