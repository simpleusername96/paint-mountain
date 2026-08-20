extends SceneTree

const FIXTURE_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	host.add_child(surface)
	surface.configure(TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT))
	var manager := ProjectileManager.new()
	host.add_child(manager)
	manager.configure_terrain(surface)
	var commands: Array[RadialPaintMark] = []
	var effects := {"count": 0}
	var events: Array[StringName] = []
	manager.configure_paint_admission(
		func(command: RadialPaintMark) -> bool:
			events.append(&"admit_burst" if command.kind == RadialPaintMark.Kind.BURST else &"admit_impact")
			return true,
		func(_command: SurfacePaintSweep) -> bool: return true
	)
	manager.radial_paint_mark_ready.connect(func(command: RadialPaintMark) -> void: commands.append(command))
	manager.intrinsic_effect_requested.connect(func(_projectile: PaintProjectile, _contact: ProjectileContact) -> void:
		effects.count += 1
		events.append(&"effect")
	)
	manager.projectile_stopped.connect(func(_projectile: PaintProjectile, reason: StringName) -> void:
		if reason == ProjectileSettlementReason.CONSUMED:
			events.append(&"consumed")
	)
	await physics_frame
	var point := surface.world_surface_point(Vector2.ZERO)
	var projectile := manager.spawn_projectile(
		PROJECTILE_DATA, point + Vector3.UP * 4.0, Vector3(0.0, -18.0, 0.0),
		0, 0, -1.0, BallToken.new(BallKind.Value.IMPACT_BURST, PaintChannel.Value.GREEN)
	)
	_assert(projectile != null, "Burst root must be admitted")
	for _tick in range(120):
		await physics_frame
		manager.finalize_pending_paint_intents()
		if manager.active_count() == 0:
			break
	_assert(commands.size() == 2, "Burst contact must emit only ordinary impact and one radial burst")
	if commands.size() == 2:
		_assert(commands[0].kind == RadialPaintMark.Kind.IMPACT, "ordinary impact must precede Burst")
		_assert(commands[1].kind == RadialPaintMark.Kind.BURST and is_equal_approx(commands[1].radius, 14.0), "Burst must use the locked radius 14")
		_assert(commands[0].channel == PaintChannel.Value.GREEN and commands[1].channel == PaintChannel.Value.GREEN, "both commands must retain the root channel")
	_assert(int(effects.count) == 1, "Burst must request exactly one intrinsic effect")
	_assert(manager.active_count() == 0, "Burst must consume before any rolling trail")
	_assert(
		events == [&"admit_impact", &"admit_burst", &"effect", &"consumed"],
		"ordinary impact, accepted Burst, presentation, and consumption must be ordered exactly once"
	)

	# A rejected authoritative Burst command gets no cue and does not consume;
	# the projectile resumes as a Standard resident after the contact pause.
	manager.cleanup()
	commands.clear()
	effects.count = 0
	events.clear()
	var rejection := {"burst_rejected": false}
	manager.configure_paint_admission(
		func(command: RadialPaintMark) -> bool:
			if command.kind == RadialPaintMark.Kind.BURST:
				rejection.burst_rejected = true
				return false
			return true,
		func(_command: SurfacePaintSweep) -> bool: return true
	)
	var fallback := manager.spawn_projectile(
		PROJECTILE_DATA, point + Vector3.UP * 4.0, Vector3(0.0, -18.0, 0.0),
		0, 0, -1.0, BallToken.new(BallKind.Value.IMPACT_BURST, PaintChannel.Value.RED)
	)
	_assert(fallback != null, "rejection fixture must admit its Burst root")
	for _tick in range(120):
		await physics_frame
		manager.finalize_pending_paint_intents()
		if bool(rejection.burst_rejected):
			break
	_assert(bool(rejection.burst_rejected), "fixture must exercise an authoritative Burst rejection")
	_assert(int(effects.count) == 0, "rejected Burst work must publish no success effect")
	_assert(
		fallback != null and is_instance_valid(fallback) and manager.active_projectiles().has(fallback),
		"rejected Burst work must preserve the root on its Standard fallback"
	)
	_assert(commands.size() == 1 and commands[0].kind == RadialPaintMark.Kind.IMPACT, "rejected Burst work must not publish a ready radial command")
	manager.cleanup()
	host.queue_free()
	await physics_frame
	if not _failed:
		print("impact_burst_ball_test passed: authoritative admission orders accepted Burst and suppresses rejected cues/consumption.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Impact Burst test failed: %s" % message)
