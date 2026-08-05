class_name ProjectileData
extends Resource

@export_category("Body")
@export_range(0.1, 2.0, 0.05) var radius: float = 0.52
@export_range(0.1, 20.0, 0.1) var mass: float = 2.4
@export_range(0.0, 1.0, 0.01) var bounce: float = 0.08
@export_range(0.0, 1.0, 0.01) var friction: float = 0.78
@export_range(0.0, 5.0, 0.05) var linear_damp: float = 0.18
@export_range(0.0, 5.0, 0.05) var angular_damp: float = 0.35

@export_category("Launch")
@export_range(1.0, 100.0, 0.5) var minimum_launch_speed: float = 32.0
@export_range(1.0, 200.0, 0.5) var maximum_launch_speed: float = 160.0

@export_category("Lifetime")
@export_range(1.0, 60.0, 0.25) var maximum_lifetime: float = 18.0
@export_range(0.05, 5.0, 0.05) var minimum_movement_speed: float = 1.4
@export_range(0.1, 5.0, 0.1) var stop_duration: float = 1.0

@export_category("Paint Surface")
@export_range(0.05, 8.0, 0.05) var paint_footprint_radius: float = 4.0
@export_range(0.1, 20.0, 0.1) var impact_paint_radius: float = 6.0
@export_range(0.1, 20.0, 0.1) var settle_paint_radius: float = 4.0


func launch_speed(power_percent: float) -> float:
	var normalized_power := clampf(power_percent / 100.0, 0.0, 1.0)
	return lerpf(minimum_launch_speed, maximum_launch_speed, normalized_power)
