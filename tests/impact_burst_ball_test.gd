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
	manager.radial_paint_mark_ready.connect(func(command: RadialPaintMark) -> void: commands.append(command))
	manager.intrinsic_effect_requested.connect(func(_projectile: PaintProjectile, _contact: ProjectileContact) -> void: effects.count += 1)
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
	manager.cleanup()
	host.queue_free()
	await physics_frame
	if not _failed:
		print("impact_burst_ball_test passed: first terrain contact emits impact then same-channel radius-14 burst and consumes.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Impact Burst test failed: %s" % message)
