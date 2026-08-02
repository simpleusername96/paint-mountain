extends SceneTree

const SANDBOX_SCENE := preload("res://scenes/sandbox/projectile_sandbox.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.time_scale = 2.0
	var sandbox := SANDBOX_SCENE.instantiate()
	root.add_child(sandbox)
	await physics_frame
	await physics_frame
	var cannon: CannonController = sandbox.get_node("Cannon")
	var manager: ProjectileManager = sandbox.get_node("ProjectileManager")
	var paint_system: PaintSystem = sandbox.get_node("PaintSystem")
	var observed := {"deposit_count": 0, "request_count": 0, "amount": 0.0, "kinds": {}}
	manager.paint_deposit_requested.connect(
		func(_projectile: PaintProjectile, kind: StringName, _position: Vector3, _radius: float, amount: float, _flow: bool) -> void:
			observed.request_count += 1
			observed.amount += amount
			observed.kinds[kind] = int(observed.kinds.get(kind, 0)) + 1
	)
	paint_system.paint_deposited.connect(
		func(_kind: StringName, _position: Vector3, _radius: float) -> void:
			observed.deposit_count += 1
	)
	cannon.set_aim(0.0, 38.0, 68.0)
	_assert_true(cannon.request_fire(), "sandbox cannon must accept a ready fire command")
	var frame_budget := 60 * 24
	while manager.active_count() > 0 and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	paint_system.flush_pending()
	_assert_true(manager.active_count() == 0, "painted projectile must terminate without an orphan")
	_assert_true(observed.deposit_count > 0, "physical projectile contacts must produce paint deposits")
	_assert_true(observed.kinds.has(&"impact"), "physical contact must request an impact splash")
	_assert_true(observed.kinds.has(&"trail"), "surface travel must request repeated trail stamps")
	_assert_true(observed.kinds.has(&"puddle"), "settlement must request a final puddle")
	_assert_true(observed.amount <= cannon.projectile_data.initial_payload + 0.001, "deposit requests must never exceed finite payload")
	_assert_true(paint_system.coverage_percent() > 0.0, "projectile deposits must increase authoritative coverage")
	if not _failed:
		print(
			"Phase 3 projectile-paint integration passed: %d/%d accepted/requested, %.4f%% coverage, kinds=%s." % [
				observed.deposit_count,
				observed.request_count,
				paint_system.coverage_percent(),
				observed.kinds,
			]
		)
	Engine.time_scale = 1.0
	sandbox.queue_free()
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
