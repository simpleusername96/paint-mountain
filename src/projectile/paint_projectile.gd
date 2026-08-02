class_name PaintProjectile
extends RigidBody3D

signal impacted(projectile: PaintProjectile, world_position: Vector3, speed: float)
signal stopped(projectile: PaintProjectile, reason: StringName)

var projectile_data: ProjectileData
var remaining_payload: float = 0.0
var split_generation: int = 0
var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))

var _elapsed: float = 0.0
var _slow_elapsed: float = 0.0
var _deactivated: bool = false


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
	freeze = true
	stopped.emit(self, reason)
	queue_free()


func _on_body_entered(_body: Node) -> void:
	if _deactivated:
		return
	impacted.emit(self, global_position, linear_velocity.length())


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
