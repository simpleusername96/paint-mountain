class_name PaintProjectile
extends RigidBody3D

signal contact_reported(projectile: PaintProjectile, contact: ProjectileContact)
signal radial_paint_mark_intent_requested(projectile: PaintProjectile, intent: RadialPaintMark)
signal surface_paint_sweep_intent_requested(projectile: PaintProjectile, intent: SurfacePaintSweep)
signal transient_splash_requested(projectile: PaintProjectile, contact: ProjectileContact)
signal stopped(projectile: PaintProjectile, reason: StringName)

const IMPACT_SPEED_THRESHOLD := 8.0
const RECONTACT_ABSENCE_TICKS := 2
const CONTACT_CONFIGURATION_ERROR := &"contact_configuration_error"

var projectile_data: ProjectileData
var split_generation: int = 0
var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))
var spawn_ordinal: int:
	get:
		return _spawn_ordinal

var _terrain_surface: TerrainSurface
var _paint_surface_tuning: PaintSurfaceTuning
var _target_mask := PackedByteArray()
var _spawn_ordinal: int = -1
var _elapsed: float = 0.0
var _slow_elapsed: float = 0.0
var _deactivated: bool = false
var _current_top_contact: ProjectileContact
var _current_target_top_contact: ProjectileContact
var _current_target_event_index: int = -1
var _interval_last_contact: ProjectileContact
var _interval_missing_ticks: int = 0
var _cached_incoming_velocity: Vector3 = Vector3.ZERO
var _contact_missing_ticks: Dictionary = {}
var _stable_identity_rids: Dictionary = {}
var _has_reported_contact: bool = false
var _penetration_ticks: int = 0
var _velocity_history: Array[Vector3] = []
var _queued_desired_velocity := Vector3.INF
var _queued_desired_velocity_tick: int = -1


func paint_radius_multiplier() -> float:
	return 0.78 if split_generation > 0 else 1.0


func physical_radius() -> float:
	return projectile_data.radius * (0.78 if split_generation > 0 else 1.0)


func configure(
		data: ProjectileData,
		bounds: AABB,
		terrain_surface: TerrainSurface,
		launch_velocity: Vector3,
		generation: int = 0,
		paint_surface_tuning: PaintSurfaceTuning = null,
		assigned_spawn_ordinal: int = -1
) -> void:
	projectile_data = data
	stage_bounds = bounds
	_terrain_surface = terrain_surface
	_paint_surface_tuning = paint_surface_tuning
	_spawn_ordinal = assigned_spawn_ordinal
	_cached_incoming_velocity = launch_velocity
	_velocity_history.assign([launch_velocity])
	split_generation = generation
	var layout := _terrain_surface.layout_read_only() if _terrain_surface != null else null
	if layout != null and layout.has_valid_target_mask():
		_target_mask = layout.target_mask


func _ready() -> void:
	assert(projectile_data != null, "PaintProjectile requires ProjectileData before entering the tree.")
	assert(_terrain_surface != null, "PaintProjectile requires the authoritative TerrainSurface.")
	assert(_paint_surface_tuning != null and _paint_surface_tuning.is_valid(), "PaintProjectile requires valid paint-surface tuning.")
	assert(_spawn_ordinal >= 0, "PaintProjectile requires a stable per-shot spawn ordinal.")
	mass = projectile_data.mass
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = projectile_data.linear_damp
	angular_damp = projectile_data.angular_damp
	gravity_scale = 1.0
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 16
	can_sleep = true
	collision_layer = 2
	collision_mask = 1 | 4
	_build_body()


