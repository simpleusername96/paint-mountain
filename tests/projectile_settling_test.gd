extends SceneTree

const FIXTURE_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")
const NORMAL_TERRAIN_PHYSICS_MATERIAL := preload(
	"res://resources/physics/normal_terrain_physics_material.tres"
)

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	_assert_production_tuning()
	await _assert_manager_canonical_ordering()
	await _assert_bounded_rebound_and_recovery(false)
	await _assert_bounded_rebound_and_recovery(true)
	await _assert_gap_proof()
	await _assert_settle_command()
	if not _failed:
		print("Projectile settling checks passed: low rebound, flat/ramp recovery, exact gap proof, and ordered impact/sweep/settle intent.")
	quit(1 if _failed else 0)


func _assert_production_tuning() -> void:
	var default_data := ProjectileData.new()
	_assert_true(is_equal_approx(default_data.impact_paint_radius, 6.0), "default impact radius must be 6 m")
	_assert_true(is_equal_approx(PROJECTILE_DATA.radius, 0.52), "production radius must remain 0.52 m")
	_assert_true(is_equal_approx(PROJECTILE_DATA.mass, 2.4), "production mass must remain 2.4 kg")
	_assert_true(is_equal_approx(PROJECTILE_DATA.bounce, 0.08), "production bounce must be 0.08")
	_assert_true(is_equal_approx(PROJECTILE_DATA.friction, 0.78), "production friction must be 0.78")
	_assert_true(is_equal_approx(PROJECTILE_DATA.linear_damp, 0.18), "production linear damping must be 0.18")
	_assert_true(is_equal_approx(PROJECTILE_DATA.angular_damp, 0.35), "production angular damping must be 0.35")
	_assert_true(
		is_zero_approx(NORMAL_TERRAIN_PHYSICS_MATERIAL.bounce) \
				and is_equal_approx(NORMAL_TERRAIN_PHYSICS_MATERIAL.friction, 1.0),
		"normal terrain must stay restitution-neutral so ProjectileData alone owns rebound tuning"
	)
	_assert_true(is_equal_approx(PROJECTILE_DATA.paint_footprint_radius, 4.0), "parent sweep radius must be 4 m")
	_assert_true(is_equal_approx(PROJECTILE_DATA.impact_paint_radius, 6.0), "impact radius must be 6 m")
	_assert_true(is_equal_approx(PROJECTILE_DATA.settle_paint_radius, 4.0), "settle radius must be 4 m")


