extends RefCounted

const FAN_YAWS_DEGREES := [-12.0, 0.0, 12.0]
const HORIZONTAL_SPEED_MULTIPLIER := 0.92
const UPWARD_SPEED := 1.5

var _terrain_reached := false
var _apex_resolved := false


func note_valid_terrain_contact() -> void:
	_terrain_reached = true


func on_valid_terrain_contact() -> Dictionary:
	return {}


func on_airborne_velocity(previous_velocity: Vector3, current_velocity: Vector3) -> Array[Vector3]:
	if _terrain_reached or _apex_resolved \
			or previous_velocity.y <= 0.0 or current_velocity.y > 0.0:
		return []
	_apex_resolved = true
	var horizontal := Vector3(current_velocity.x, 0.0, current_velocity.z) \
			* HORIZONTAL_SPEED_MULTIPLIER
	if horizontal.is_zero_approx():
		return []
	var children: Array[Vector3] = []
	for yaw_degrees in FAN_YAWS_DEGREES:
		children.append(horizontal.rotated(Vector3.UP, deg_to_rad(yaw_degrees)) \
				+ Vector3.UP * UPWARD_SPEED)
	return children
