extends SceneTree

const PAINT_SHADER := preload("res://src/paint/terrain_paint.gdshader")
const PAINT_DEPOSIT_TUNING := preload("res://resources/paint/default_paint_deposit_tuning.tres")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var flat := _build_layout(&"flat")
	var paint_system := _configured_system(flat)
	var material := paint_system.get_meta(&"test_material") as ShaderMaterial
	_assert_true(material.get_shader_parameter(&"paint_mask") == paint_system.paint_texture(), "shader must bind the authoritative paint texture")
	_assert_true(material.get_shader_parameter(&"eligible_mask") == paint_system.eligible_texture(), "shader must bind the authoritative eligible texture")
	var request := PaintDepositRequest.new(
		PaintDepositRequest.SourceKind.TRAIL, Vector3.ZERO, Vector3.UP,
		4.0, 22.0, false, 0, 1001, 1, 1
	)
	var first := paint_system.apply_deposit(request)
	_assert_true(int(first.written_pixel_count) == 3228, "narrow fixture must write exactly 3,228 pixels")
	_assert_true(int(first.newly_painted_pixel_count) == 3228, "first narrow stamp must cross threshold on 3,228 pixels")
	_assert_true(is_equal_approx(float(first.accepted_amount), 22.0), "accepted narrow stamp must consume its full request amount")
	_assert_true(absf(paint_system.coverage_percent() - 1.231384) <= 0.00001, "narrow fixture coverage must be exactly 1.231384%")
	_assert_true(_visible_pixel_count(paint_system.paint_bytes_read_only()) == 3228, "persistent visible pixels must equal written eligible pixels")
	_assert_true(paint_system.persistent_noneligible_pixel_count() == 0, "persistent paint must never write an excluded pixel")
	var second := paint_system.apply_deposit(request)
	_assert_true(int(second.newly_painted_pixel_count) == 0, "identical second stamp must add zero coverage pixels")
	_assert_true(paint_system.painted_eligible_pixels() == 3228, "overlap must not double-count coverage")
	paint_system.queue_free()

	var cliff := _build_layout(&"cliff")
	var cliff_paint := _configured_system(cliff)
	var cliff_request := PaintDepositRequest.new(
		PaintDepositRequest.SourceKind.IMPACT, Vector3(-2.0, 0.0, 0.0), Vector3.UP,
		6.0, 22.0, false, 0, 1002, 2, 1
	)
	var cliff_result := cliff_paint.apply_deposit(cliff_request)
	_assert_true(float(cliff_result.accepted_amount) == 22.0, "near cliff face must accept its connected side")
	_assert_true(_painted_right_half(cliff_paint.paint_bytes_read_only()) == 0, "3D distance and connectivity must not paint the opposite cliff")
	_assert_true(cliff_paint.persistent_noneligible_pixel_count() == 0, "cliff stamp must remain eligible-only")
	cliff_paint.queue_free()

	var slope := _build_layout(&"slope")
	var flow_paint := _configured_system(slope)
	var flow_origin := Vector3(0.0, slope.height_at_local(0.0, 0.0), 0.0)
	var direct_request := PaintDepositRequest.new(
		PaintDepositRequest.SourceKind.FINAL_PUDDLE, flow_origin, slope.normal_at_local(0.0, 0.0),
		0.8, 18.0, false, 0, 1003, 3, 1
	)
	var direct := flow_paint.apply_deposit(direct_request)
	flow_paint.clear()
	var flow_request := PaintDepositRequest.new(
		PaintDepositRequest.SourceKind.FINAL_PUDDLE, flow_origin, slope.normal_at_local(0.0, 0.0),
		0.8, 18.0, true, 12, 1003, 3, 2
	)
	var flowed := flow_paint.apply_deposit(flow_request)
	_assert_true(int(flowed.written_pixel_count) > int(direct.written_pixel_count), "bounded steepest-descent flow must add connected downhill pixels")
	_assert_true(flow_paint.pending_work_count() == 0, "flow must settle synchronously within its bounded steps")
	flow_paint.clear()
	_assert_true(is_zero_approx(flow_paint.coverage_percent()), "clear must reset authoritative coverage")
	flow_paint.queue_free()

	if not _failed:
		print("Phase 3 authoritative paint passed: 3,228 pixels, 1.231384%, zero overlap gain, cliff isolation, and bounded flow.")
	quit(1 if _failed else 0)


func _configured_system(layout: GeneratedStageLayout) -> PaintSystem:
	var paint_system := PaintSystem.new()
	root.add_child(paint_system)
	var material := ShaderMaterial.new()
	material.shader = PAINT_SHADER
	paint_system.configure(layout.local_bounds, 0.0, material, Color(0.03, 0.38, 1.0), layout, PAINT_DEPOSIT_TUNING)
	paint_system.set_meta(&"test_material", material)
	return paint_system


func _build_layout(kind: StringName) -> GeneratedStageLayout:
	var layout := GeneratedStageLayout.new()
	layout.profile_id = &"paint_narrow_fixture"
	layout.profile_version = 3
	layout.terrain_seed = 1
	layout.accepted_seed = 1
	layout.generation_attempt = 0
	layout.cell_count = Vector2i(64, 64)
	layout.local_bounds = Rect2(Vector2(-32.0, -32.0), Vector2(64.0, 64.0))
	layout.heights.resize(65 * 65)
	for z_index in range(65):
		var z := -32.0 + float(z_index)
		for x_index in range(65):
			var x := -32.0 + float(x_index)
			var height := 0.0
			if kind == &"cliff" and x > 0.0:
				height = 8.0
			elif kind == &"slope":
				height = -0.08 * z + 3.0
			layout.heights[z_index * 65 + x_index] = height
	layout.route_spines = [PackedVector3Array([Vector3(0, 0, -20), Vector3(0, 0, 20)])]
	layout.route_widths = PackedFloat32Array([16.0])
	layout.route_roles = PackedInt32Array([StageRouteProfile.Role.PRIMARY])
	layout.route_reversal_counts = PackedInt32Array([0])
	layout.route_shelf_positions = PackedFloat32Array([-1.0])
	layout.route_shelf_radii = PackedFloat32Array([0.0])
	layout.eligible_mask.resize(512 * 512)
	layout.eligible_mask.fill(255)
	return layout


func _visible_pixel_count(bytes: PackedByteArray) -> int:
	var count := 0
	for byte in bytes:
		if byte > 0:
			count += 1
	return count


func _painted_right_half(bytes: PackedByteArray) -> int:
	var count := 0
	for y in range(512):
		for x in range(256, 512):
			if bytes[y * 512 + x] > 0:
				count += 1
	return count


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Phase 3 paint check failed: %s" % message)
