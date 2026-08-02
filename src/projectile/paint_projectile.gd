class_name PaintProjectile
extends RigidBody3D

signal impacted(projectile: PaintProjectile, world_position: Vector3, speed: float)
signal paint_deposit_requested(
	projectile: PaintProjectile,
	kind: StringName,
	world_position: Vector3,
	radius: float,
	amount: float,
	allow_flow: bool
)
signal stopped(projectile: PaintProjectile, reason: StringName)

var projectile_data: ProjectileData
var remaining_payload: float = 0.0
var split_generation: int = 0
var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))

var _elapsed: float = 0.0
var _slow_elapsed: float = 0.0
var _deactivated: bool = false
var _touching_surface: bool = false
var _contact_position: Vector3 = Vector3.ZERO
var _trail_elapsed: float = 0.0
var _last_deposit_position: Vector3 = Vector3.INF


func configure(
		data: ProjectileData,
		bounds: AABB,
		payload_override: float = -1.0,
		generation: int = 0
) -> void:
	projectile_data = data
	stage_bounds = bounds
	remaining_payload = data.initial_payload if payload_override < 0.0 else payload_override
	split_generation = generation


func _ready() -> void:
	assert(projectile_data != null, "PaintProjectile requires ProjectileData before entering the tree.")
	mass = projectile_data.mass
	linear_damp = projectile_data.linear_damp
	angular_damp = projectile_data.angular_damp
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	can_sleep = true
	_build_body()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _deactivated:
		return
	_elapsed += delta
	if not stage_bounds.has_point(global_position):
		deactivate(&"out_of_bounds")
		return
	if _elapsed >= projectile_data.maximum_lifetime:
		deactivate(&"lifetime")
		return
	if sleeping:
		deactivate(&"settled")
		return
	_deposit_surface_trail(delta)
	if remaining_payload <= 0.0:
		deactivate(&"empty_payload")
		return
	if linear_velocity.length() <= projectile_data.minimum_movement_speed:
		_slow_elapsed += delta
		if _slow_elapsed >= projectile_data.stop_duration:
			deactivate(&"settled")
	else:
		# Brief collision impulses should not erase all accumulated rest time.
		_slow_elapsed = maxf(0.0, _slow_elapsed - delta * 0.35)


func deactivate(reason: StringName) -> void:
	if _deactivated:
		return
	_deactivated = true
	if reason == &"settled" and remaining_payload > 0.0:
		var puddle_amount := minf(remaining_payload, 12.0)
		_request_deposit(
			&"puddle",
			global_position - Vector3.UP * projectile_data.radius * 0.7,
			projectile_data.paint_stamp_radius * 1.45,
			puddle_amount,
			true
		)
	freeze = true
	stopped.emit(self, reason)
	queue_free()


func _on_body_entered(_body: Node) -> void:
	if _deactivated:
		return
	var impact_speed := linear_velocity.length()
	impacted.emit(self, global_position, impact_speed)
	var splash_amount := minf(remaining_payload, clampf(impact_speed * 0.5, 4.0, 24.0))
	var splash_scale := clampf(impact_speed / 38.0, 0.45, 1.0)
	_request_deposit(
		&"impact",
		global_position - Vector3.UP * projectile_data.radius * 0.55,
		projectile_data.impact_splash_radius * splash_scale,
		splash_amount,
		impact_speed >= 20.0
	)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_touching_surface = state.get_contact_count() > 0
	if _touching_surface:
		_contact_position = global_position - Vector3.UP * projectile_data.radius * 0.72


func _deposit_surface_trail(delta: float) -> void:
	if not _touching_surface or remaining_payload <= 0.0:
		_trail_elapsed = 0.0
		return
	_trail_elapsed += delta
	var distance_ready := _last_deposit_position == Vector3.INF \
			or _last_deposit_position.distance_to(_contact_position) >= projectile_data.paint_stamp_radius * 0.7
	if not distance_ready and _trail_elapsed < 0.12:
		return
	var payload_ratio := clampf(remaining_payload / projectile_data.initial_payload, 0.0, 1.0)
	var radius := projectile_data.paint_stamp_radius * lerpf(0.48, 1.0, payload_ratio)
	var amount := minf(remaining_payload, maxf(1.0, projectile_data.deposit_rate * _trail_elapsed))
	_request_deposit(&"trail", _contact_position, radius, amount, false)
	_last_deposit_position = _contact_position
	_trail_elapsed = 0.0


func _request_deposit(
		kind: StringName,
		world_position: Vector3,
		radius: float,
		amount: float,
		allow_flow: bool
) -> void:
	if amount <= 0.0 or remaining_payload <= 0.0:
		return
	var deposited := minf(amount, remaining_payload)
	remaining_payload -= deposited
	paint_deposit_requested.emit(self, kind, world_position, radius, deposited, allow_flow)


func _build_body() -> void:
	var material := PhysicsMaterial.new()
	material.bounce = projectile_data.bounce
	material.friction = projectile_data.friction
	physics_material_override = material

	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = projectile_data.radius
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = sphere_shape
	add_child(collision)

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = projectile_data.radius
	sphere_mesh.height = projectile_data.radius * 2.0
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