func _assert_manager_canonical_ordering() -> void:
	var fixture := await _build_fixture(false)
	var host: Node3D = fixture.host
	var surface: TerrainSurface = fixture.surface
	var manager: ProjectileManager = fixture.manager
	var body := surface.get_node("TerrainTopBody") as StaticBody3D
	var point := surface.world_surface_point(Vector2.ZERO)
	var tick := Engine.get_physics_frames()
	var emitted: Array[RefCounted] = []
	manager.radial_paint_mark_ready.connect(func(command: RadialPaintMark) -> void: emitted.append(command))
	manager.surface_paint_sweep_ready.connect(func(command: SurfacePaintSweep) -> void: emitted.append(command))
	var settle := RadialPaintMark.new(
		tick, 0, 0, -1, point, Vector3.UP, 4.0, body.get_rid(),
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID, TerrainSurface.TOP_SHAPE_ID,
		0, RadialPaintMark.Kind.SETTLE
	)
	var sweep := SurfacePaintSweep.new(
		tick, 0, 0, -1, point, point + Vector3.RIGHT, Vector3.UP, Vector3.UP,
		4.0, body.get_rid(), TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID, 0, false
	)
	var later_ordinal_impact := RadialPaintMark.new(
		tick, 1, 0, -1, point, Vector3.UP, 6.0, body.get_rid(),
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID, TerrainSurface.TOP_SHAPE_ID,
		0, RadialPaintMark.Kind.IMPACT
	)
	var impact := RadialPaintMark.new(
		tick, 0, 0, -1, point, Vector3.UP, 6.0, body.get_rid(),
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID, TerrainSurface.TOP_SHAPE_ID,
		0, RadialPaintMark.Kind.IMPACT
	)
	_assert_true(manager.submit_radial_paint_intent(settle), "valid settle intent must queue")
	_assert_true(manager.submit_surface_paint_intent(sweep), "valid sweep intent must queue")
	_assert_true(manager.submit_radial_paint_intent(later_ordinal_impact), "second ordinal intent must queue")
	_assert_true(manager.submit_radial_paint_intent(impact), "valid impact intent must queue")
	await physics_frame
	await physics_frame
	_assert_true(emitted.size() == 4, "manager must canonicalize all four typed intents")
	if emitted.size() == 4:
		var emitted_impact := emitted[0] as RadialPaintMark
		var emitted_sweep := emitted[1] as SurfacePaintSweep
		var emitted_settle := emitted[2] as RadialPaintMark
		var emitted_later := emitted[3] as RadialPaintMark
		_assert_true(emitted_impact != null and emitted_impact.kind == RadialPaintMark.Kind.IMPACT, "IMPACT must sort before SWEEP and SETTLE")
		_assert_true(emitted_sweep != null, "SWEEP must sort after IMPACT")
		_assert_true(emitted_settle != null and emitted_settle.kind == RadialPaintMark.Kind.SETTLE, "SETTLE must sort last for one source event")
		_assert_true(emitted_later != null and emitted_later.spawn_ordinal == 1, "higher spawn ordinal must sort after ordinal zero")
		_assert_true(
			emitted_impact != null and emitted_sweep != null \
					and emitted_settle != null and emitted_later != null \
					and emitted_impact.sequence == 0 and emitted_sweep.sequence == 1 \
					and emitted_settle.sequence == 2 and emitted_later.sequence == 0,
			"sequence must increase independently per spawn ordinal"
		)
	_assert_true(manager.pending_intent_count() == 0, "completed-tick intent buffer must drain")
	await _dispose_fixture(host, manager, surface)


