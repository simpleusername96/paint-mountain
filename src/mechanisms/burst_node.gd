class_name BurstNode
extends GimmickBase


var _deposit_sequence: int = 0


func _apply_effect(_projectile: PaintProjectile, _contact: ProjectileContact) -> void:
	_deposit_sequence += 1
	var world_xz := Vector2(global_position.x, global_position.z)
	_paint_system.apply_deposit(PaintDepositRequest.new(
		PaintDepositRequest.SourceKind.BURST,
		_paint_system.terrain_surface_position(world_xz),
		_paint_system.terrain_surface_normal(world_xz),
		data.burst_radius,
		data.burst_paint_amount,
		true,
		data.burst_maximum_flow_steps,
		get_instance_id(),
		Engine.get_physics_frames(),
		_deposit_sequence
	))
