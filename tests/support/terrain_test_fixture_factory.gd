class_name TerrainTestFixtureFactory
extends RefCounted

enum Kind {
	FLAT,
	RAMP,
}

const CELL_COUNT := Vector2i(12, 12)
const BOUNDS := Rect2(Vector2(-15.0, -15.0), Vector2(30.0, 30.0))


static func build_layout(kind: Kind) -> GeneratedStageLayout:
	var layout := GeneratedStageLayout.new()
	layout.profile_id = &"terrain_test_fixture"
	layout.profile_version = 4
	layout.layout_version = 4
	layout.terrain_seed = int(kind) + 1
	layout.accepted_seed = layout.terrain_seed
	layout.generation_attempt = 0
	layout.cell_count = CELL_COUNT
	layout.local_bounds = BOUNDS
	layout.heights = PackedFloat32Array()
	layout.heights.resize((CELL_COUNT.x + 1) * (CELL_COUNT.y + 1))
	for z_index in range(CELL_COUNT.y + 1):
		for x_index in range(CELL_COUNT.x + 1):
			var x := lerpf(BOUNDS.position.x, BOUNDS.end.x, float(x_index) / float(CELL_COUNT.x))
			layout.heights[z_index * (CELL_COUNT.x + 1) + x_index] = ramp_height(x) if kind == Kind.RAMP else 0.0
	var summit_id := GeneratedRouteNode.summit_id(&"terrain_test_fixture")
	var exit_id := GeneratedRouteNode.route_node_id(&"terrain_test_fixture", 0, 1)
	var summit := GeneratedRouteNode.new(
		summit_id,
		Vector3(0.0, layout.height_at_local(0.0, -10.0), -10.0),
		-1,
		0,
		GeneratedRouteNode.Kind.SUMMIT
	)
	var exit := GeneratedRouteNode.new(
		exit_id,
		Vector3(0.0, layout.height_at_local(0.0, 10.0), 10.0),
		0,
		1,
		GeneratedRouteNode.Kind.EXIT
	)
	var edge := GeneratedRouteEdge.new(
		GeneratedRouteEdge.stable_id(&"terrain_test_fixture", 0, 0),
		summit_id,
		exit_id,
		0,
		0,
		StageRouteProfile.Role.PRIMARY,
		10.0
	)
	layout.route_graph = GeneratedRouteGraph.new([summit, exit], [edge])
	return layout


static func ramp_height(x: float) -> float:
	return tan(deg_to_rad(35.0)) * (x + 15.0)
