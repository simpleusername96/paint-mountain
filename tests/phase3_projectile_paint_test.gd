extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.time_scale = 2.0
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	_assert_true(game_state.select_stage(&"first_descent"), "production First Descent must be selectable")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var paint_system: PaintSystem = gameplay.get_node("PaintSystem")
	var observed := {
		"applied_count": 0,
		"radial_count": 0,
		"impact_count": 0,
		"settle_count": 0,
		"sweep_count": 0,
		"written_pixels": 0,
		"newly_painted_pixels": 0,
		"impact_radii": PackedFloat32Array(),
		"sweep_radii": PackedFloat32Array(),
		"stop_reason": &"",
		"last_drained_tick": -1,
		"paint_checksum": 0,
	}
	manager.projectile_stopped.connect(
		func(_projectile: PaintProjectile, reason: StringName) -> void:
			observed.stop_reason = reason
	)
	manager.radial_paint_mark_ready.connect(
		func(command: RadialPaintMark) -> void:
			observed.radial_count += 1
			if command.kind == RadialPaintMark.Kind.IMPACT:
				observed.impact_count += 1
				observed.impact_radii.append(command.radius)
			elif command.kind == RadialPaintMark.Kind.SETTLE:
				observed.settle_count += 1
	)
	manager.surface_paint_sweep_ready.connect(
		func(command: SurfacePaintSweep) -> void:
			observed.sweep_count += 1
			observed.sweep_radii.append(command.footprint_radius)
	)
	paint_system.paint_command_applied.connect(
		func(_command, written_pixel_count: int, newly_painted_pixel_count: int) -> void:
			observed.applied_count += 1
			observed.written_pixels += written_pixel_count
			observed.newly_painted_pixels += newly_painted_pixel_count
	)
	paint_system.paint_commands_drained.connect(
		func(last_drained_physics_tick: int, _command_count: int, paint_mask_checksum: int) -> void:
			observed.last_drained_tick = last_drained_physics_tick
			observed.paint_checksum = paint_mask_checksum
	)
	_assert_true(controller.begin_aiming(), "production stage must enter aiming")
	cannon.set_aim(0.0, 38.0, 68.0)
	_assert_true(cannon.request_fire(), "production cannon must accept a predicted fire command")
	var active := manager.active_projectiles()
	_assert_true(active.size() == 1, "accepted fire must spawn exactly one projectile")
	if not active.is_empty():
		_assert_true(active[0].spawn_ordinal == 0, "shot parent must receive stable spawn ordinal zero")
	var frame_budget := 60 * 24
	while manager.active_count() > 0 and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	await physics_frame
	await physics_frame
	paint_system.flush_pending()
	_assert_true(manager.active_count() == 0, "painted projectile must terminate without an orphan")
	_assert_true(manager.pending_intent_count() == 0, "projectile termination must leave no uncanonicalized paint intent")
	_assert_true(observed.applied_count > 0, "physical target contacts must apply typed paint commands")
	_assert_true(observed.impact_count > 0, "first target contact must emit an impact mark")
	_assert_true(observed.sweep_count > 0, "sustained target contact must emit continuous surface sweeps")
	_assert_true(observed.stop_reason != &"", "projectile termination must publish a bounded stop reason")
	if observed.stop_reason == &"settled":
		_assert_true(observed.settle_count == 1, "target-top settlement must emit exactly one settle mark")
	for radius in observed.impact_radii:
		_assert_true(is_equal_approx(radius, cannon.projectile_data.impact_paint_radius), "impact radius must remain fixed for the whole shot")
	for radius in observed.sweep_radii:
		_assert_true(is_equal_approx(radius, cannon.projectile_data.paint_footprint_radius), "parent sweep footprint must remain fixed for the whole shot")
	_assert_true(observed.last_drained_tick >= 0, "paint commands must cross the late fixed-physics drain boundary")
	_assert_true(observed.paint_checksum == paint_system.paint_mask_checksum(), "drained checksum must match PaintSystem authority")
	_assert_true(observed.written_pixels > 0 and observed.newly_painted_pixels > 0, "typed commands must write and cross the authoritative threshold")
	_assert_true(paint_system.coverage_percent() > 0.0, "projectile commands must increase authoritative coverage")
	_assert_true(paint_system.persistent_nontarget_pixel_count() == 0, "persistent paint must never enter non-target pixels")
	if not _failed:
		print(
			"Phase 3 projectile-paint integration passed: %d applied, %d impact, %d sweep, %d settle, %.4f%% coverage." % [
				observed.applied_count,
				observed.impact_count,
				observed.sweep_count,
				observed.settle_count,
				paint_system.coverage_percent(),
			]
		)
	Engine.time_scale = 1.0
	game_state.persistence_enabled = true
	gameplay.queue_free()
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
