extends SceneTree

const BACKSTOP_SCENE := preload("res://scenes/gameplay/backstop_environment.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const TERRAIN_FIXTURE_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const NORMAL_TERRAIN_PHYSICS_MATERIAL := preload(
	"res://resources/physics/normal_terrain_physics_material.tres"
)
const LOCKED_AIMS := [
	Vector3(0.0, 46.0, 100.0),
	Vector3(-28.0, 42.0, 100.0),
	Vector3(28.0, 42.0, 100.0),
	Vector3(80.0, 10.0, 100.0),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	var host := Node3D.new()
	root.add_child(host)
	var spec := ContainmentSpec.new()
	var backstop := BACKSTOP_SCENE.instantiate() as BackstopEnvironment
	host.add_child(backstop)
	backstop.configure(
		spec,
		Rect2(Vector2(-90.0, -172.0), Vector2(180.0, 120.0)),
		ContainmentSpec.FIXED_APRON_MINIMUM_Y
	)
	_assert_true(
		(backstop.get_node("ApronBody") as StaticBody3D).physics_material_override \
				== NORMAL_TERRAIN_PHYSICS_MATERIAL,
		"the apron must use the shared normal-terrain PhysicsMaterial"
	)
	var terrain := TERRAIN_FIXTURE_SCENE.instantiate() as TerrainSurface
	terrain.position = Vector3(0.0, -200.0, -112.0)
	host.add_child(terrain)
	terrain.configure(TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT))
	var cannon := CANNON_SCENE.instantiate() as CannonController
	cannon.position = Vector3(0.0, 0.0, 5.0)
	host.add_child(cannon)
	var manager := ProjectileManager.new()
	manager.stage_bounds = spec.containment_bounds
	host.add_child(manager)
	manager.configure_terrain(terrain)
	await physics_frame
	await physics_frame
	for aim in LOCKED_AIMS:
		await _assert_wall_launch(host, cannon, manager, spec, aim)
	manager.cleanup()
	host.queue_free()
	await physics_frame
	if not _failed:
		print("Containment checks passed: four locked aims terminated on the closed apron/backstop/side-wall boundary without paint commands or escape.")
	quit(1 if _failed else 0)


