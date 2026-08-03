class_name PaintProjectile
extends RigidBody3D

signal contact_reported(projectile: PaintProjectile, contact: ProjectileContact)
signal paint_deposit_requested(projectile: PaintProjectile, request: PaintDepositRequest)
signal transient_splash_requested(projectile: PaintProjectile, contact: ProjectileContact)
signal stopped(projectile: PaintProjectile, reason: StringName)

const IMPACT_SPEED_THRESHOLD := 8.0
const RECONTACT_ABSENCE_TICKS := 2
const TRAIL_MINIMUM_TRAVEL := 0.8
const TRAIL_MAXIMUM_INTERVAL := 0.12

var projectile_data: ProjectileData
var remaining_payload: float = 0.0
var split_generation: int = 0
var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))

var _terrain_surface: TerrainSurface
var _elapsed: float = 0.0
var _slow_elapsed: float = 0.0
var _deactivated: bool = false
var _trail_elapsed: float = 0.0
var _last_trail_position: Vector3 = Vector3.INF
var _current_top_contact: ProjectileContact
var _cached_incoming_velocity: Vector3 = Vector3.ZERO
var _contact_missing_ticks: Dictionary = {}
var _has_reported_contact: bool = false
var _deposit_sequence: int = 0
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
		payload_override: float = -1.0,
		generation: int = 0
) -> void:
	projectile_data = data
	stage_bounds = bounds
	_terrain_surface = terrain_surface
	_cached_incoming_velocity = launch_velocity
	_velocity_history.assign([launch_velocity])
	remaining_payload = data.initial_payload if payload_override < 0.0 else payload_override
	split_generation = generation


func _ready() -> void:
	assert(projectile_data != null, "PaintProjectile requires ProjectileData before entering the tree.")
	assert(_terrain_surface != null, "PaintProjectile requires the authoritative TerrainSurface.")
	mass = projectile_data.mass
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = projectile_data.linear_damp
	angular_damp = projectile_data.angular_damp
	gravity_scale = 1.0
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
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
	_request_surface_trail(delta)
	if remaining_payload <= 0.0:
		deactivate(&"empty_payload")
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
	var begun_contacts: Array[ProjectileContact] = []
	var top_contacts: Array[ProjectileContact] = []
	var physics_tick := Engine.get_physics_frames()
	for index in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(index)
		var collider_id := collider.get_instance_id() if is_instance_valid(collider) else 0
		var collider_shape := state.get_contact_collider_shape(index)
		var key := "%d:%d" % [collider_id, collider_shape]
		current_keys[key] = true
		var world_normal := state.get_contact_local_normal(index).normalized()
		var world_position := state.get_contact_collider_position(index)
		var collider_velocity := state.get_contact_collider_velocity_at_position(index)
		var incoming_velocity := _select_incoming_velocity(world_normal, collider_velocity)
		var relative_velocity := incoming_velocity - collider_velocity
		var relative_normal_speed := maxf(0.0, -relative_velocity.dot(world_normal))
		var impulse := state.get_contact_impulse(index)
		# Jolt can expose solver-noise impulses on speculative CCD manifolds.
		if impulse.length_squared() < 0.0001:
			impulse = Vector3.ZERO
		var contact := ProjectileContact.new(
			world_position, world_normal, world_position + world_normal * physical_radius(),
			absf(state.transform.origin.distance_to(world_position) - physical_radius()),
			incoming_velocity, relative_normal_speed, impulse, collider,
			state.get_contact_local_shape(index), collider_shape, physics_tick, false
		)
		if _terrain_surface.is_top_collider(collider):
			top_contacts.append(contact)
		var manifold_contacts: Array = contacts_by_key.get(key, [])
		manifold_contacts.append(contact)
		contacts_by_key[key] = manifold_contacts

	for key in contacts_by_key:
		var typed_manifold: Array[ProjectileContact] = []
		for contact: ProjectileContact in contacts_by_key[key]:
			typed_manifold.append(contact)
		if not _contact_missing_ticks.has(key) or int(_contact_missing_ticks[key]) >= RECONTACT_ABSENCE_TICKS:
			begun_contacts.append(_primary_contact(typed_manifold))
		_contact_missing_ticks[key] = 0

	for key in _contact_missing_ticks.keys():
		if not current_keys.has(key):
			_contact_missing_ticks[key] = mini(int(_contact_missing_ticks[key]) + 1, RECONTACT_ABSENCE_TICKS)

	_current_top_contact = _primary_contact(top_contacts)
	var primary := _primary_contact(begun_contacts)
	if primary != null:
		if primary._impulse.is_zero_approx():
			var measured_normal_delta := maxf(
				0.0, (state.linear_velocity - primary.incoming_velocity).dot(primary.normal)
			)
			primary._impulse = primary.normal * measured_normal_delta * mass
		primary._is_first_contact = not _has_reported_contact
		_has_reported_contact = true
		contact_reported.emit(self, primary)
		if primary.relative_normal_speed >= IMPACT_SPEED_THRESHOLD:
			transient_splash_requested.emit(self, primary)
		if _terrain_surface.is_top_collider(primary.collider) and primary.relative_normal_speed >= IMPACT_SPEED_THRESHOLD:
			_request_impact(primary)
	if _queued_desired_velocity != Vector3.INF and physics_tick > _queued_desired_velocity_tick:
		state.apply_central_impulse(mass * (_queued_desired_velocity - state.linear_velocity))
		_queued_desired_velocity = Vector3.INF
		_queued_desired_velocity_tick = -1
	_cached_incoming_velocity = state.linear_velocity
	_velocity_history.append(state.linear_velocity)
	if _velocity_history.size() > 3:
		_velocity_history.pop_front()


