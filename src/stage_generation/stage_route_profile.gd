class_name StageRouteProfile
extends Resource

enum Role {
	PRIMARY,
	SAFE,
	SPLITTER,
	BUMPER,
}

@export var role: Role = Role.PRIMARY
@export_range(-70.0, 70.0, 1.0) var endpoint_x: float = 0.0
@export_range(1.0, 64.0, 0.5) var width: float = 20.0
@export_range(0, 6, 1) var target_reversals: int = 0
@export var grade_pattern := PackedInt32Array([-1, -1, -1, -1, -1, -1, -1])
@export var downhill_drop_range := Vector2(7.0, 9.0)
@export var uphill_rise_range := Vector2(0.0, 0.0)
@export var lateral_bend_range := Vector2(-8.0, 8.0)
@export_range(-1.0, 1.0, 0.01) var mechanism_shelf_t: float = -1.0
@export_range(0.0, 20.0, 0.5) var mechanism_shelf_radius: float = 0.0


func is_valid() -> bool:
	if width <= 0.0 or grade_pattern.size() != 7:
		return false
	if downhill_drop_range.x <= 0.0 or downhill_drop_range.x > downhill_drop_range.y:
		return false
	if uphill_rise_range.x < 0.0 or uphill_rise_range.x > uphill_rise_range.y:
		return false
	if lateral_bend_range.x > lateral_bend_range.y:
		return false
	var previous_sign := 0
	var reversals := 0
	for grade in grade_pattern:
		if grade != -1 and grade != 1:
			return false
		if grade > 0 and uphill_rise_range.x <= 0.0:
			return false
		if previous_sign != 0 and grade != previous_sign:
			reversals += 1
		previous_sign = grade
	if reversals != target_reversals:
		return false
	return (mechanism_shelf_t < 0.0 and is_zero_approx(mechanism_shelf_radius)) \
			or (mechanism_shelf_t >= 0.0 and mechanism_shelf_radius > 0.0)
