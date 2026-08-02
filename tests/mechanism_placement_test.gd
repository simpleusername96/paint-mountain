extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	for stage_id in [&"burst_basin", &"split_ridge"]:
		var stage := StageCatalog.get_stage(stage_id)
		var first := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		var repeated := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		_assert_true(first != null, "%s must generate with all required placements" % stage_id)
		_assert_true(repeated != null, "%s repeated placement generation must succeed" % stage_id)
		if first == null or repeated == null:
			continue
		_assert_true(first.mechanism_placements.size() == stage.mechanism_loadout.size(), "%s must resolve its exact mechanism loadout" % stage_id)
		_assert_true(repeated.mechanism_placements.size() == first.mechanism_placements.size(), "%s must reproduce placement count" % stage_id)
		for index in range(first.mechanism_placements.size()):
			var placement := first.mechanism_placements[index]
			var repeated_placement := repeated.mechanism_placements[index]
			_assert_true(placement.mechanism_data.kind == stage.mechanism_loadout[index].kind, "%s placement order must preserve loadout kind" % stage_id)
			_assert_true(placement.local_xz.is_equal_approx(repeated_placement.local_xz), "%s placement coordinates must be deterministic" % stage_id)
			_assert_true(is_equal_approx(placement.yaw_degrees, repeated_placement.yaw_degrees), "%s placement orientation must be deterministic" % stage_id)
			var slope := rad_to_deg(acos(clampf(first.normal_at_local(placement.local_xz.x, placement.local_xz.y).y, -1.0, 1.0)))
			_assert_true(slope <= 18.0, "%s mechanism base slope must stay within 18 degrees" % stage_id)
			_assert_true(_projected_size_passes(stage, first, placement), "%s mechanism must meet both projected-size thresholds" % stage_id)
		for first_index in range(first.mechanism_placements.size()):
			for second_index in range(first_index + 1, first.mechanism_placements.size()):
				_assert_true(
					first.mechanism_placements[first_index].local_xz.distance_to(first.mechanism_placements[second_index].local_xz) >= 10.0,
					"%s mechanisms must keep ten metres of center separation" % stage_id
				)
		if stage_id == &"split_ridge":
			var bumper: MechanismPlacement = first.mechanism_placements[1]
			var route_direction := Vector2(-sin(deg_to_rad(bumper.yaw_degrees)), -cos(deg_to_rad(bumper.yaw_degrees)))
			var start_height := first.height_at_local(bumper.local_xz.x, bumper.local_xz.y)
			var end_height := start_height
			for distance in [0.0, 5.0, 10.0, 15.0, 20.0]:
				var point: Vector2 = bumper.local_xz + route_direction * float(distance)
				end_height = first.height_at_local(point.x, point.y)
			_assert_true(end_height <= start_height - 10.0, "split_ridge Bumper must face a materially descending section of its own route")
		print("%s placements: seed=%d attempt=%d %s" % [stage_id, first.accepted_seed, first.generation_attempt, _placement_summary(first)])
	quit(1 if _failed else 0)


func _projected_size_passes(stage: StageData, layout: GeneratedStageLayout, placement: MechanismPlacement) -> bool:
	var diameter := 4.2
	if placement.mechanism_data.kind == MechanismData.Kind.SPLITTER:
		diameter = 4.5
	elif placement.mechanism_data.kind == MechanismData.Kind.BUMPER:
		diameter = 3.8
	var local_position := Vector3(placement.local_xz.x, layout.height_at_local(placement.local_xz.x, placement.local_xz.y) + diameter * 0.5, placement.local_xz.y)
	var world_position := stage.terrain_center + local_position
	var forward := (stage.aiming_camera_target - stage.aiming_camera_position).normalized()
	var depth := maxf((world_position - stage.aiming_camera_position).dot(forward), 0.01)
	var projected_1080 := diameter / (2.0 * tan(deg_to_rad(25.0)) * depth) * 1080.0
	var projected_720 := diameter / (2.0 * tan(deg_to_rad(25.0)) * depth) * 720.0
	return projected_1080 >= 32.0 and projected_720 >= 22.0


func _placement_summary(layout: GeneratedStageLayout) -> Array[String]:
	var result: Array[String] = []
	for placement in layout.mechanism_placements:
		result.append("%s@%s yaw=%.1f" % [MechanismData.Kind.keys()[placement.mechanism_data.kind], placement.local_xz, placement.yaw_degrees])
	return result


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Mechanism placement check failed: %s" % message)