func accept_deposit_amount(amount: float) -> void:
	remaining_payload = maxf(0.0, remaining_payload - clampf(amount, 0.0, remaining_payload))


func queue_desired_velocity(desired_velocity: Vector3, contact_tick: int) -> void:
	if desired_velocity.is_finite() and not desired_velocity.is_zero_approx():
		_queued_desired_velocity = desired_velocity
		_queued_desired_velocity_tick = contact_tick


func deactivate(reason: StringName) -> void:
	if _deactivated:
		return
	if reason == &"settled" and _current_top_contact != null and remaining_payload > 0.0:
		_request_deposit(
			PaintDepositRequest.SourceKind.FINAL_PUDDLE,
			_current_top_contact.world_position,
			_current_top_contact.normal,
			projectile_data.paint_stamp_radius * 1.45 * paint_radius_multiplier(),
			minf(remaining_payload, 12.0), true, 12
		)
	_deactivated = true
	freeze = true
	stopped.emit(self, reason)
	queue_free()


func _request_impact(contact: ProjectileContact) -> void:
	var splash_amount := minf(remaining_payload, clampf(contact.relative_normal_speed * 0.5, 4.0, 24.0))
	var splash_scale := clampf(contact.relative_normal_speed / 38.0, 0.45, 1.0)
	_request_deposit(
		PaintDepositRequest.SourceKind.IMPACT, contact.world_position, contact.normal,
		projectile_data.impact_splash_radius * splash_scale * paint_radius_multiplier(),
		splash_amount, true, 12
	)


func _request_surface_trail(delta: float) -> void:
	if _current_top_contact == null or remaining_payload <= 0.0:
		_trail_elapsed = 0.0
		return
	_trail_elapsed += delta
	var distance_ready := _last_trail_position == Vector3.INF \
			or _last_trail_position.distance_to(_current_top_contact.world_position) >= TRAIL_MINIMUM_TRAVEL
	if not distance_ready and _trail_elapsed < TRAIL_MAXIMUM_INTERVAL:
		return
	var payload_ratio := clampf(remaining_payload / projectile_data.initial_payload, 0.0, 1.0)
	var radius := projectile_data.paint_stamp_radius * lerpf(0.48, 1.0, payload_ratio) * paint_radius_multiplier()
	var amount := minf(remaining_payload, maxf(1.0, projectile_data.deposit_rate * _trail_elapsed))
	_request_deposit(
		PaintDepositRequest.SourceKind.TRAIL, _current_top_contact.world_position,
		_current_top_contact.normal, radius, amount, false, 0
	)
	_last_trail_position = _current_top_contact.world_position
	_trail_elapsed = 0.0


func _request_deposit(
		source_kind: PaintDepositRequest.SourceKind,
		world_position: Vector3,
		world_normal: Vector3,
		radius: float,
		amount: float,
		allow_flow: bool,
		maximum_flow_steps: int
) -> void:
	if amount <= 0.0 or remaining_payload <= 0.0:
		return
	_deposit_sequence += 1
	paint_deposit_requested.emit(self, PaintDepositRequest.new(
		source_kind, world_position, world_normal, radius, minf(amount, remaining_payload),
		allow_flow, maximum_flow_steps, get_instance_id(), Engine.get_physics_frames(),
		_deposit_sequence
	))


func _primary_contact(contacts: Array[ProjectileContact]) -> ProjectileContact:
	if contacts.is_empty():
		return null
	contacts.sort_custom(func(a: ProjectileContact, b: ProjectileContact) -> bool:
		var a_impulse := a.impulse.length_squared()
		var b_impulse := b.impulse.length_squared()
		if not is_equal_approx(a_impulse, b_impulse):
			return a_impulse > b_impulse
		if a.collider_instance_id != b.collider_instance_id:
			return a.collider_instance_id < b.collider_instance_id
		if a.collider_shape_index != b.collider_shape_index:
			return a.collider_shape_index < b.collider_shape_index
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
