extends SceneTree

const STAGE_GENERATION_CONTRACT := preload("res://src/stage_generation/stage_generation_contract.gd")
const GENERATION_CONTRACT := preload("res://resources/stage_generation/version4_generation_contract.tres")
const PAINT_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")

var _failed := false


func _initialize() -> void:
	_run_checks()
	if not _failed:
		print("Version 4 contract checks passed: generation constants, graph IDs, aim snapping, hit identity, paint ordering, containment, and validation.")
	quit(1 if _failed else 0)


func _run_checks() -> void:
	_assert_generation_contract()
	_assert_graph_contract()
	_assert_aim_contract()
	_assert_hit_identity_contract()
	_assert_paint_command_contract()
	_assert_certificate_contract()
	_assert_containment_contract()
	_assert_observation_contract()


func _assert_generation_contract() -> void:
	_assert_true(GENERATION_CONTRACT is STAGE_GENERATION_CONTRACT, "the version-4 generation contract resource must load with its typed script")
	var contract := GENERATION_CONTRACT as STAGE_GENERATION_CONTRACT
	_assert_true(contract != null and contract.is_valid(), "the pinned version-4 generation contract must validate")
	_assert_true(contract.generation_version == 4 and contract.profile_version == 4 and contract.layout_version == 4, "generation, profile, and layout versions must all be 4")
	_assert_true(contract.cell_count == Vector2i(72, 48) and contract.local_bounds == Rect2(Vector2(-90.0, -60.0), Vector2(180.0, 120.0)), "the generation grid and local bounds must remain fixed")
	_assert_true(contract.top_triangle_count == 6912 and contract.top_triangle_count == contract.cell_count.x * contract.cell_count.y * 2, "the fixed grid must emit exactly 6,912 top triangles")
	_assert_true(contract.cell_diagonal == STAGE_GENERATION_CONTRACT.CellDiagonal.P01_TO_P10, "the shared cell edge must remain p01-to-p10")
	_assert_true(contract.mask_size == 512 and contract.attempt_count == 32 and contract.attempt_seed_stride == 7919, "mask size and bounded seed sequence must remain fixed")
	var invalid_contract := contract.duplicate() as STAGE_GENERATION_CONTRACT
	invalid_contract.attempt_count = 31
	_assert_true(not invalid_contract.is_valid(), "a mutated generation contract must fail closed")


func _assert_graph_contract() -> void:
	var summit_id := GeneratedRouteNode.summit_id(&"first_descent")
	var exit_id := GeneratedRouteNode.route_node_id(&"first_descent", 0, 7)
	_assert_true(summit_id == GeneratedRouteNode.summit_id(&"first_descent"), "node IDs must repeat exactly")
	var summit := GeneratedRouteNode.new(
		summit_id, Vector3(0.0, 72.0, -44.0), -1, 0, GeneratedRouteNode.Kind.SUMMIT
	)
	var exit := GeneratedRouteNode.new(
		exit_id, Vector3(0.0, 28.0, 44.0), 0, 7, GeneratedRouteNode.Kind.EXIT
	)
	var edge_id := GeneratedRouteEdge.stable_id(&"first_descent", 0, 0)
	var edge := GeneratedRouteEdge.new(
		edge_id, summit_id, exit_id, 0, 0, StageRouteProfile.Role.PRIMARY, 28.0
	)
	var graph := GeneratedRouteGraph.new([summit, exit], [edge])
	_assert_true(graph.is_valid(), "a unique, fully referenced graph must validate")
	_assert_true(graph.node_index(summit_id) == 0 and graph.edge_index(edge_id) == 0, "graph ID maps must preserve ordered indices")
	_assert_true(GeneratedRouteEdge.stable_id(&"split_ridge", 1, 3, &"a") == GeneratedRouteEdge.stable_id(&"split_ridge", 1, 3, &"a"), "split-edge IDs must be deterministic")
	var duplicate := GeneratedRouteGraph.new([summit, summit], [edge])
	_assert_true(not duplicate.is_valid(), "duplicate node IDs must be rejected")
	var missing := GeneratedRouteEdge.new(&"missing", summit_id, &"unknown", 0, 0, 0, 12.0)
	_assert_true(not GeneratedRouteGraph.new([summit], [missing]).is_valid(), "missing graph references must be rejected")
	var corridor_id := GeneratedRouteNode.route_node_id(&"first_descent", 0, 1)
	var corridor := GeneratedRouteNode.new(
		corridor_id, Vector3(0.0, 48.0, 20.0), 0, 1, GeneratedRouteNode.Kind.CORRIDOR
	)
	var non_summit_edge := GeneratedRouteEdge.new(
		&"non_summit", corridor_id, exit_id, 0, 0, StageRouteProfile.Role.PRIMARY, 28.0
	)
	_assert_true(not GeneratedRouteGraph.new([summit, corridor, exit], [non_summit_edge]).is_valid(), "every route must start at the shared summit")
	var non_exit_edge := GeneratedRouteEdge.new(
		&"non_exit", summit_id, corridor_id, 0, 0, StageRouteProfile.Role.PRIMARY, 28.0
	)
	_assert_true(not GeneratedRouteGraph.new([summit, corridor], [non_exit_edge]).is_valid(), "every route must end at a typed exit")
	var orphan_pad := GeneratedRouteNode.new(
		&"orphan_pad", Vector3(4.0, 54.0, 0.0), 0, 1,
		GeneratedRouteNode.Kind.PAD, MechanismData.Kind.BURST, 8.0
	)
	_assert_true(not GeneratedRouteGraph.new([summit, exit, orphan_pad], [edge]).is_valid(), "unused pad nodes must invalidate the graph")