func _assert_wall_launch(
		host: Node3D,
		cannon: CannonController,
		manager: ProjectileManager,
		spec: ContainmentSpec,
		aim: Vector3
) -> void:
	var origin := cannon.get_launch_origin_for(aim.x, aim.y)
	var velocity := CannonBallistics.launch_velocity(PROJECTILE_DATA, aim.x, aim.y, aim.z)
	var prediction := TrajectoryPredictor.predict_motion(
		host.get_world_3d().direct_space_state,
		origin,
		velocity,
		PROJECTILE_DATA.radius,
		PROJECTILE_DATA.linear_damp,
		spec.containment_bounds
	)
	_assert_true(prediction.kind == TrajectoryPrediction.Kind.COLLISION, "%s predictor must collide" % aim)
	_assert_true(prediction.hit_identity != null, "%s predictor must expose a containment identity" % aim)
	var predicted_backstop := _is_backstop_identity(prediction.hit_identity)
	var predicted_apron := _is_apron_identity(prediction.hit_identity)
	var predicted_side_wall := _is_side_wall_identity(prediction.hit_identity)
	_assert_true(
		predicted_backstop or predicted_apron or predicted_side_wall,
		"%s predictor must first identify the closed containment boundary" % aim
	)
	var observed := {
		"contacts": [],
		"commands": 0,
		"reason": &"",
		"contact_tick": -1,
		"stop_tick": -1,
		"linear_at_stop": Vector3.INF,
		"angular_at_stop": Vector3.INF,
	}
	var launch_data := PROJECTILE_DATA.duplicate() as ProjectileData
	launch_data.never_contacted_timeout = 10.0
	var projectile := manager.spawn_projectile(launch_data, origin, velocity)
	_assert_true(projectile != null, "%s wall fixture must spawn" % aim)
	var contact_callback := func(reported_projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if reported_projectile != projectile:
			return
		observed.contacts.append(contact)
		observed.contact_tick = contact.physics_tick
	var radial_callback := func(_command: RadialPaintMark) -> void: observed.commands += 1
	var sweep_callback := func(_command: SurfacePaintSweep) -> void: observed.commands += 1
	var stopped_callback := func(stopped_projectile: PaintProjectile, reason: StringName) -> void:
		if stopped_projectile != projectile:
			return
		observed.reason = reason
		observed.stop_tick = Engine.get_physics_frames()
		observed.linear_at_stop = stopped_projectile.linear_velocity
		observed.angular_at_stop = stopped_projectile.angular_velocity
	manager.projectile_contact_reported.connect(contact_callback)
	manager.radial_paint_mark_ready.connect(radial_callback)
	manager.surface_paint_sweep_ready.connect(sweep_callback)
	manager.projectile_stopped.connect(stopped_callback)
	var budget := 720
	while observed.reason == &"" and budget > 0:
		await physics_frame
		budget -= 1
	var observed_backstop: bool = observed.contacts.size() == 1 and _is_backstop_contact(observed.contacts[0])
	var observed_apron: bool = observed.contacts.size() == 1 and _is_apron_contact(observed.contacts[0])
	var observed_side_wall: bool = observed.contacts.size() == 1 and _is_side_wall_contact(observed.contacts[0])
	_assert_true(observed_backstop or observed_apron or observed_side_wall, "%s runtime must report a closed containment contact" % aim)
	_assert_true(
		(observed_backstop and observed.reason == ProjectileSettlementReason.BACKSTOP) \
				or (observed_side_wall and observed.reason == ProjectileSettlementReason.BACKSTOP) \
				or (observed_apron and observed.reason == ProjectileSettlementReason.MISSED_TERRAIN),
		"%s must use the matching containment settlement reason" % aim
	)
	_assert_true(observed.contacts.size() == 1, "%s must report exactly one begun wall contact" % aim)
	if observed.contacts.size() == 1:
		var contact: ProjectileContact = observed.contacts[0]
		_assert_true(
			_is_backstop_contact(contact) or _is_apron_contact(contact) or _is_side_wall_contact(contact),
			"%s runtime shape must be a closed containment shape" % aim
		)
		_assert_true(not contact.impulse_was_measured, "%s speculative CCD wall contact must retain estimated-impulse provenance" % aim)
		_assert_true(contact.impulse.length() > 0.0, "%s wall contact must preserve its deterministic fallback impulse" % aim)
		if _is_backstop_contact(contact):
			_assert_true(contact.normal.dot(Vector3.BACK) >= cos(deg_to_rad(1.0)), "%s wall normal must be within one degree of +Z" % aim)
		elif _is_side_wall_contact(contact):
			_assert_true(absf(contact.normal.x) >= cos(deg_to_rad(1.0)), "%s side-wall normal must be within one degree of horizontal X" % aim)
		else:
			_assert_true(contact.normal.dot(Vector3.UP) >= cos(deg_to_rad(1.0)), "%s apron normal must be within one degree of +Y" % aim)
		_assert_true(contact.world_position.distance_to(prediction.endpoint) <= 0.25, "%s predictor/runtime wall points must agree within 0.25 m" % aim)
	_assert_true(observed.commands == 0, "%s containment boundary must emit no paint command" % aim)
	_assert_true(
		(observed_backstop and observed.stop_tick == observed.contact_tick) \
				or (observed_side_wall and observed.stop_tick == observed.contact_tick) \
				or (observed_apron and observed.stop_tick >= observed.contact_tick),
		"%s must stop no later than the contact tick for a wall or after roll-down for an apron" % aim
	)
	_assert_true(observed.linear_at_stop == Vector3.ZERO and observed.angular_at_stop == Vector3.ZERO, "%s must zero linear and angular velocity in the contact tick" % aim)
	await physics_frame
	_assert_true(manager.active_count() == 0, "%s must have no active projectile on the next physics tick" % aim)
	if manager.projectile_contact_reported.is_connected(contact_callback):
		manager.projectile_contact_reported.disconnect(contact_callback)
	if manager.radial_paint_mark_ready.is_connected(radial_callback):
		manager.radial_paint_mark_ready.disconnect(radial_callback)
	if manager.surface_paint_sweep_ready.is_connected(sweep_callback):
		manager.surface_paint_sweep_ready.disconnect(sweep_callback)
	if manager.projectile_stopped.is_connected(stopped_callback):
		manager.projectile_stopped.disconnect(stopped_callback)


func _is_backstop_identity(identity: TrajectoryHitIdentity) -> bool:
	return identity != null \
			and identity.contact_owner_id == ContainmentSpec.BACKSTOP_OWNER_ID \
			and identity.contact_shape_id == ContainmentSpec.BACKSTOP_SHAPE_ID


func _is_apron_identity(identity: TrajectoryHitIdentity) -> bool:
	return identity != null \
			and identity.contact_owner_id == ContainmentSpec.APRON_OWNER_ID \
			and identity.contact_shape_id == ContainmentSpec.APRON_SHAPE_ID


func _is_side_wall_identity(identity: TrajectoryHitIdentity) -> bool:
	return identity != null and ContainmentSpec.is_side_wall_contact(
		identity.contact_owner_id,
		identity.contact_shape_id
	)


func _is_backstop_contact(contact: ProjectileContact) -> bool:
	return contact != null \
			and contact.contact_owner_id == ContainmentSpec.BACKSTOP_OWNER_ID \
			and contact.contact_shape_id == ContainmentSpec.BACKSTOP_SHAPE_ID


func _is_apron_contact(contact: ProjectileContact) -> bool:
	return contact != null \
			and contact.contact_owner_id == ContainmentSpec.APRON_OWNER_ID \
			and contact.contact_shape_id == ContainmentSpec.APRON_SHAPE_ID


func _is_side_wall_contact(contact: ProjectileContact) -> bool:
	return contact != null and ContainmentSpec.is_side_wall_contact(
		contact.contact_owner_id,
		contact.contact_shape_id
	)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Containment wall check failed: %s" % message)
