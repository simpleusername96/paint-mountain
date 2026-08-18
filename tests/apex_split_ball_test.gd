extends SceneTree

const FIXTURE_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const APEX_SPLIT_BEHAVIOR := preload("res://src/projectile/apex_split_ball_behavior.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var behavior := APEX_SPLIT_BEHAVIOR.new()
	var direct_children: Array[Vector3] = behavior.on_airborne_velocity(
		Vector3(10.0, 0.1, 0.0), Vector3(10.0, -0.1, 0.0)
	)
	_assert(direct_children.size() == 3, "positive-to-nonpositive crossing must create three launch vectors")
	for velocity in direct_children:
		_assert(absf(velocity.length_squared() - velocity.y * velocity.y - 84.64) <= 0.001, "Apex Split must scale crossing horizontal speed by 0.92")
		_assert(is_equal_approx(velocity.y, 1.5), "Apex Split must use the locked upward addition")
	var terrain_first_behavior := APEX_SPLIT_BEHAVIOR.new()
	terrain_first_behavior.note_valid_terrain_contact()
	_assert(
		terrain_first_behavior.on_airborne_velocity(Vector3(10.0, 0.1, 0.0), Vector3(10.0, -0.1, 0.0)).is_empty(),
		"terrain-first Apex Split must become Standard and never split after bounce"
	)
	var host := Node3D.new()
	root.add_child(host)
	var surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	host.add_child(surface)
	surface.configure(TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT))
	var manager := ProjectileManager.new()
	host.add_child(manager)
	manager.configure_terrain(surface)
	var spawned: Array[PaintProjectile] = []
	manager.projectile_spawned.connect(func(projectile: PaintProjectile) -> void: spawned.append(projectile))
	await physics_frame
	var projectile := manager.spawn_projectile(
		PROJECTILE_DATA, Vector3(0.0, 20.0, 0.0), Vector3(10.0, 10.0, 0.0),
		0, 0, -1.0, BallToken.new(BallKind.Value.APEX_SPLIT, PaintChannel.Value.GREEN)
	)
	_assert(projectile != null, "Apex Split root must be admitted")
	for _tick in range(180):
		await physics_frame
		if spawned.size() == 4:
			break
	_assert(spawned.size() == 4, "first pre-contact apex must replace root with exactly three children")
	if spawned.size() == 4:
		var root_ball := spawned[0]
		var child_horizontal_squared := -1.0
		_assert(root_ball.ball_kind == BallKind.Value.APEX_SPLIT, "root keeps Apex Split identity")
		for child_index in range(1, spawned.size()):
			var child := spawned[child_index]
			_assert(child.ball_kind == BallKind.Value.STANDARD and child.split_generation == 1, "children must be generation-one Standard balls")
			_assert(child.paint_channel == PaintChannel.Value.GREEN and child.shot_id == root_ball.shot_id, "children must inherit root channel and shot")
			var horizontal_squared := child.linear_velocity.length_squared() - child.linear_velocity.y * child.linear_velocity.y
			if child_horizontal_squared < 0.0:
				child_horizontal_squared = horizontal_squared
			_assert(absf(horizontal_squared - child_horizontal_squared) <= 0.01, "all fan children must retain the same scaled horizontal speed")
			_assert(absf(child.linear_velocity.y - 1.5) <= 0.5, "children must use the locked upward addition")
	manager.cleanup()
	host.queue_free()
	await physics_frame
	if not _failed:
		print("apex_split_ball_test passed: generation-zero pre-contact apex creates three Standard children with inherited identity.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Apex Split test failed: %s" % message)
