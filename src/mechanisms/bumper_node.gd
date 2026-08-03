class_name BumperNode
extends GimmickBase

var _downstream_tangent := Vector3.ZERO


func configure_downstream_tangent(tangent: Vector3) -> void:
	_downstream_tangent = tangent.normalized()


func displayed_downstream_tangent() -> Vector3:
	return _downstream_tangent


func _effect_can_activate(_projectile: PaintProjectile, _contact: ProjectileContact) -> bool:
	return not _downstream_tangent.is_zero_approx()


func _apply_effect(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	var desired_speed := clampf(maxf(contact.incoming_velocity.length() * 0.85, 18.0), 18.0, 32.0)
	var desired_direction := (_downstream_tangent + Vector3.UP * 0.22).normalized()
	projectile.queue_desired_velocity(desired_direction * desired_speed, contact.physics_tick)