func _assert_aim_contract() -> void:
	var aim := AimTuple.canonicalize(-1.25, 38.25, 50.5)
	_assert_true(aim.is_valid(), "canonical aim must validate")
	_assert_true(is_equal_approx(aim.yaw_degrees, -1.3), "negative angle ties must round away from zero")
	_assert_true(is_equal_approx(aim.elevation_degrees, 38.3), "positive angle ties must round away from zero")
	_assert_true(aim.power_percent == 51, "power ties must round half up")
	var bounded := AimTuple.canonicalize(-90.0, 90.0, 200.0)
	_assert_true(bounded.is_equal_to(AimTuple.new(-45.0, 68.0, 100)), "aim canonicalization must clamp to the legal domain")
	_assert_true(not AimTuple.new(0.04, 38.0, 50).is_valid(), "unsnapped aim data must be rejected")
	_assert_true(AimTuple.canonicalize(NAN, 38.0, 50.0) == null, "non-finite aim data must be rejected")


func _assert_hit_identity_contract() -> void:
	var tie := TerrainSurface.classify_top_cell_uv(&"TerrainTopShape", 3, Vector2i(4, 7), Vector2(0.25, 0.75))
	_assert_true(tie != null and tie.is_valid(), "valid terrain hit identity must validate")
	_assert_true(tie.terrain_triangle == 0, "the fixed-diagonal tie must belong to triangle 0")
	_assert_vector3(tie.barycentric, Vector3(0.0, 0.75, 0.25), 0.00001, "triangle 0 barycentrics must use p00,p01,p10 order")
	var upper := TerrainSurface.classify_top_cell_uv(&"TerrainTopShape", 3, Vector2i(4, 7), Vector2(0.75, 0.5))
	_assert_true(upper.terrain_triangle == 1, "u+v > 1 must resolve to triangle 1")
	_assert_vector3(upper.barycentric, Vector3(0.5, 0.25, 0.25), 0.00001, "triangle 1 barycentrics must use p10,p01,p11 order")
	_assert_true(tie.has_same_surface_address(TerrainSurface.classify_top_cell_uv(&"TerrainTopShape", 3, Vector2i(4, 7), Vector2(0.1, 0.1))), "barycentric differences must not change a triangle address")
	_assert_true(not tie.has_same_surface_address(upper), "triangle identity must distinguish the two fixed-diagonal faces")
	_assert_true(TerrainSurface.classify_top_cell_uv(&"TerrainTopShape", 3, Vector2i.ZERO, Vector2(1.1, 0.0)) == null, "out-of-cell UV data must be rejected")


