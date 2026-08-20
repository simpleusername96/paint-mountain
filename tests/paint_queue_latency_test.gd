extends SceneTree

const FIXTURE_FACTORY := preload("res://tests/support/terrain_test_fixture_factory.gd")
const PAINT_SHADER := preload("res://src/paint/terrain_paint.gdshader")
const SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const PRODUCER_COUNT := 3
const PRODUCTION_TICKS := 36
const SWEEP_CADENCE_TICKS := 4
const MAXIMUM_PENDING_AGE_TICKS := 12
const MAXIMUM_DRAIN_USEC := 16700

var _failed := false
var _top_body_rid := RID()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(PROJECTILE_DATA.minimum_paint_travel_distance >= 0.75
			and PROJECTILE_DATA.minimum_paint_travel_distance < PROJECTILE_DATA.paint_footprint_radius,
		"contact samples must coalesce without approaching the visible footprint width")
	_top_body_rid = PhysicsServer3D.body_create()
	var reference := _configured_system()
	var incremental := _configured_system()
	_warm_surface_cache(reference)
	_warm_surface_cache(incremental)
	reference.clear()
	incremental.clear()

	var expected_order: Array[Vector3i] = []
	var applied_order: Array[Vector3i] = []
	incremental.paint_command_applied.connect(func(command, _written: int, _newly: int) -> void:
		applied_order.append(Vector3i(
			int(command.physics_tick), int(command.spawn_ordinal), int(command.sequence)
		))
	)
	var reference_burst := _burst(reference)
	var incremental_burst := _burst(incremental)
	expected_order.append(Vector3i(1, 0, 0))
	_assert(reference.queue_radial_paint_mark(reference_burst), "reference Burst must queue")
	_assert(incremental.queue_radial_paint_mark(incremental_burst), "incremental Burst must queue")

	for tick in range(1, PRODUCTION_TICKS + 1):
		if tick % SWEEP_CADENCE_TICKS != 0:
			continue
		for producer in range(PRODUCER_COUNT):
			var reference_command := _workload_sweep(reference, tick, producer)
			expected_order.append(Vector3i(tick, producer, int(reference_command.sequence)))
			_assert(reference.queue_surface_paint_sweep(reference_command),
				"reference sweep must queue")
	reference.drain_pending_commands()

	var maximum_age := 0
	var maximum_pending := 0
	var maximum_drain_usec := 0
	var maximum_completed_per_tick := 0
	var completed_during_production := 0
	for tick in range(1, PRODUCTION_TICKS + 1):
		if tick % SWEEP_CADENCE_TICKS == 0:
			for producer in range(PRODUCER_COUNT):
				_assert(incremental.queue_surface_paint_sweep(
					_workload_sweep(incremental, tick, producer)
				), "incremental sweep must queue")
		var started_at := Time.get_ticks_usec()
		var result := incremental.drain_pending_commands(false)
		maximum_drain_usec = maxi(maximum_drain_usec, Time.get_ticks_usec() - started_at)
		completed_during_production += int(result.command_count)
		maximum_completed_per_tick = maxi(
			maximum_completed_per_tick, int(result.command_count)
		)
		var snapshot := incremental.queue_latency_snapshot(tick)
		maximum_age = maxi(maximum_age, int(snapshot.oldest_pending_age_ticks))
		maximum_pending = maxi(maximum_pending, int(snapshot.pending_count))

	var pending_at_contact_end := incremental.pending_work_count()
	var previous_pending := pending_at_contact_end
	var drain_ticks := 0
	while incremental.pending_work_count() > 0 and drain_ticks < MAXIMUM_PENDING_AGE_TICKS:
		drain_ticks += 1
		var current_tick := PRODUCTION_TICKS + drain_ticks
		var started_at := Time.get_ticks_usec()
		incremental.drain_pending_commands(false)
		maximum_drain_usec = maxi(maximum_drain_usec, Time.get_ticks_usec() - started_at)
		var snapshot := incremental.queue_latency_snapshot(current_tick)
		maximum_age = maxi(maximum_age, int(snapshot.oldest_pending_age_ticks))
		var pending := int(snapshot.pending_count)
		_assert(pending <= previous_pending, "pending work must not grow after contact ends")
		previous_pending = pending

	var final_snapshot := incremental.queue_latency_snapshot(PRODUCTION_TICKS + drain_ticks)
	_assert(maximum_completed_per_tick > 1,
		"the shared budget must continue into another small command when time remains")
	_assert(maximum_age <= MAXIMUM_PENDING_AGE_TICKS,
		"the oldest continuous paint command must stay within 12 physics ticks")
	_assert(incremental.pending_work_count() == 0,
		"continuous paint work must drain within 12 ticks after contact ends")
	_assert(maximum_drain_usec < MAXIMUM_DRAIN_USEC,
		"one incremental PaintSystem drain must stay below 16.7 ms")
	_assert(applied_order == expected_order,
		"incremental paint acknowledgements must retain canonical command order")
	_assert(
		incremental.paint_bytes_read_only() == reference.paint_bytes_read_only()
			and incremental.paint_owner_bytes_read_only() == reference.paint_owner_bytes_read_only()
			and incremental.paint_mask_checksum() == reference.paint_mask_checksum()
			and incremental.painted_target_pixels() == reference.painted_target_pixels(),
		"incremental three-producer output must equal the completion barrier"
	)
	var expected_command_count := 1 \
			+ PRODUCER_COUNT * (PRODUCTION_TICKS / SWEEP_CADENCE_TICKS)
	_assert(int(final_snapshot.queued_total) == expected_command_count
			and int(final_snapshot.completed_total) == expected_command_count,
		"queue diagnostics must report every admitted and completed command")

	var metrics := {
		"commands": expected_command_count,
		"completed_during_production": completed_during_production,
		"maximum_completed_per_tick": maximum_completed_per_tick,
		"pending_at_contact_end": pending_at_contact_end,
		"drain_ticks_after_contact": drain_ticks,
		"maximum_pending_count": maximum_pending,
		"maximum_oldest_pending_age_ticks": maximum_age,
		"maximum_drain_usec": maximum_drain_usec,
	}
	print("Paint queue latency %s: %s" % [
		"passed" if not _failed else "failed",
		JSON.stringify(metrics),
	])

	reference.free()
	incremental.free()
	PhysicsServer3D.free_rid(_top_body_rid)
	quit(1 if _failed else 0)


