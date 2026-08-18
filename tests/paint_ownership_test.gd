extends SceneTree

const FIXTURE_FACTORY := preload("res://tests/support/terrain_test_fixture_factory.gd")
const PAINT_SHADER := preload("res://src/paint/terrain_paint.gdshader")
const TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")

var _failed := false
var _rid := RID()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_rid = PhysicsServer3D.body_create()
	var paint := _configured()
	var red := _mark(paint, 1, PaintChannel.Value.RED)
	_assert(paint.queue_radial_paint_mark(red), "Red command must queue")
	paint.drain_pending_commands()
	var snapshot: PaintCoverageSnapshot = paint.coverage_snapshot()
	_assert(snapshot.red_percent > 0.0 and is_zero_approx(snapshot.green_percent), "first target coat must count as Red")
	var strength_before := paint.paint_bytes_read_only()
	var checksum_before := paint.paint_mask_checksum()
	var green := _mark(paint, 2, PaintChannel.Value.GREEN)
	_assert(paint.queue_radial_paint_mark(green), "Green overwrite must queue")
	paint.drain_pending_commands()
	snapshot = paint.coverage_snapshot()
	_assert(is_zero_approx(snapshot.red_percent) and snapshot.green_percent > 0.0, "latest valid writer must own target area")
	_assert(paint.paint_bytes_read_only() == strength_before, "lower/equal ownership write must not reduce strength")
	_assert(paint.paint_mask_checksum() != checksum_before, "owner transition must participate in checksum")
	var owners := paint.paint_owner_bytes_read_only()
	var center := PaintMaskAddressing.snap_uv_to_pixel(Vector2(0.5, 0.5), PaintSystem.MASK_SIZE)
	_assert(owners[center.y * PaintSystem.MASK_SIZE + center.x] == PaintChannel.Value.GREEN, "owner texture API must decode Green")
	_assert(owners[0] == PaintSystem.OWNER_UNPAINTED_BYTE, "owner API must use an explicit byte sentinel for unpainted texels")
	paint.clear()
	_assert(is_zero_approx(paint.coverage_snapshot().total_percent), "clear must reset both channel counters")
	paint.free()
	PhysicsServer3D.free_rid(_rid)
	if not _failed:
		print("Paint ownership passed: RG authority, monotonic strength, latest writer, counters, and checksum.")
	quit(1 if _failed else 0)


func _configured() -> PaintSystem:
	var layout: GeneratedStageLayout = FIXTURE_FACTORY.build_layout(FIXTURE_FACTORY.Kind.FLAT)
	layout.profile_version = StageGenerationContract.CONTRACT_VERSION
	layout.layout_version = StageGenerationContract.CONTRACT_VERSION
	if not layout.has_valid_footprint():
		var footprint := PackedByteArray()
		footprint.resize(layout.cell_count.x * layout.cell_count.y)
		footprint.fill(1)
		assert(layout.install_footprint(footprint))
	var target := PackedByteArray()
	target.resize(PaintSystem.MASK_SIZE * PaintSystem.MASK_SIZE)
	target.fill(255)
	assert(FIXTURE_FACTORY.install_target_mask_with_coverage(layout, target))
	var paint := PaintSystem.new()
	root.add_child(paint)
	var material := ShaderMaterial.new()
	material.shader = PAINT_SHADER
	paint.configure(layout.local_bounds, 0.0, material, Color(0.94, 0.17, 0.20), layout, TUNING)
	paint.configure_top_surface_identity(_rid, TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID, TerrainSurface.TOP_SHAPE_ID, 0)
	return paint


func _mark(paint: PaintSystem, tick: int, channel: int) -> RadialPaintMark:
	var layout := paint.generated_layout_read_only()
	var identity := paint.authoritative_top_surface_identity()
	return RadialPaintMark.new(tick, 0, 0, 0, Vector3.ZERO, layout.normal_at_local(0.0, 0.0), 4.0, identity.collider_rid, identity.contact_owner_id, identity.contact_shape_id, int(identity.collider_shape_index), RadialPaintMark.Kind.IMPACT, 1, channel)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Paint ownership test failed: %s" % message)