func _physics_process(delta: float) -> void:
	if _deactivated:
		return
	_elapsed += delta
	if not stage_bounds.has_point(global_position):
		deactivate(&"out_of_bounds")
		return
	if _terrain_surface.contains_world_xz(Vector2(global_position.x, global_position.z)):
		var surface_y := _terrain_surface.world_surface_point(Vector2(global_position.x, global_position.z)).y
		_penetration_ticks = _penetration_ticks + 1 if global_position.y < surface_y - 3.0 else 0
	else:
		_penetration_ticks = 0
	if _penetration_ticks >= 2:
		deactivate(&"terrain_penetration_guard")
		return
	if _elapsed >= projectile_data.maximum_lifetime:
		deactivate(&"lifetime")
		return
	if sleeping:
		deactivate(&"settled")
		return
	if linear_velocity.length() <= projectile_data.minimum_movement_speed:
		_slow_elapsed += delta
		if _slow_elapsed >= projectile_data.stop_duration:
			deactivate(&"settled")
	else:
		_slow_elapsed = maxf(0.0, _slow_elapsed - delta * 0.35)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _deactivated:
		return
	var current_keys: Dictionary = {}
	var contacts_by_key: Dictionary = {}
	var identity_failure: StringName = &""
	var physics_tick := Engine.get_physics_frames()
	for index in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(index)
		var collider_shape := state.get_contact_collider_shape(index)
		var local_shape := state.get_contact_local_shape(index)
		var collider_rid := state.get_contact_collider(index)
		var identity := ProjectileContactIdentityResolver.resolve(collider, collider_shape)
		if not bool(identity.get("valid", false)):
			identity_failure = StringName(identity.get("reason", &"invalid_contact_identity"))
			break
		var stable_identity_key := "%s\u001f%s" % [
			String(identity.owner_id),
			String(identity.shape_id),
		]
		var collider_rid_id := collider_rid.get_id()
		if _stable_identity_rids.has(stable_identity_key) \
				and int(_stable_identity_rids[stable_identity_key]) != collider_rid_id:
			identity_failure = &"duplicate_stable_contact_identity"
			break
		_stable_identity_rids[stable_identity_key] = collider_rid_id
		var key := "%d:%d:%d" % [collider_rid.get_id(), collider_shape, local_shape]
		current_keys[key] = true
		var world_normal := state.get_contact_local_normal(index).normalized()
		var world_position := state.get_contact_collider_position(index)
		var collider_velocity := state.get_contact_collider_velocity_at_position(index)
		var incoming_velocity := _select_incoming_velocity(world_normal, collider_velocity)
		var relative_velocity := incoming_velocity - collider_velocity
		var relative_normal_speed := maxf(0.0, -relative_velocity.dot(world_normal))
		var impulse := state.get_contact_impulse(index)
		var impulse_was_measured := impulse.length_squared() >= 0.0001
		if not impulse_was_measured:
			impulse = Vector3.ZERO
		var contact := ProjectileContact.new(
			world_position,
			world_normal,
			state.transform.origin,
			absf(state.transform.origin.distance_to(world_position) - physical_radius()),
			incoming_velocity,
			relative_normal_speed,
			impulse,
			collider,
			local_shape,
			collider_shape,
			physics_tick,
			false,
			impulse_was_measured,
			StringName(identity.owner_id),
			StringName(identity.shape_id),
			collider_rid
		)
		var manifold_contacts: Array = contacts_by_key.get(key, [])
		manifold_contacts.append(contact)
		contacts_by_key[key] = manifold_contacts

	if not String(identity_failure).is_empty():
		push_error("PaintProjectile blocked an invalid gameplay contact identity: %s" % identity_failure)
		_deactivate_from_state(state, CONTACT_CONFIGURATION_ERROR)
		return

	var current_contacts: Array[ProjectileContact] = []
	var begun_contacts: Array[ProjectileContact] = []
	for key in contacts_by_key:
		var typed_manifold: Array[ProjectileContact] = []
		for contact: ProjectileContact in contacts_by_key[key]:
			typed_manifold.append(contact)
		var primary := _primary_contact(typed_manifold)
		current_contacts.append(primary)
		if not _contact_missing_ticks.has(key) \
				or int(_contact_missing_ticks[key]) >= RECONTACT_ABSENCE_TICKS:
			begun_contacts.append(primary)
		_contact_missing_ticks[key] = 0
	for key in _contact_missing_ticks.keys():
		if not current_keys.has(key):
			_contact_missing_ticks[key] = mini(
				int(_contact_missing_ticks[key]) + 1,
				RECONTACT_ABSENCE_TICKS
			)

	current_contacts.sort_custom(_stable_contact_less)
	begun_contacts.sort_custom(_stable_contact_less)
	for event_index in range(current_contacts.size()):
		current_contacts[event_index].assign_source_event_index(event_index)
	_current_top_contact = _first_top_contact(current_contacts)
	for contact in begun_contacts:
		if not contact.impulse_was_measured:
			var measured_normal_delta := maxf(
				0.0,
				(state.linear_velocity - contact.incoming_velocity).dot(contact.normal)
			)
			contact._impulse = contact.normal * measured_normal_delta * mass
		contact._is_first_contact = not _has_reported_contact
		_has_reported_contact = true
		contact_reported.emit(self, contact)
		if contact.relative_normal_speed >= IMPACT_SPEED_THRESHOLD:
			transient_splash_requested.emit(self, contact)

	if _contains_backstop_contact(current_contacts):
		_deactivate_from_state(state, ProjectileSettlementReason.BACKSTOP)
		return

	_update_target_contact_interval(current_contacts, state.get_space_state())
	if _queued_desired_velocity != Vector3.INF and physics_tick > _queued_desired_velocity_tick:
		state.apply_central_impulse(mass * (_queued_desired_velocity - state.linear_velocity))
		_queued_desired_velocity = Vector3.INF
		_queued_desired_velocity_tick = -1
	_cached_incoming_velocity = state.linear_velocity
	_velocity_history.append(state.linear_velocity)
	if _velocity_history.size() > 3:
		_velocity_history.pop_front()


