extends SceneTree

const DEFERRED_STAGES: Array[StageData] = [
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]
const BURST_DATA: MechanismData = preload("res://resources/mechanisms/burst_node.tres")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	_assert_deferred_profiles_resolve_typed_pads()
	var fixture := _synthetic_burst_fixture()
	var stage := fixture.stage as StageData
	var first := fixture.layout as GeneratedStageLayout
	var repeated := _synthetic_burst_fixture().layout as GeneratedStageLayout
	first.mechanism_placements = MechanismPlacementGenerator.generate(stage, first)
	repeated.mechanism_placements = MechanismPlacementGenerator.generate(stage, repeated)
	_assert_true(first.mechanism_placements.size() == 1 and repeated.mechanism_placements.size() == 1, "synthetic typed pad must place Burst deterministically")
	if first.mechanism_placements.size() == 1 and repeated.mechanism_placements.size() == 1:
		_assert_placement(stage, first, first.mechanism_placements[0], repeated.mechanism_placements[0])
		_assert_graph_immutability(stage, first)
		_assert_invalid_pad_rejected(stage, first)
		print("Task 1.1 graph-owned mechanism placement passed: %s" % _placement_summary(first))
	quit(1 if _failed else 0)


func _assert_deferred_profiles_resolve_typed_pads() -> void:
	for stage in DEFERRED_STAGES:
		var graph := RouteGraphResolver.resolve(stage.stage_id, stage.generation_profile, stage.terrain_seed)
		_assert_true(graph != null and graph.is_valid(), "%s v4 graph input must resolve before Phase 2 acceptance" % stage.stage_id)
		if graph == null:
			continue
		for mechanism in stage.mechanism_loadout:
			var pad := graph.pad_node_for_kind(mechanism.kind)
			_assert_true(pad != null and pad.mechanism_kind == mechanism.kind, "%s mechanism must resolve to its typed immutable pad" % stage.stage_id)


func _synthetic_burst_fixture() -> Dictionary:
	var stage := StageData.new()
	stage.stage_id = &"mechanism_graph_fixture"
	stage.stage_version = 4
	stage.terrain_center = Vector3.ZERO
	stage.mechanism_loadout = [BURST_DATA]
	stage.aiming_camera_position = Vector3(0.0, 8.0, 12.0)
	stage.aiming_camera_target = Vector3(0.0, 1.0, 0.0)
	stage.briefing_camera_position = Vector3(10.0, 10.0, 12.0)
	stage.briefing_camera_target = Vector3(0.0, 1.0, 0.0)
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	layout.profile_id = &"mechanism_graph_fixture_v4"
	var summit_id := GeneratedRouteNode.summit_id(stage.stage_id)
	var pad_id := GeneratedRouteNode.pad_id(stage.stage_id, 0, 0, MechanismData.Kind.BURST)
	var exit_id := GeneratedRouteNode.route_node_id(stage.stage_id, 0, 2)
	var summit := GeneratedRouteNode.new(
		summit_id, Vector3(0.0, 0.0, -10.0), -1, 0, GeneratedRouteNode.Kind.SUMMIT
	)
	var pad := GeneratedRouteNode.new(
		pad_id, Vector3.ZERO, 0, 1, GeneratedRouteNode.Kind.PAD, MechanismData.Kind.BURST, 8.0
	)
	var exit := GeneratedRouteNode.new(
		exit_id, Vector3(0.0, 0.0, 10.0), 0, 2, GeneratedRouteNode.Kind.EXIT
	)
	var first_edge := GeneratedRouteEdge.new(
		GeneratedRouteEdge.stable_id(stage.stage_id, 0, 0, &"a"),
		summit_id, pad_id, 0, 0, StageRouteProfile.Role.PRIMARY, 10.0
	)
	var second_edge := GeneratedRouteEdge.new(
		GeneratedRouteEdge.stable_id(stage.stage_id, 0, 0, &"b"),
		pad_id, exit_id, 0, 1, StageRouteProfile.Role.PRIMARY, 10.0
	)
	layout.route_graph = GeneratedRouteGraph.new([summit, pad, exit], [first_edge, second_edge])
	return {"stage": stage, "layout": layout}


