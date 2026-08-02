class_name StageRouteProfile
extends Resource

## Ordered route samples stored as (local_x, height, local_z).
@export var control_points: PackedVector3Array = PackedVector3Array()
@export_range(1.0, 64.0, 0.5) var width: float = 20.0
@export var is_safe_route: bool = false


func is_valid() -> bool:
	if control_points.size() < 2 or width <= 0.0:
		return false
	var previous_z := control_points[0].z
	for index in range(1, control_points.size()):
		if control_points[index].z <= previous_z:
			return false
		previous_z = control_points[index].z
	return true