func queue_desired_velocity(desired_velocity: Vector3, contact_tick: int) -> void:
	if desired_velocity.is_finite() and not desired_velocity.is_zero_approx():
		_queued_desired_velocity = desired_velocity
		_queued_desired_velocity_tick = contact_tick


func deactivate(reason: StringName) -> void:
	if _deactivated:
		return
	if reason == &"settled" and _current_target_top_contact != null:
		_emit_settle_intent(_current_target_top_contact, _current_target_event_index)
	_deactivated = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	stopped.emit(self, reason)
	queue_free()


func _update_target_contact_interval(
		current_contacts: Array[ProjectileContact],
		space_state: PhysicsDirectSpaceState3D
) -> void:
	_current_target_top_contact = null
	_current_target_event_index = -1
	for event_index in range(current_contacts.size()):
		var contact := current_contacts[event_index]
		if SurfaceContactGapValidator.is_target_contact(
			_terrain_surface,
			_paint_surface_tuning,
			_target_mask,
			contact
		):
			_current_target_top_contact = contact
			_current_target_event_index = event_index
			break
	if _current_target_top_contact == null:
		if _interval_last_contact != null:
			_interval_missing_ticks += 1
			if _interval_missing_ticks > _paint_surface_tuning.maximum_bridge_ticks:
				_interval_last_contact = null
				_interval_missing_ticks = 0
		return

	var current := _current_target_top_contact
	if _interval_last_contact == null or not _interval_last_contact.same_collider_shape(current):
		_emit_impact_intent(current, _current_target_event_index)
	else:
		var missing_ticks := maxi(0, current.physics_tick - _interval_last_contact.physics_tick - 1)
		if missing_ticks == 0:
			_emit_sweep_intent(
				_interval_last_contact,
				current,
				_current_target_event_index,
				false
			)
		elif SurfaceContactGapValidator.can_bridge(
			_terrain_surface,
			_paint_surface_tuning,
			_target_mask,
			_interval_last_contact,
			current,
			missing_ticks,
			space_state
		):
			_emit_sweep_intent(
				_interval_last_contact,
				current,
				_current_target_event_index,
				true
			)
		else:
			_emit_impact_intent(current, _current_target_event_index)
	_interval_last_contact = current
	_interval_missing_ticks = 0


func _emit_impact_intent(contact: ProjectileContact, source_event_index: int) -> void:
	var intent := RadialPaintMark.new(
		contact.physics_tick,
		_spawn_ordinal,
		source_event_index,
		-1,
		contact.world_position,
		contact.normal,
		projectile_data.impact_paint_radius * paint_radius_multiplier(),
		contact.collider_rid,
		contact.contact_owner_id,
		contact.contact_shape_id,
		contact.collider_shape_index,
		RadialPaintMark.Kind.IMPACT
	)
	if intent.is_intent_valid():
		radial_paint_mark_intent_requested.emit(self, intent)


func _emit_sweep_intent(
		from_contact: ProjectileContact,
		to_contact: ProjectileContact,
		source_event_index: int,
		bridged_gap: bool
) -> void:
	var intent := SurfacePaintSweep.new(
		to_contact.physics_tick,
		_spawn_ordinal,
		source_event_index,
		-1,
		from_contact.world_position,
		to_contact.world_position,
		from_contact.normal,
		to_contact.normal,
		projectile_data.paint_footprint_radius * paint_radius_multiplier(),
		to_contact.collider_rid,
		to_contact.contact_owner_id,
		to_contact.contact_shape_id,
		to_contact.collider_shape_index,
		bridged_gap
	)
	if intent.is_intent_valid():
		surface_paint_sweep_intent_requested.emit(self, intent)