func _assert_bounded_rebound_and_recovery(on_ramp: bool) -> void:
	var fixture := await _build_fixture(on_ramp)
	var host: Node3D = fixture.host
	var surface: TerrainSurface = fixture.surface
	var manager: ProjectileManager = fixture.manager
	var top_body := surface.get_node("TerrainTopBody") as StaticBody3D
	var shell_body := surface.get_node("TerrainShellBody") as StaticBody3D
	_assert_true(
		top_body.physics_material_override == NORMAL_TERRAIN_PHYSICS_MATERIAL \
				and shell_body.physics_material_override == NORMAL_TERRAIN_PHYSICS_MATERIAL,
		"terrain top and shell must use the shared normal-terrain PhysicsMaterial"
	)
	var commands: Array[RefCounted] = []
	manager.radial_paint_mark_ready.connect(func(command: RadialPaintMark) -> void: commands.append(command))
	manager.surface_paint_sweep_ready.connect(func(command: SurfacePaintSweep) -> void: commands.append(command))
	var observed := {"first_contact": null}
	manager.projectile_contact_reported.connect(func(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if observed.first_contact == null and contact.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
			observed.first_contact = contact
	)
	var local_start := Vector2(0.0, 0.0)
	var surface_y := surface.world_surface_point(local_start).y
	var projectile := manager.spawn_projectile(
		PROJECTILE_DATA,
		Vector3(local_start.x, surface_y + 6.0, local_start.y),
		Vector3(5.0, -30.0, 0.0)
	)
	_assert_true(projectile != null, "bounded-rebound fixture must spawn")
	var contact_budget := 120
	while observed.first_contact == null and contact_budget > 0:
		await physics_frame
		contact_budget -= 1
	var first_contact := observed.first_contact as ProjectileContact
	_assert_true(first_contact != null, "bounded-rebound fixture must contact target top")
	if first_contact == null:
		await _dispose_fixture(host, manager, surface)
		return
	var maximum_outgoing_normal_speed := 0.0
	var maximum_clearance := 0.0
	var recovered_with_sweep := false
	for _tick in range(45):
		await physics_frame
		if not is_instance_valid(projectile):
			break
		var world_xz := Vector2(projectile.global_position.x, projectile.global_position.z)
		var normal := surface.world_surface_normal(world_xz)
		maximum_outgoing_normal_speed = maxf(
			maximum_outgoing_normal_speed,
			projectile.linear_velocity.dot(normal)
		)
		maximum_clearance = maxf(
			maximum_clearance,
			projectile.global_position.y - surface.world_surface_point(world_xz).y \
					- projectile.physical_radius()
		)
		for command in commands:
			if command is SurfacePaintSweep:
				recovered_with_sweep = true
				break
		if recovered_with_sweep:
			break
	_assert_true(
		maximum_outgoing_normal_speed <= first_contact.relative_normal_speed * 0.10 + 0.12,
		"first rebound normal speed must stay at or below 10%%; incoming=%.3f outgoing=%.3f" \
				% [first_contact.relative_normal_speed, maximum_outgoing_normal_speed]
	)
	_assert_true(maximum_clearance <= 1.5, "normal terrain must not create a second arc above 1.5 m")
	_assert_true(recovered_with_sweep, "%s must recover sustained target contact within 0.75 s" % ("30-degree ramp" if on_ramp else "flat"))
	_assert_true(not commands.is_empty() and commands[0] is RadialPaintMark, "first target command must be an impact mark")
	if not commands.is_empty() and commands[0] is RadialPaintMark:
		var impact := commands[0] as RadialPaintMark
		_assert_true(impact.kind == RadialPaintMark.Kind.IMPACT and impact.sequence == 0, "first impact must receive sequence zero")
		_assert_true(impact.spawn_ordinal == 0 and impact.center.distance_to(first_contact.world_position) <= 0.001, "impact must use ordinal zero and the measured contact point")
	if is_instance_valid(projectile):
		projectile.deactivate(&"bounded_rebound_complete")
	await _dispose_fixture(host, manager, surface)


func _assert_gap_proof() -> void:
	var fixture := await _build_fixture(false)
	var host: Node3D = fixture.host
	var surface: TerrainSurface = fixture.surface
	var manager: ProjectileManager = fixture.manager
	var top_body := surface.get_node("TerrainTopBody") as StaticBody3D
	var target_mask := surface.layout_read_only().target_mask
	var from_point := surface.world_surface_point(Vector2(-2.0, 0.0))
	var to_point := surface.world_surface_point(Vector2(2.0, 0.0))
	var from_contact := _fixture_contact(top_body, from_point, 10)
	var to_contact := _fixture_contact(top_body, to_point, 13)
	var space_state := host.get_world_3d().direct_space_state
	_assert_true(
		SurfaceContactGapValidator.can_bridge(
			surface, SURFACE_TUNING, target_mask, from_contact, to_contact, 2, space_state
		),
		"a same-top two-tick surface chord must pass the complete bridge proof"
	)
	var airborne_contact := _fixture_contact(top_body, to_point + Vector3.UP, 13)
	_assert_true(
		not SurfaceContactGapValidator.can_bridge(
			surface, SURFACE_TUNING, target_mask, from_contact, airborne_contact, 2, space_state
		),
		"a chord more than 0.4 m above the reconstructed surface must stay blank"
	)
	var long_gap_contact := _fixture_contact(top_body, to_point, 14)
	_assert_true(
		not SurfaceContactGapValidator.can_bridge(
			surface, SURFACE_TUNING, target_mask, from_contact, long_gap_contact, 3, space_state
		),
		"a three-tick missing-contact gap must stay blank"
	)
	await _dispose_fixture(host, manager, surface)


func _assert_settle_command() -> void:
	var fixture := await _build_fixture(false)
	var host: Node3D = fixture.host
	var surface: TerrainSurface = fixture.surface
	var manager: ProjectileManager = fixture.manager
	var data := PROJECTILE_DATA.duplicate() as ProjectileData
	data.minimum_movement_speed = 2.0
	data.stop_duration = 0.2
	var commands: Array[RefCounted] = []
	var observed := {"stop_reason": &""}
	manager.radial_paint_mark_ready.connect(func(command: RadialPaintMark) -> void: commands.append(command))
	manager.surface_paint_sweep_ready.connect(func(command: SurfacePaintSweep) -> void: commands.append(command))
	manager.projectile_contact_reported.connect(func(projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if contact.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
			projectile.linear_velocity = Vector3.ZERO
	)
	manager.projectile_stopped.connect(func(_projectile: PaintProjectile, reason: StringName) -> void: observed.stop_reason = reason)
	var surface_y := surface.world_surface_point(Vector2.ZERO).y
	manager.spawn_projectile(data, Vector3(0.0, surface_y + 2.0, 0.0), Vector3(0.0, -8.0, 0.0))
	var budget := 180
	while observed.stop_reason == &"" and budget > 0:
		await physics_frame
		budget -= 1
	for _tick in range(2):
		await physics_frame
	_assert_true(observed.stop_reason == &"settled", "low-speed fixture must settle on target top")
	var impact: RadialPaintMark
	var settle: RadialPaintMark
	for command in commands:
		var radial := command as RadialPaintMark
		if radial == null:
			continue
		if radial.kind == RadialPaintMark.Kind.IMPACT and impact == null:
			impact = radial
		elif radial.kind == RadialPaintMark.Kind.SETTLE:
			settle = radial
	_assert_true(impact != null and settle != null, "target settlement must emit impact and settle marks")
	if impact != null and settle != null:
		_assert_true(impact.sequence < settle.sequence, "settle must be sequenced after impact for the same ordinal")
		_assert_true(settle.spawn_ordinal == 0 and is_equal_approx(settle.radius, 4.0), "settle must preserve ordinal and fixed radius")
	await _dispose_fixture(host, manager, surface)


func _build_fixture(on_ramp: bool) -> Dictionary:
	var host := Node3D.new()
	root.add_child(host)
	var surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	host.add_child(surface)
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	if on_ramp:
		_apply_thirty_degree_ramp(layout)
	_install_full_target_mask(layout)
	surface.configure(layout)
	var manager := ProjectileManager.new()
	host.add_child(manager)
	manager.configure_terrain(surface, SURFACE_TUNING)
	await physics_frame
	await physics_frame
	return {"host": host, "surface": surface, "manager": manager}


func _apply_thirty_degree_ramp(layout: GeneratedStageLayout) -> void:
	var sample_size := layout.sample_size()
	for z_index in range(sample_size.y):
		for x_index in range(sample_size.x):
			var x := lerpf(
				layout.local_bounds.position.x,
				layout.local_bounds.end.x,
				float(x_index) / float(layout.cell_count.x)
			)
			layout.heights[z_index * sample_size.x + x_index] = tan(deg_to_rad(30.0)) \
					* (x - layout.local_bounds.position.x)
	layout.top_topology = TerrainTopTopology.build(layout.cell_count, layout.local_bounds, layout.heights)


func _install_full_target_mask(layout: GeneratedStageLayout) -> void:
	var target_mask := PackedByteArray()
	target_mask.resize(SURFACE_TUNING.mask_size * SURFACE_TUNING.mask_size)
	target_mask.fill(255)
	_assert_true(
		layout.install_target_mask(target_mask, TargetMaskRasterizer.byte_checksum(target_mask)),
		"fixture target mask must install once"
	)


func _fixture_contact(body: StaticBody3D, point: Vector3, tick: int) -> ProjectileContact:
	return ProjectileContact.new(
		point,
		Vector3.UP,
		point + Vector3.UP * PROJECTILE_DATA.radius,
		0.0,
		Vector3.ZERO,
		0.0,
		Vector3.ZERO,
		body,
		0,
		0,
		tick,
		false,
		false,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		body.get_rid()
	)


func _dispose_fixture(host: Node3D, manager: ProjectileManager, surface: TerrainSurface) -> void:
	if is_instance_valid(manager):
		manager.cleanup()
	if is_instance_valid(surface):
		surface.queue_free()
	if is_instance_valid(host):
		host.queue_free()
	await physics_frame


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Projectile settling check failed: %s" % message)