func _assert_paint_command_contract() -> void:
	_assert_true(PAINT_TUNING is PaintSurfaceTuning and PAINT_TUNING.is_valid(), "the explicit v4 paint tuning resource must load and validate")
	_assert_true(PaintMaskAddressing.snap_uv_to_pixel(Vector2.ZERO, PAINT_TUNING.mask_size) == Vector2i.ZERO, "zero UV must clamp to the first pixel")
	_assert_true(PaintMaskAddressing.snap_uv_to_pixel(Vector2(0.5, 0.5), PAINT_TUNING.mask_size) == Vector2i(256, 256), "pixel-center snapping must round half up")
	_assert_true(PaintMaskAddressing.snap_uv_to_pixel(Vector2.ONE, PAINT_TUNING.mask_size) == Vector2i(511, 511), "maximum UV must clamp to the final pixel")
	_assert_true(PaintMaskAddressing.candidate_sort_key(Vector2i(4, 3), Vector2i(3, 3)) == PackedInt32Array([1, 3, 4]), "snap candidates must sort by distance, y, then x")
	var body_rid := PhysicsServer3D.body_create()
	var impact := RadialPaintMark.new(
		10, 0, 2, -1, Vector3.ZERO, Vector3.UP, 9.0, body_rid,
		&"terrain/top", &"TerrainTopShape", 0, RadialPaintMark.Kind.IMPACT
	)
	var sweep := SurfacePaintSweep.new(
		10, 0, 2, -1, Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.UP,
		4.0, body_rid, &"terrain/top", &"TerrainTopShape", 0, false
	)
	var burst := RadialPaintMark.new(
		10, 0, 2, -1, Vector3.ZERO, Vector3.UP, 12.0, body_rid,
		&"terrain/top", &"TerrainTopShape", 0, RadialPaintMark.Kind.BURST
	)
	_assert_true(impact.is_intent_valid() and not impact.is_valid(), "an unsequenced radial intent must be valid only at the producer queue boundary")
	_assert_true(sweep.is_intent_valid() and not sweep.is_valid(), "an unsequenced sweep intent must be valid only at the producer queue boundary")
	_assert_true(int(impact.queue_sort_key()[3]) < int(sweep.queue_sort_key()[3]) and int(sweep.queue_sort_key()[3]) < int(burst.queue_sort_key()[3]), "equal-source commands must order IMPACT before SWEEP before BURST")
	_assert_true(impact.with_sequence(4).drain_sort_key() == PackedInt64Array([10, 0, 4]), "assigned commands must expose the tick/ordinal/sequence drain key")
	_assert_true(not RadialPaintMark.new().is_intent_valid() and not SurfacePaintSweep.new().is_intent_valid(), "missing command identity and geometry must be rejected")
	PhysicsServer3D.free_rid(body_rid)
	var invalid_tuning := PaintSurfaceTuning.new()
	invalid_tuning.mask_size = 0
	_assert_true(not invalid_tuning.is_valid(), "invalid paint tuning must fail closed")


func _assert_certificate_contract() -> void:
	var default_aim := AimTuple.new(0.0, 38.0, 68)
	var alternate := AimTuple.new(1.0, 39.0, 70)
	var certificate := DirectReachabilityCertificate.new(
		&"first_descent", 4, 845479992, 845479992, [default_aim, alternate],
		PackedInt32Array([0, 0, 1]), PackedFloat32Array([0.25, 0.20]),
		PackedFloat32Array([2.0, 1.0]), default_aim, 12345
	)
	_assert_true(certificate.is_valid(), "a complete version-4 reachability certificate must validate")
	var invalid_index := DirectReachabilityCertificate.new(
		&"first_descent", 4, 1, 1, [default_aim], PackedInt32Array([1]),
		PackedFloat32Array([0.1]), PackedFloat32Array([0.1]), default_aim, 1
	)
	_assert_true(not invalid_index.is_valid(), "out-of-range witness indices must be rejected")


func _assert_containment_contract() -> void:
	var containment := ContainmentSpec.new()
	_assert_true(containment.is_valid(), "the fixed v4 containment contract must validate")
	_assert_true(is_equal_approx(containment.backstop_front_z(), -172.25), "backstop front face must be the fixed rear terrain join")
	_assert_true(ContainmentSpec.BACKSTOP_OWNER_ID == &"world/backstop" and ContainmentSpec.BACKSTOP_SHAPE_ID == &"BackstopWall", "backstop stable IDs must match the contact contract")
	_assert_true(not ContainmentSpec.new(4, containment.containment_bounds, containment.apron_xz_bounds, -30.5, containment.backstop_center, containment.backstop_size, 0.25, 0.02).is_valid(), "containment gaps above 0.01 m must be rejected")


func _assert_observation_contract() -> void:
	var contact := ProjectileContact.new(
		Vector3.ZERO, Vector3.UP, Vector3.UP, 0.0, Vector3.DOWN, 1.0,
		Vector3.UP, null, 0, 0, 1, true, true, &"terrain/top", &"TerrainTopShape"
	)
	_assert_true(contact.impulse_was_measured, "contact impulse provenance must preserve measured data")
	_assert_true(contact.contact_owner_id == &"terrain/top" and contact.contact_shape_id == &"TerrainTopShape", "contact observation must expose stable owner and shape IDs")
	var identity := TerrainSurface.classify_top_cell_uv(&"TerrainTopShape", 0, Vector2i.ZERO, Vector2.ZERO)
	var prediction := TrajectoryPrediction.new(TrajectoryPrediction.Kind.COLLISION, Vector3.ZERO, PackedVector3Array(), 0.0, null, Vector3.UP, &"", identity)
	_assert_true(prediction.hit_identity == identity, "trajectory observation must expose immutable hit identity")
	_assert_true(ProjectileSettlementReason.BACKSTOP == &"BACKSTOP" and ProjectileSettlementReason.is_backstop(ProjectileSettlementReason.BACKSTOP), "BACKSTOP must be a recognized non-banking settlement reason")


func _assert_vector3(actual: Vector3, expected: Vector3, tolerance: float, message: String) -> void:
	_assert_true(actual.distance_to(expected) <= tolerance, "%s: expected=%s actual=%s" % [message, expected, actual])


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Version 4 contract check failed: %s" % message)
