extends SceneTree

const FIXTURE_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const REPEATS := 20

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	await _run_fixture_case(
		&"flat", TerrainTestFixtureFactory.Kind.FLAT,
		Vector3(0, 10, 0), Vector3(0, -100, 0), Vector3.UP
	)
	await _run_fixture_case(
		&"ramp", TerrainTestFixtureFactory.Kind.RAMP,
		Vector3(0, TerrainTestFixtureFactory.ramp_height(0.0) + 10.0, 0),
		Vector3(0, -100, 0), Vector3(-tan(deg_to_rad(35.0)), 1.0, 0.0).normalized()
	)
	await _run_fixture_case(
		&"graze", TerrainTestFixtureFactory.Kind.FLAT,
		Vector3(-10, 1, 0), Vector3(80, -20, 0), Vector3.UP
	)
	await _run_fixture_case(
		&"skirt", TerrainTestFixtureFactory.Kind.FLAT,
		Vector3(20, -4, 0), Vector3(-100, 0, 0), Vector3.RIGHT
	)
	await _assert_recontact_debounce()
	if not _failed:
		print("Projectile contact checks passed: 80/80 exact collider contacts plus separated recontact debounce at 60 Hz.")
	quit(1 if _failed else 0)


func _run_fixture_case(
		case_name: StringName,
		kind: TerrainTestFixtureFactory.Kind,
		start: Vector3,
		velocity: Vector3,
		expected_normal: Vector3
) -> void:
	var surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	root.add_child(surface)
	var layout := TerrainTestFixtureFactory.build_layout(kind)
	surface.configure(layout)
	var manager := ProjectileManager.new()
	root.add_child(manager)
	manager.configure_terrain(surface)
	await physics_frame
	await physics_frame
	for repeat_index in range(REPEATS):
		var result := await _fire_once(manager, start, velocity)
		_assert_true(result.has("contact"), "%s repeat %d must report a contact" % [case_name, repeat_index])
		if not result.has("contact"):
			continue
		var contact: ProjectileContact = result.contact
		var expected_collider := surface.get_node("TerrainShellBody") if case_name == &"skirt" else surface.get_node("TerrainTopBody")
		_assert_true(contact.collider == expected_collider, "%s must report exact collider identity" % case_name)
		_assert_true(contact.collider_instance_id == expected_collider.get_instance_id(), "%s collider ID must match object identity" % case_name)
		_assert_true(contact.collider_shape_index == 0 and contact.local_shape_index == 0, "%s must report exact shape indices" % case_name)
		_assert_true(contact.normal.dot(expected_normal) >= 0.98, "%s contact normal must match expected surface; expected=%s got=%s dot=%.4f" % [case_name, expected_normal, contact.normal, contact.normal.dot(expected_normal)])
		_assert_true(_surface_error(case_name, contact.world_position) <= 0.05, "%s contact point must lie within 0.05 m of its known surface" % case_name)
		_assert_true(contact.impulse.length() > 0.0, "%s contact must report a physical impulse; got %s" % [case_name, contact.impulse])
		_assert_true(contact.incoming_velocity.distance_to(velocity) <= 2.0, "%s first contact must preserve cached incoming velocity; expected %s, got %s" % [case_name, velocity, contact.incoming_velocity])
		_assert_true(contact.relative_normal_speed >= 7.5, "%s contact must report positive relative normal speed" % case_name)
		_assert_true(contact.is_first_contact, "%s first reported contact must be ordered first" % case_name)
		var center: Vector3 = contact.impact_center_position
		_assert_true(absf(center.distance_to(contact.world_position) - PROJECTILE_DATA.radius) <= 0.05, "%s center-to-contact distance must equal physical radius; center=%s point=%s distance=%.4f" % [case_name, center, contact.world_position, center.distance_to(contact.world_position)])
	manager.cleanup()
	manager.queue_free()
	surface.queue_free()
	await physics_frame


func _fire_once(manager: ProjectileManager, start: Vector3, velocity: Vector3) -> Dictionary:
	var observed: Dictionary = {}
	var callback := func(projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if not observed.is_empty():
			return
		observed["contact"] = contact
		projectile.deactivate(&"contact_test")
	manager.projectile_contact_reported.connect(callback)
	var projectile := manager.spawn_projectile(PROJECTILE_DATA, start, velocity)
	_assert_true(projectile != null, "contact fixture must spawn a projectile")
	var frame_budget := 120
	while observed.is_empty() and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	if manager.projectile_contact_reported.is_connected(callback):
		manager.projectile_contact_reported.disconnect(callback)
	if projectile != null and is_instance_valid(projectile):
		projectile.deactivate(&"contact_test_timeout")
	await physics_frame
	return observed


func _assert_recontact_debounce() -> void:
	var surface := FIXTURE_SCENE.instantiate() as TerrainSurface
	root.add_child(surface)
	surface.configure(TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT))
	var manager := ProjectileManager.new()
	root.add_child(manager)
	manager.configure_terrain(surface)
	var bouncing_data := PROJECTILE_DATA.duplicate() as ProjectileData
	bouncing_data.bounce = 0.82
	bouncing_data.minimum_movement_speed = 0.1
	bouncing_data.stop_duration = 4.0
	var ticks := PackedInt32Array()
	var first_flags: Array[bool] = []
	manager.projectile_contact_reported.connect(func(projectile: PaintProjectile, contact: ProjectileContact) -> void:
		ticks.append(contact.physics_tick)
		first_flags.append(contact.is_first_contact)
		if ticks.size() >= 2:
			projectile.deactivate(&"recontact_test_complete")
	)
	manager.spawn_projectile(bouncing_data, Vector3(0, 5, 0), Vector3(0, -30, 0))
	var frame_budget := 300
	while ticks.size() < 2 and manager.active_count() > 0 and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	_assert_true(ticks.size() >= 2, "a separated bounce must begin contact again")
	if ticks.size() >= 2:
		_assert_true(ticks[1] - ticks[0] >= 3, "recontact must require two fully absent ticks")
		_assert_true(first_flags[0] and not first_flags[1], "only the projectile's first contact may carry first-contact=true")
	manager.cleanup()
	manager.queue_free()
	surface.queue_free()
	await physics_frame


func _surface_error(case_name: StringName, point: Vector3) -> float:
	if case_name == &"ramp":
		var normal := Vector3(-tan(deg_to_rad(35.0)), 1.0, 0.0).normalized()
		return absf(normal.dot(point - Vector3(-15.0, 0.0, 0.0)))
	if case_name == &"skirt":
		return absf(point.x - 15.0)
	return absf(point.y)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Projectile contact check failed: %s" % message)
