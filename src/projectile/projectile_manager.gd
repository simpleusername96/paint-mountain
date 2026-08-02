class_name ProjectileManager
extends Node3D

signal projectile_spawned(projectile: PaintProjectile)
signal projectile_impact(projectile: PaintProjectile, world_position: Vector3, speed: float)
signal projectile_stopped(projectile: PaintProjectile, reason: StringName)
signal all_projectiles_settled

const MAXIMUM_ACTIVE_PROJECTILES := 8

var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))
var _active: Array[PaintProjectile] = []


func spawn_projectile(
		projectile_data: ProjectileData,
		origin: Vector3,
		velocity: Vector3,
		payload_override: float = -1.0,
		split_generation: int = 0
) -> PaintProjectile:
	_prune_invalid()
	if _active.size() >= MAXIMUM_ACTIVE_PROJECTILES:
		return null
	var projectile := PaintProjectile.new()
	projectile.name = "PaintProjectile%02d" % (_active.size() + 1)
	projectile.configure(projectile_data, stage_bounds, payload_override, split_generation)
	add_child(projectile)
	projectile.global_position = origin
	projectile.linear_velocity = velocity
	projectile.impacted.connect(_on_projectile_impacted)
	projectile.stopped.connect(_on_projectile_stopped)
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


func _on_projectile_impacted(projectile: PaintProjectile, world_position: Vector3, speed: float) -> void:
	projectile_impact.emit(projectile, world_position, speed)


func _on_projectile_stopped(projectile: PaintProjectile, reason: StringName) -> void:
	_active.erase(projectile)
	projectile_stopped.emit(projectile, reason)
	if _active.is_empty():
		all_projectiles_settled.emit()


func _prune_invalid() -> void:
	for index in range(_active.size() - 1, -1, -1):
		if not is_instance_valid(_active[index]):
			_active.remove_at(index)
