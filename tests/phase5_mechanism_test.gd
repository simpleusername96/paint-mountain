extends SceneTree

const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const BURST_DATA := preload("res://resources/mechanisms/burst_node.tres")
const SPLITTER_DATA := preload("res://resources/mechanisms/splitter_node.tres")
const BUMPER_DATA := preload("res://resources/mechanisms/bumper_node.tres")
const STAGE := preload("res://resources/stages/first_descent.tres")
const PAINT_SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")
const TERRAIN_FIXTURE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const BURST_SCENE := preload("res://scenes/mechanisms/burst_node.tscn")
const SPLITTER_SCENE := preload("res://scenes/mechanisms/splitter_node.tscn")
const BUMPER_SCENE := preload("res://scenes/mechanisms/bumper_node.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	var test_root := Node3D.new()
	root.add_child(test_root)
	var terrain := TERRAIN_FIXTURE.instantiate() as TerrainSurface
	test_root.add_child(terrain)
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	var target_mask := PackedByteArray()
	target_mask.resize(PaintSystem.MASK_SIZE * PaintSystem.MASK_SIZE)
	target_mask.fill(255)
	var target_checksum := TargetMaskRasterizer.byte_checksum(target_mask)
	_assert_true(layout.install_target_mask(target_mask, target_checksum), "mechanism fixture target mask must install exactly once")
	layout.checksum = 0x12345678
	# Runtime admission uses the bounded generated aim; formal reachability
	# certificates are optional QA metadata and must not gate this physics fixture.
	layout.generated_default_aim = AimTuple.new(0.0, 38.0, 68)
	_assert_true(layout.is_runtime_ready(), "mechanism fixture layout must satisfy runtime readiness")
	terrain.configure(layout)
	var manager := ProjectileManager.new()
	test_root.add_child(manager)
	manager.configure_terrain(terrain)
	manager.stage_bounds = AABB(Vector3(-24, -12, -24), Vector3(48, 48, 48))
	var paint := PaintSystem.new()
	test_root.add_child(paint)
	paint.configure(
		layout.local_bounds, 0.0, null, Color(0.03, 0.38, 1.0), layout,
		PAINT_SURFACE_TUNING
	)
	var top_body := terrain.get_node("TerrainTopBody") as StaticBody3D
	paint.configure_top_surface_identity(
		top_body.get_rid(),
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID,
		0
	)
	manager.radial_paint_mark_ready.connect(paint.queue_radial_paint_mark)
	manager.surface_paint_sweep_ready.connect(paint.queue_surface_paint_sweep)

	var burst := _add_mechanism(BURST_SCENE, BURST_DATA, Vector3(-8, 0, -6), manager, paint) as BurstNode
	var splitter := _add_mechanism(SPLITTER_SCENE, SPLITTER_DATA, Vector3.ZERO, manager, paint) as SplitterNode
	splitter.configure_route_targets(PackedVector3Array([
		Vector3(-7, 0, -12), Vector3(0, 0, -13), Vector3(7, 0, -12),
	]), Vector3(0, 0, -1))
	var bumper := _add_mechanism(BUMPER_SCENE, BUMPER_DATA, Vector3(8, 0, -6), manager, paint) as BumperNode
	bumper.configure_downstream_tangent(Vector3(0, 0, -1))

	_assert_scene_contract(burst, {
		"BurstBase": ["CylinderShape3D", 1.8, 0.7, "Pedestal"],
		"BurstOrb": ["SphereShape3D", 1.05, 0.0, "Core"],
	}, &"BurstBase", 4.2)
	_assert_scene_contract(splitter, {
		"SplitterBase": ["CylinderShape3D", 1.75, 0.65, "Base"],
		"SplitterCenter": ["SphereShape3D", 0.58, 0.0, "Jewel"],
		"SplitterOutletLeft": ["CapsuleShape3D", 0.24, 2.5, "LeftOutlet"],
		"SplitterOutletCenter": ["CapsuleShape3D", 0.24, 2.5, "CenterOutlet"],
		"SplitterOutletRight": ["CapsuleShape3D", 0.24, 2.5, "RightOutlet"],
	}, &"SplitterBase", 5.0)
	_assert_scene_contract(bumper, {
		"BumperBase": ["CylinderShape3D", 1.9, 0.65, "Base"],
		"BumperUpper": ["CylinderShape3D", 1.3, 0.5, "Pad"],
	}, &"BumperBase", 5.2)

	var controller := StageController.new()
	test_root.add_child(controller)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	test_root.add_child(cannon)
	controller.configure(STAGE, layout, cannon, manager, paint, terrain, [burst, splitter, bumper])
	var observation := ShotObservation.new()
	observation.configure(1, 0.0, 38.0, 68.0, 0.0)
	controller._shot_observation = observation

	var burst_marks := {"count": 0, "command": null}
	paint.paint_command_applied.connect(func(command, _written: int, _newly: int) -> void:
		if command is RadialPaintMark and command.kind == RadialPaintMark.Kind.BURST:
			burst_marks.count += 1
			burst_marks.command = command
	)
	var burst_hit := await _fire_for_contact(
		manager, burst, Vector3(-8, 3.0, 4), Vector3(0, 0, -40), 1
	)
	await physics_frame
	await physics_frame
	_assert_contact_matches_preview(burst_hit, burst)
	_assert_true(burst_hit.contact != null and burst_hit.contact.collider_shape_index == 1, "Burst orb shot must identify its orb shape")
	_assert_true(burst_hit.contact != null and burst_hit.contact.source_event_index >= 0, "Burst activation must retain the stable current-contact event index")
	_assert_true(
		burst_marks.count == 1 and paint.coverage_percent() > 0.0,
		"Burst must write exactly one typed mark through PaintSystem; count=%d coverage=%.4f" \
				% [burst_marks.count, paint.coverage_percent()]
	)
	var burst_command: RadialPaintMark = burst_marks.command
	if burst_command != null:
		_assert_true(is_equal_approx(burst_command.radius, 14.0), "Burst mark radius must remain exactly 14 m")
		_assert_true(burst_command.spawn_ordinal == burst_hit.projectile.spawn_ordinal, "Burst mark must inherit the activating projectile ordinal")
		_assert_true(burst_command.source_event_index == burst_hit.contact.source_event_index, "Burst mark must inherit the activating contact event index")
	_assert_true(burst.is_spent(), "Burst must spend its single charge")
	_assert_true(not burst.struck(burst_hit.projectile, burst_hit.contact), "one physical contact must not double-activate Burst")
	manager.cleanup()
	await physics_frame

	var split_settlements := {"count": 0}
	manager.all_projectiles_settled.connect(func() -> void:
		split_settlements.count += 1
	)
	var split_hit := await _fire_for_contact(
		manager, splitter, Vector3(0, 8, 0), Vector3(0, -40, 0), 1
	)
	_assert_contact_matches_preview(split_hit, splitter)
	_assert_true(split_hit.contact != null and split_hit.contact.collider_shape_index == 1, "Splitter side shot must identify its center sphere")
	var children := manager.active_projectiles()
	_assert_true(children.size() == 3, "Splitter must remove one parent and emit exactly three children")
	var child_ordinals := PackedInt32Array()
	for child in children:
		child_ordinals.append(child.spawn_ordinal)
		_assert_true(child.split_generation == 1, "Splitter children must stop at generation one")
		_assert_true(absf(child.physical_radius() - PROJECTILE_DATA.radius * 0.78) <= 0.0001, "Splitter child physical radius must be 0.78x")
		_assert_true(absf(child.paint_radius_multiplier() - 0.78) <= 0.0001, "Splitter child paint radius must be 0.78x")
	_assert_true(child_ordinals == PackedInt32Array([1, 2, 3]), "Splitter children must receive stable creation-order ordinals")
	_assert_true(not splitter.struck(children[0], split_hit.contact), "generation-one child cannot split recursively")
	await process_frame
	_assert_true(split_settlements.count == 0, "Splitter replacement must not settle while its children remain active")
	manager.cleanup()
	_assert_true(split_settlements.count == 1, "cleanup must settle the active Splitter children exactly once")
	await physics_frame

	var bumper_activations := {"count": 0}
	bumper.mechanism_activated.connect(func(_mechanism: GimmickBase, _projectile: PaintProjectile, _kind: MechanismData.Kind) -> void:
		bumper_activations.count += 1
	)
	var bumper_hit := await _fire_for_contact(
		manager, bumper, Vector3(8, 8, -6), Vector3(0, -30, 0), 1
	)
	_assert_contact_matches_preview(bumper_hit, bumper)
	_assert_true(bumper_hit.contact != null and bumper_hit.contact.collider_shape_index == 1, "Bumper shot must identify its upper cylinder")
	var expected_speed := clampf(maxf(bumper_hit.contact.incoming_velocity.length() * 0.85, 18.0), 18.0, 32.0)
	var expected_velocity := (bumper.displayed_downstream_tangent() + Vector3.UP * 0.22).normalized() * expected_speed
	await physics_frame
	await physics_frame
	if is_instance_valid(bumper_hit.projectile):
		_assert_true(bumper_hit.projectile.linear_velocity.distance_to(expected_velocity) <= 1.0, "Bumper queued impulse must match its displayed tangent")
	_assert_true(not bumper.struck(bumper_hit.projectile, bumper_hit.contact), "one Bumper contact must not double-activate")
	manager.cleanup()
	for _cooldown_frame in range(55):
		await physics_frame
	var second_bumper_hit := await _fire_for_contact(
		manager, bumper, Vector3(8, 8, -6), Vector3(0, -30, 0), 1
	)
	_assert_true(second_bumper_hit.contact != null and bumper_activations.count == 2, "a separated later Bumper strike must activate again")
	manager.cleanup()
	await physics_frame

	for dummy_index in range(ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES):
		var dummy := manager.spawn_projectile(PROJECTILE_DATA, Vector3(-14 + dummy_index * 0.5, 12, 12), Vector3.ZERO)
		_assert_true(dummy != null, "manager must fill each slot through the eighth projectile")
	_assert_true(manager.active_count() == 8, "active projectile count must reach but never exceed eight")
	_assert_true(manager.spawn_projectile(PROJECTILE_DATA, Vector3.ZERO, Vector3.ZERO) == null, "ninth projectile must be rejected")

	burst.reset_state()
	splitter.reset_state()
	bumper.reset_state()
	_assert_true(not burst.is_spent() and burst.remaining_charges == 1, "reset must restore Burst charge")
	_assert_true(is_zero_approx(splitter.cooldown_remaining) and is_zero_approx(bumper.cooldown_remaining), "reset must clear mechanism cooldowns")
	observation.seal(
		paint.coverage_percent(),
		paint.last_drained_physics_tick(),
		paint.paint_mask_checksum()
	)
	_assert_true(observation.is_sealed, "mechanism facts must remain in the sealed shot observation")
	_assert_true(observation.mechanism_activation_kinds.size() == 4, "each real activation must appear exactly once in ShotObservation")
	_assert_true(observation.spawned_child_count == 3, "ShotObservation must record exactly three spawned children")
	_assert_true(observation.peak_active_projectile_count <= 8, "ShotObservation must retain the global active-ball cap")

	if not _failed:
		print("Phase 5 physical mechanisms passed: exact compound shapes, preview/contact parity, Burst 1, Splitter 3, Bumper 2, cap 8.")
	manager.cleanup()
	test_root.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _add_mechanism(
		scene: PackedScene,
		data: MechanismData,
		position: Vector3,
		manager: ProjectileManager,
		paint: PaintSystem
) -> GimmickBase:
	var mechanism := scene.instantiate() as GimmickBase
	mechanism.data = data
	mechanism.position = position
	mechanism.configure(manager, paint)
	manager.get_parent().add_child(mechanism)
	return mechanism


func _fire_for_contact(
		manager: ProjectileManager,
		mechanism: GimmickBase,
		start: Vector3,
		velocity: Vector3,
		expected_shape_index: int
) -> Dictionary:
	var preview := await _preview_cast(start, velocity)
	_assert_true(preview.get("collider") == mechanism.mechanism_body(), "preview must hit the mechanism gameplay body")
	_assert_true(int(preview.get("shape", -1)) == expected_shape_index, "preview must identify the intended mechanism shape")
	var observed := {"contact": null, "projectile": null, "preview": preview}
	var callback := func(projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if contact.collider == mechanism.mechanism_body() and observed.contact == null:
			observed.contact = contact
			observed.projectile = projectile
	manager.projectile_contact_reported.connect(callback)
	var projectile := manager.spawn_projectile(PROJECTILE_DATA, start, velocity)
	_assert_true(projectile != null, "mechanism fixture must spawn a projectile")
	var frame_budget := 120
	while observed.contact == null and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	if manager.projectile_contact_reported.is_connected(callback):
		manager.projectile_contact_reported.disconnect(callback)
	_assert_true(observed.contact != null, "real projectile must report a mechanism contact")
	return observed


func _preview_cast(start: Vector3, velocity: Vector3) -> Dictionary:
	var sphere := SphereShape3D.new()
	sphere.radius = PROJECTILE_DATA.radius
	var space := root.get_world_3d().direct_space_state
	var samples := CannonBallistics.sample_unobstructed(
		start, velocity, Vector3.DOWN * 9.8, 1.0 / 60.0, 1.0, PROJECTILE_DATA.linear_damp
	)
	for sample_index in range(1, samples.size()):
		var previous := samples[sample_index - 1]
		var motion := samples[sample_index] - previous
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = sphere
		query.transform = Transform3D(Basis.IDENTITY, previous)
		query.motion = motion
		query.collision_mask = 4
		query.collide_with_bodies = true
		query.collide_with_areas = false
		var fractions := space.cast_motion(query)
		if fractions.is_empty() or float(fractions[0]) >= 1.0:
			continue
		var safe_fraction := minf(float(fractions[1]) + 0.002, 1.0)
		query.transform.origin = previous + motion * safe_fraction
		var hits := space.intersect_shape(query, 8)
		if hits.is_empty():
			return {}
		var hit: Dictionary = hits[0]
		hit["center"] = previous + motion * float(fractions[0])
		return hit
	return {}


func _assert_contact_matches_preview(result: Dictionary, mechanism: GimmickBase) -> void:
	var contact: ProjectileContact = result.contact
	var preview: Dictionary = result.preview
	_assert_true(contact != null and contact.collider == mechanism.mechanism_body(), "ball and preview must report the same mechanism body")
	if contact != null and not preview.is_empty():
		_assert_true(contact.collider_shape_index == int(preview.shape), "ball and preview must report the same mechanism shape")
		_assert_true(
			contact.impact_center_position.distance_to(Vector3(preview.center)) <= 0.80,
			"ball and preview centers must agree within the 0.80 m projectile-scale envelope"
		)


func _assert_scene_contract(
		mechanism: GimmickBase,
		expected: Dictionary,
		envelope_shape_name: StringName,
		authored_visual_diameter: float
) -> void:
	_assert_true(mechanism.get_class() == "Node3D", "%s root must be Node3D, never Area3D" % mechanism.name)
	var visual_root := mechanism.get_node("Visual") as Node3D
	var body := mechanism.mechanism_body()
	var selection := mechanism.selection_body()
	_assert_true(
		body.get_meta(ContainmentSpec.CONTACT_OWNER_META, &"")
				== GimmickBase.contact_owner_id_for_kind(mechanism.data.kind),
		"%s gameplay body must expose its stable mechanism owner ID" % mechanism.name
	)
	var effective_scale := Vector3(2.0, 2.0, 2.0)
	_assert_true(
		visual_root.scale.is_equal_approx(effective_scale)
				and body.scale.is_equal_approx(effective_scale)
				and selection.scale.is_equal_approx(effective_scale),
		"%s visible, gameplay, and selection branches must share the frozen 2x scale" % mechanism.name
	)
	_assert_true(body.collision_layer == 4 and body.collision_mask == 2, "%s gameplay body must use only layer 3 against projectiles" % mechanism.name)
	_assert_true(selection.collision_layer == 8 and selection.collision_mask == 0, "%s selection body must use only layer 4" % mechanism.name)
	_assert_true(body.get_child_count() == expected.size(), "%s must contain every frozen gameplay shape" % mechanism.name)
	_assert_true(selection.get_child_count() == expected.size(), "%s selection geometry must mirror its visible physical silhouette" % mechanism.name)
	var envelope_shape := body.get_node(String(envelope_shape_name)) as CollisionShape3D
	var local_envelope_radius := float(expected[String(envelope_shape_name)][1])
	var world_collision_radius := local_envelope_radius \
			* envelope_shape.global_transform.basis.get_scale().x
	var world_visual_diameter := authored_visual_diameter \
			* visual_root.global_transform.basis.get_scale().x
	_assert_true(
		is_equal_approx(
			world_collision_radius,
			MechanismPlacementGenerator.effective_collision_radius(mechanism.data.kind)
		),
		"%s placement radius must match its effective world collision envelope" % mechanism.name
	)
	_assert_true(
		is_equal_approx(
			world_visual_diameter,
			MechanismPlacementGenerator.effective_visual_diameter(mechanism.data.kind)
		),
		"%s placement visibility must match its effective world visual diameter" % mechanism.name
	)
	for shape_name in expected:
		var values: Array = expected[shape_name]
		var collision := body.get_node(String(shape_name)) as CollisionShape3D
		var selection_collision := selection.get_node(String(shape_name)) as CollisionShape3D
		var visual := mechanism.get_node("Visual/%s" % values[3]) as MeshInstance3D
		_assert_true(collision != null and selection_collision != null and visual != null, "%s must map collision %s to matching selection and visual geometry" % [mechanism.name, shape_name])
		if collision == null or selection_collision == null or visual == null:
			continue
		_assert_true(
			collision.get_meta(ContainmentSpec.CONTACT_SHAPE_META, &"")
					== GimmickBase.contact_shape_id_for_kind(
						mechanism.data.kind, collision.name
					),
			"%s gameplay shape must expose its stable mechanism shape ID" % shape_name
		)
		_assert_true(collision.shape.is_class(String(values[0])), "%s must use its frozen primitive type" % shape_name)
		if collision.shape is SphereShape3D:
			_assert_true(absf(collision.shape.radius - float(values[1])) <= 0.0001, "%s radius must match" % shape_name)
		elif collision.shape is CylinderShape3D:
			_assert_true(absf(collision.shape.radius - float(values[1])) <= 0.0001 and absf(collision.shape.height - float(values[2])) <= 0.0001, "%s cylinder dimensions must match" % shape_name)
		elif collision.shape is CapsuleShape3D:
			_assert_true(absf(collision.shape.radius - float(values[1])) <= 0.0001 and absf(collision.shape.height - float(values[2])) <= 0.0001, "%s capsule dimensions must match" % shape_name)
		var collision_aabb := collision.global_transform * collision.shape.get_debug_mesh().get_aabb()
		var selection_aabb := selection_collision.global_transform \
				* selection_collision.shape.get_debug_mesh().get_aabb()
		var world_tolerance := 0.10 * visual.global_transform.basis.get_scale().x
		var visual_aabb := (visual.global_transform * visual.mesh.get_aabb()).grow(world_tolerance)
		_assert_true(
			_aabb_is_equal_approx(collision_aabb, selection_aabb),
			"%s gameplay and selection AABBs must match in world space" % shape_name
		)
		_assert_true(_aabb_contains(visual_aabb, collision_aabb), "%s effective collision AABB must remain inside its effective visual AABB + %.2f m" % [shape_name, world_tolerance])


func _aabb_contains(outer: AABB, inner: AABB) -> bool:
	return outer.has_point(inner.position) and outer.has_point(inner.end)


func _aabb_is_equal_approx(a: AABB, b: AABB) -> bool:
	return a.position.is_equal_approx(b.position) and a.size.is_equal_approx(b.size)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Phase 5 mechanism check failed: %s" % message)
