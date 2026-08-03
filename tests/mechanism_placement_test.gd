extends SceneTree

const STAGES: Array[StageData] = [
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	for stage in STAGES:
		var first := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		var repeated := SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		_assert_true(first != null and repeated != null, "%s must generate with every required mechanism" % stage.stage_id)
		if first == null or repeated == null:
			continue
		_assert_true(first.mechanism_placements.size() == stage.mechanism_loadout.size(), "%s must place the exact loadout" % stage.stage_id)
		for index in range(first.mechanism_placements.size()):
			_assert_placement(stage, first, first.mechanism_placements[index], repeated.mechanism_placements[index])
		_assert_fixed_point_rejection(stage, first)
		print("%s exact placements passed: %s" % [stage.stage_id, _placement_summary(first)])
	quit(1 if _failed else 0)


func _assert_placement(stage: StageData, layout: GeneratedStageLayout, placement: MechanismPlacement, repeated: MechanismPlacement) -> void:
	var expected_role := _role_for_kind(placement.mechanism_data.kind)
	_assert_true(placement.route_role == expected_role, "%s mechanism must map to its route role" % stage.stage_id)
	_assert_true(layout.route_roles[placement.route_index] == expected_role, "%s placement route index must own the role" % stage.stage_id)
	_assert_true(is_equal_approx(placement.shelf_t, layout.route_shelf_positions[placement.route_index]), "%s placement must use the frozen shelf t" % stage.stage_id)
	var route_point := layout.route_position(placement.route_index, placement.shelf_t)
	_assert_true(placement.local_xz.is_equal_approx(Vector2(route_point.x, route_point.z)), "%s placement must stay on the route centerline" % stage.stage_id)
	var surface := Vector3(route_point.x, layout.height_at_local(route_point.x, route_point.z), route_point.z)
	var normal := layout.normal_at_local(route_point.x, route_point.z)
	_assert_true(placement.local_transform.origin.is_equal_approx(surface + normal * 0.05), "%s transform origin must be the sampled surface plus 0.05 m" % stage.stage_id)
	_assert_true(placement.local_transform.basis.y.is_equal_approx(normal), "%s local Y must align to the surface normal" % stage.stage_id)
	var before := layout.route_position(placement.route_index, maxf(0.0, placement.shelf_t - 0.02))
	var after := layout.route_position(placement.route_index, minf(1.0, placement.shelf_t + 0.02))
	var tangent := Vector3(after.x - before.x, 0.0, after.z - before.z).normalized()
	_assert_true(placement.downstream_tangent.is_equal_approx(tangent), "%s downstream tangent must come from t +/- 0.02" % stage.stage_id)
	_assert_true((-placement.local_transform.basis.z).dot(tangent) >= 0.999, "%s local forward must follow the downstream tangent" % stage.stage_id)
	var slope := rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
	_assert_true(slope <= 8.0, "%s exact shelf point must be <= 8 degrees" % stage.stage_id)
	var physical_radius := _physical_radius(placement.mechanism_data.kind)
	_assert_true(layout.route_shelf_radii[placement.route_index] * 0.60 >= physical_radius, "%s flat shelf must contain the physical body" % stage.stage_id)
	_assert_true(layout.route_widths[placement.route_index] * 0.5 - physical_radius >= 3.0, "%s body must keep 3 m route-edge clearance" % stage.stage_id)
	_assert_visibility(stage, layout, placement, normal)
	_assert_true(placement.local_transform.is_equal_approx(repeated.local_transform), "%s exact transform must be deterministic" % stage.stage_id)


func _assert_visibility(stage: StageData, layout: GeneratedStageLayout, placement: MechanismPlacement, normal: Vector3) -> void:
	var diameter := _visual_diameter(placement.mechanism_data.kind)
	var surface := Vector3(placement.local_xz.x, layout.height_at_local(placement.local_xz.x, placement.local_xz.y), placement.local_xz.y)
	var world_top := stage.terrain_center + surface + normal * diameter
	_assert_true(MechanismPlacementGenerator._terrain_ray_clear(stage, layout, stage.aiming_camera_position, world_top), "%s mechanism must be unoccluded in aiming" % stage.stage_id)
	_assert_true(MechanismPlacementGenerator._terrain_ray_clear(stage, layout, stage.briefing_camera_position, world_top), "%s mechanism must be unoccluded in briefing" % stage.stage_id)
	var aiming_pixels := MechanismPlacementGenerator._projected_horizontal_pixels(stage.aiming_camera_position, stage.aiming_camera_target, world_top, diameter)
	var briefing_pixels := MechanismPlacementGenerator._projected_horizontal_pixels(stage.briefing_camera_position, stage.briefing_camera_target, world_top, diameter)
	_assert_true(aiming_pixels >= 18.0, "%s mechanism must project to >= 18 px in aiming" % stage.stage_id)
	_assert_true(briefing_pixels >= 24.0, "%s mechanism must project to >= 24 px in briefing" % stage.stage_id)


func _assert_fixed_point_rejection(stage: StageData, layout: GeneratedStageLayout) -> void:
	if layout.mechanism_placements.is_empty():
		return
	var placement := layout.mechanism_placements[0]
	var original_radii := layout.route_shelf_radii.duplicate()
	layout.route_shelf_radii[placement.route_index] = 0.0
	var rejected := MechanismPlacementGenerator.generate(stage, layout)
	_assert_true(rejected.is_empty(), "%s must reject the whole candidate when its exact shelf point is invalid" % stage.stage_id)
	layout.route_shelf_radii = original_radii


func _role_for_kind(kind: MechanismData.Kind) -> StageRouteProfile.Role:
	if kind == MechanismData.Kind.SPLITTER:
		return StageRouteProfile.Role.SPLITTER
	if kind == MechanismData.Kind.BUMPER:
		return StageRouteProfile.Role.BUMPER
	return StageRouteProfile.Role.PRIMARY


func _physical_radius(kind: MechanismData.Kind) -> float:
	if kind == MechanismData.Kind.BURST:
		return 1.8
	if kind == MechanismData.Kind.SPLITTER:
		return 1.75
	return 1.9


func _visual_diameter(kind: MechanismData.Kind) -> float:
	if kind == MechanismData.Kind.BURST:
		return 4.2
	if kind == MechanismData.Kind.SPLITTER:
		return 5.0
	return 5.2


func _placement_summary(layout: GeneratedStageLayout) -> Array[String]:
	var result: Array[String] = []
	for placement in layout.mechanism_placements:
		result.append("%s role=%s route=%d t=%.2f at=%s" % [
			MechanismData.Kind.keys()[placement.mechanism_data.kind],
			StageRouteProfile.Role.keys()[placement.route_role], placement.route_index,
			placement.shelf_t, placement.local_xz,
		])
	return result


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Mechanism placement check failed: %s" % message)