func _assert_placement(stage: StageData, layout: GeneratedStageLayout, placement: MechanismPlacement, repeated: MechanismPlacement) -> void:
	var expected_role := _role_for_kind(placement.mechanism_data.kind)
	_assert_true(placement.route_role == expected_role, "%s mechanism must map to its route role" % stage.stage_id)
	_assert_true(layout.route_graph.route_role(placement.route_index) == expected_role, "%s placement route index must own the role" % stage.stage_id)
	var pad := layout.route_graph.pad_node_for_kind(placement.mechanism_data.kind)
	_assert_true(pad != null and pad.route_index == placement.route_index, "%s placement must come from its typed pad node" % stage.stage_id)
	_assert_true(is_equal_approx(placement.route_t, layout.route_graph.route_normalized_t_for_node(placement.route_index, pad.id)), "%s placement must use the resolved pad arc position" % stage.stage_id)
	var route_point := pad.position
	_assert_true(placement.local_xz.is_equal_approx(Vector2(route_point.x, route_point.z)), "%s placement must stay on the route centerline" % stage.stage_id)
	var surface := Vector3(route_point.x, layout.height_at_local(route_point.x, route_point.z), route_point.z)
	var normal := layout.normal_at_local(route_point.x, route_point.z)
	_assert_true(placement.local_transform.origin.is_equal_approx(surface + normal * 0.05), "%s transform origin must be the sampled surface plus 0.05 m" % stage.stage_id)
	_assert_true(placement.local_transform.basis.y.is_equal_approx(normal), "%s local Y must align to the surface normal" % stage.stage_id)
	var tangent := layout.route_graph.route_tangent(placement.route_index, placement.route_t)
	_assert_true(placement.downstream_tangent.is_equal_approx(tangent), "%s downstream tangent must come from t +/- 0.02" % stage.stage_id)
	_assert_true((-placement.local_transform.basis.z).dot(tangent) >= 0.999, "%s local forward must follow the downstream tangent" % stage.stage_id)
	var slope := rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
	_assert_true(slope <= 8.0, "%s exact shelf point must be <= 8 degrees" % stage.stage_id)
	var physical_radius := _physical_radius(placement.mechanism_data.kind)
	_assert_true(pad.pad_radius * 0.60 >= physical_radius, "%s flat pad must contain the physical body" % stage.stage_id)
	_assert_true(layout.route_graph.route_width(placement.route_index) * 0.5 - physical_radius >= 3.0, "%s body must keep 3 m route-edge clearance" % stage.stage_id)
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


func _assert_graph_immutability(stage: StageData, layout: GeneratedStageLayout) -> void:
	if layout.mechanism_placements.is_empty():
		return
	var exposed_nodes := layout.route_graph.nodes
	exposed_nodes.clear()
	_assert_true(layout.route_graph.is_valid() and not layout.route_graph.nodes.is_empty(), "%s graph access must not permit mutation of the production owner" % stage.stage_id)


func _assert_invalid_pad_rejected(stage: StageData, layout: GeneratedStageLayout) -> void:
	var mechanism := stage.mechanism_loadout[0]
	var source_pad := layout.route_graph.pad_node_for_kind(mechanism.kind)
	var invalid_nodes: Array[GeneratedRouteNode] = []
	for node in layout.route_graph.nodes:
		if node.id == source_pad.id:
			invalid_nodes.append(GeneratedRouteNode.new(
				node.id,
				node.position,
				node.route_index,
				node.station_index,
				node.kind,
				node.mechanism_kind,
				0.5
			))
		else:
			invalid_nodes.append(node)
	var invalid_layout := GeneratedStageLayout.new()
	invalid_layout.profile_id = layout.profile_id
	invalid_layout.profile_version = layout.profile_version
	invalid_layout.layout_version = layout.layout_version
	invalid_layout.terrain_seed = layout.terrain_seed
	invalid_layout.accepted_seed = layout.accepted_seed
	invalid_layout.generation_attempt = layout.generation_attempt
	invalid_layout.cell_count = layout.cell_count
	invalid_layout.local_bounds = layout.local_bounds
	invalid_layout.heights = layout.heights.duplicate()
	invalid_layout.top_topology = TerrainTopTopology.build(
		invalid_layout.cell_count, invalid_layout.local_bounds, invalid_layout.heights
	)
	invalid_layout.route_graph = GeneratedRouteGraph.new(invalid_nodes, layout.route_graph.edges)
	invalid_layout.containment = layout.containment
	_assert_true(invalid_layout.is_valid(), "%s invalid-placement fixture must preserve the typed graph shape" % stage.stage_id)
	var rejected := MechanismPlacementGenerator.generate(stage, invalid_layout)
	_assert_true(rejected.is_empty(), "%s must reject the whole candidate when its exact pad is too small" % stage.stage_id)


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
			placement.route_t, placement.local_xz,
		])
	return result


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Mechanism placement check failed: %s" % message)