func _warm_surface_cache(paint: PaintSystem) -> void:
	for producer in range(PRODUCER_COUNT):
		paint.queue_surface_paint_sweep(_sweep(
			paint.generated_layout_read_only(),
			1,
			producer,
			producer,
			Vector2(float(producer - 1) * 0.25, -6.5),
			Vector2(float(producer - 1) * 0.25, 3.5),
			0.45,
			producer + 1,
			producer % 2
		))
	paint.drain_pending_commands()


func _workload_sweep(paint: PaintSystem, tick: int, producer: int) -> SurfacePaintSweep:
	var z_to := -6.0 + float(tick) * 0.25
	var x := float(producer - 1) * 0.25
	return _sweep(
		paint.generated_layout_read_only(),
		tick,
		producer,
		1 + (tick / SWEEP_CADENCE_TICKS - 1) * PRODUCER_COUNT + producer,
		Vector2(x, z_to - 0.25 * SWEEP_CADENCE_TICKS),
		Vector2(x, z_to),
		0.32,
		producer + 1,
		producer % 2
	)


func _burst(paint: PaintSystem) -> RadialPaintMark:
	var layout := paint.generated_layout_read_only()
	var point := Vector3(0.0, layout.height_at_local(0.0, -6.5), -6.5)
	return RadialPaintMark.new(
		1,
		0,
		0,
		0,
		point,
		layout.normal_at_local(0.0, -6.5),
		2.0,
		_top_body_rid,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		0,
		RadialPaintMark.Kind.BURST,
		1,
		PaintChannel.Value.RED
	)


func _configured_system() -> PaintSystem:
	var layout: GeneratedStageLayout = FIXTURE_FACTORY.build_layout(FIXTURE_FACTORY.Kind.FLAT)
	layout.profile_version = StageGenerationContract.CONTRACT_VERSION
	layout.layout_version = StageGenerationContract.CONTRACT_VERSION
	var target_mask := PackedByteArray()
	target_mask.resize(PaintSystem.MASK_SIZE * PaintSystem.MASK_SIZE)
	target_mask.fill(255)
	assert(FIXTURE_FACTORY.install_target_mask_with_coverage(layout, target_mask))
	var paint := PaintSystem.new()
	root.add_child(paint)
	var material := ShaderMaterial.new()
	material.shader = PAINT_SHADER
	paint.configure(
		layout.local_bounds,
		0.0,
		material,
		Color(0.03, 0.38, 1.0),
		layout,
		SURFACE_TUNING
	)
	paint.configure_top_surface_identity(
		_top_body_rid,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		0
	)
	return paint


func _sweep(
		layout: GeneratedStageLayout,
		tick: int,
		ordinal: int,
		sequence: int,
		from_xz: Vector2,
		to_xz: Vector2,
		radius: float,
		shot_id: int,
		channel: int
) -> SurfacePaintSweep:
	var from_point := Vector3(
		from_xz.x, layout.height_at_local(from_xz.x, from_xz.y), from_xz.y
	)
	var to_point := Vector3(
		to_xz.x, layout.height_at_local(to_xz.x, to_xz.y), to_xz.y
	)
	return SurfacePaintSweep.new(
		tick,
		ordinal,
		0,
		sequence,
		from_point,
		to_point,
		layout.normal_at_local(from_xz.x, from_xz.y),
		layout.normal_at_local(to_xz.x, to_xz.y),
		radius,
		_top_body_rid,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		0,
		false,
		shot_id,
		channel
	)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Paint queue latency check failed: %s" % message)