func _emit_settle_intent(contact: ProjectileContact, source_event_index: int) -> void:
	var intent := RadialPaintMark.new(
		contact.physics_tick,
		_spawn_ordinal,
		source_event_index,
		-1,
		contact.world_position,
		contact.normal,
		projectile_data.settle_paint_radius * paint_radius_multiplier(),
		contact.collider_rid,
		contact.contact_owner_id,
		contact.contact_shape_id,
		contact.collider_shape_index,
		RadialPaintMark.Kind.SETTLE
	)
	if intent.is_intent_valid():
		radial_paint_mark_intent_requested.emit(self, intent)


func _deactivate_from_state(state: PhysicsDirectBodyState3D, reason: StringName) -> void:
	if _deactivated:
		return
	_deactivated = true
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	stopped.emit(self, reason)
	queue_free()


func _contains_backstop_contact(contacts: Array[ProjectileContact]) -> bool:
	for contact in contacts:
		if contact.contact_owner_id == ContainmentSpec.BACKSTOP_OWNER_ID \
				and contact.contact_shape_id == ContainmentSpec.BACKSTOP_SHAPE_ID:
			return true
	return false


func _first_top_contact(contacts: Array[ProjectileContact]) -> ProjectileContact:
	for contact in contacts:
		if _terrain_surface.is_top_collider(contact.collider):
			return contact
	return null


func _stable_contact_less(a: ProjectileContact, b: ProjectileContact) -> bool:
	var a_owner := String(a.contact_owner_id)
	var b_owner := String(b.contact_owner_id)
	if a_owner != b_owner:
		return a_owner < b_owner
	var a_shape := String(a.contact_shape_id)
	var b_shape := String(b.contact_shape_id)
	if a_shape != b_shape:
		return a_shape < b_shape
	if a.local_shape_index != b.local_shape_index:
		return a.local_shape_index < b.local_shape_index
	return false


func _primary_contact(contacts: Array[ProjectileContact]) -> ProjectileContact:
	if contacts.is_empty():
		return null
	# A begun event represents one RID/collider-shape/local-shape key, not every raw
	# manifold point. Prefer measured impulse, then deterministic geometric ties.
	contacts.sort_custom(func(a: ProjectileContact, b: ProjectileContact) -> bool:
		var a_impulse := a.impulse.length_squared()
		var b_impulse := b.impulse.length_squared()
		if not is_equal_approx(a_impulse, b_impulse):
			return a_impulse > b_impulse
		if not is_equal_approx(a._selection_distance_error, b._selection_distance_error):
			return a._selection_distance_error < b._selection_distance_error
		if not is_equal_approx(a.world_position.x, b.world_position.x):
			return a.world_position.x < b.world_position.x
		if not is_equal_approx(a.world_position.y, b.world_position.y):
			return a.world_position.y < b.world_position.y
		return a.world_position.z < b.world_position.z
	)
	return contacts[0]


func _select_incoming_velocity(world_normal: Vector3, collider_velocity: Vector3) -> Vector3:
	var selected := _cached_incoming_velocity
	var selected_closing_speed := -(selected - collider_velocity).dot(world_normal)
	for candidate in _velocity_history:
		var closing_speed := -(candidate - collider_velocity).dot(world_normal)
		if closing_speed > selected_closing_speed:
			selected = candidate
			selected_closing_speed = closing_speed
	return selected


func _build_body() -> void:
	var material := PhysicsMaterial.new()
	material.bounce = projectile_data.bounce
	material.friction = projectile_data.friction
	physics_material_override = material
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = physical_radius()
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = sphere_shape
	add_child(collision)
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = physical_radius()
	sphere_mesh.height = physical_radius() * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	var paint_material := StandardMaterial3D.new()
	paint_material.albedo_color = Color(0.03, 0.36, 1.0, 1.0)
	paint_material.metallic = 0.16
	paint_material.roughness = 0.24
	sphere_mesh.material = paint_material
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "PaintballMesh"
	mesh_instance.mesh = sphere_mesh
	add_child(mesh_instance)
