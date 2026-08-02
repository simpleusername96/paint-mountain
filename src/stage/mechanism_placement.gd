class_name MechanismPlacement
extends Resource

@export var mechanism_data: MechanismData
@export var local_xz: Vector2 = Vector2.ZERO
@export var height_offset: float = 1.0
@export_range(-180.0, 180.0, 1.0) var yaw_degrees: float = 0.0
