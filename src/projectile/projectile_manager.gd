class_name ProjectileManager
extends Node3D

signal projectile_spawned(projectile: PaintProjectile)
signal projectile_contact_reported(projectile: PaintProjectile, contact: ProjectileContact)
signal paint_deposit_requested(projectile: PaintProjectile, request: PaintDepositRequest)
signal paint_deposit_resolved(
	projectile: PaintProjectile,
	request: PaintDepositRequest,
	accepted_amount: float,
	written_pixel_count: int
)
signal transient_splash_requested(projectile: PaintProjectile, contact: ProjectileContact)
signal projectile_stopped(projectile: PaintProjectile, reason: StringName)
signal all_projectiles_settled

const MAXIMUM_ACTIVE_PROJECTILES := 8

var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))
var _terrain_surface: TerrainSurface
var _active: Array[PaintProjectile] = []


func configure_terrain(terrain_surface: TerrainSurface) -> void:
	assert(terrain_surface != null, "ProjectileManager requires TerrainSurface.")
	_terrain_surface = terrain_surface


func spawn_projectile(
		projectile_data: ProjectileData,
		origin: Vector3,
		velocity: Vector3,
		payload_override: float = -1.0,
		split_generation: int = 0
) -> PaintProjectile:
	_prune_invalid()
	if _active.size() >= MAXIMUM_ACTIVE_PROJECTILES or _terrain_surface == null:
		return null
	var projectile := PaintProjectile.new()
	projectile.name = "PaintProjectile%02d" % (_active.size() + 1)
	projectile.configure(projectile_data, stage_bounds, _terrain_surface, velocity, payload_override, split_generation)
	projectile.contact_reported.connect(_on_contact_reported)
	projectile.paint_deposit_requested.connect(_on_paint_deposit_requested)
	projectile.transient_splash_requested.connect(_on_transient_splash_requested)
	projectile.stopped.connect(_on_projectile_stopped)
	projectile.position = to_local(origin)
	projectile.linear_velocity = velocity
	add_child(projectile)
	_active.append(projectile)
	projectile_spawned.emit(projectile)
	return projectile


func active_count() -> int:
	_prune_invalid()
	return _active.size()


func active_projectiles() -> Array[PaintProjectile]:
	_prune_invalid()
	return _active.duplicate()


func cleanup() -> void:
	for projectile in _active:
		if is_instance_valid(projectile):
			projectile.queue_free()
	_active.clear()
	all_projectiles_settled.emit()


func resolve_paint_deposit(
		projectile: PaintProjectile,
		request: PaintDepositRequest,
		result: Dictionary
) -> void:
	if projectile == null or request == null:
		return
	var accepted_amount := float(result.get("accepted_amount", 0.0))
	var written_pixels := int(result.get("written_pixel_count", 0))
	if is_instance_valid(projectile):
		projectile.accept_deposit_amount(accepted_amount)
	paint_deposit_resolved.emit(projectile, request, accepted_amount, written_pixels)


func _on_contact_reported(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	projectile_contact_reported.emit(projectile, contact)


func _on_paint_deposit_requested(projectile: PaintProjectile, request: PaintDepositRequest) -> void:
	paint_deposit_requested.emit(projectile, request)


func _on_transient_splash_requested(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	transient_splash_requested.emit(projectile, contact)


func _on_projectile_stopped(projectile: PaintProjectile, reason: StringName) -> void:
	_active.erase(projectile)
	projectile_stopped.emit(projectile, reason)
	if _active.is_empty():
		all_projectiles_settled.emit()


func _prune_invalid() -> void:
	for index in range(_active.size() - 1, -1, -1):
		if not is_instance_valid(_active[index]):
			_active.remove_at(index)
