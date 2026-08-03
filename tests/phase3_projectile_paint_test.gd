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
	var observed := {
		"applied_count": 0,
		"request_count": 0,
		"requested_amount": 0.0,
		"accepted_amount": 0.0,
		"written_pixels": 0,
		"kinds": {},
		"stop_reason": &"",
	}
	manager.projectile_stopped.connect(
		func(_projectile: PaintProjectile, reason: StringName) -> void:
			observed.stop_reason = reason
	)
	manager.paint_deposit_requested.connect(
		func(_projectile: PaintProjectile, request: PaintDepositRequest) -> void:
			observed.request_count += 1
			observed.requested_amount += request.amount
			var kind := PaintDepositRequest.source_kind_name(request.source_kind)
			observed.kinds[kind] = int(observed.kinds.get(kind, 0)) + 1
	)
	manager.paint_deposit_resolved.connect(
		func(
				_projectile: PaintProjectile,
				_request: PaintDepositRequest,
				accepted_amount: float,
				written_pixel_count: int
		) -> void:
			observed.accepted_amount += accepted_amount
			observed.written_pixels += written_pixel_count
	)
	paint_system.deposit_applied.connect(
		func(_request: PaintDepositRequest, _accepted: float, _written: int, _newly_painted: int) -> void:
			observed.applied_count += 1
	)
	cannon.set_aim(0.0, 38.0, 68.0)
	_assert_true(cannon.request_fire(), "sandbox cannon must accept a ready fire command")
	var active := manager.active_projectiles()
	_assert_true(active.size() == 1, "accepted fire must spawn exactly one projectile")
	var projectile := active[0] if not active.is_empty() else null
	var initial_payload := projectile.remaining_payload if projectile != null else cannon.projectile_data.initial_payload
	for _airborne_frame in range(3):
		await physics_frame
	if projectile != null and is_instance_valid(projectile):
		_assert_true(
			is_equal_approx(projectile.remaining_payload, initial_payload),
			"airborne travel must consume no paint payload"
		)
	var frame_budget := 60 * 24
	while manager.active_count() > 0 and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	paint_system.flush_pending()
	_assert_true(manager.active_count() == 0, "painted projectile must terminate without an orphan")
	_assert_true(observed.applied_count > 0, "physical projectile contacts must produce accepted paint deposits")
	_assert_true(observed.kinds.has(&"impact"), "physical top contact must request an impact deposit")
	_assert_true(observed.kinds.has(&"trail"), "surface travel must request repeated trail deposits")
	_assert_true(observed.stop_reason != &"", "projectile termination must publish a bounded stop reason")
	_assert_true(observed.accepted_amount <= initial_payload + 0.001, "accepted deposits must never exceed finite payload")
	_assert_true(observed.written_pixels > 0, "accepted deposits must write the authoritative mask")
	_assert_true(paint_system.coverage_percent() > 0.0, "projectile deposits must increase authoritative coverage")
	_assert_true(paint_system.persistent_noneligible_pixel_count() == 0, "persistent paint must never enter score-ineligible pixels")
	if not _failed:
		print(
			"Phase 3 projectile-paint integration passed: %d/%d accepted/requested, %.1f payload, %.4f%% coverage, kinds=%s." % [
				observed.applied_count,
				observed.request_count,
				observed.accepted_amount,
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
