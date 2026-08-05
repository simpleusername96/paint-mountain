class_name WindProfile
extends Resource

@export_category("Schedule")
@export_range(1.0, 120.0, 1.0) var interval_seconds: float = 30.0
@export_range(0.0, 10.0, 0.5) var transition_seconds: float = 3.0
@export var schedule_version: int = 1

@export_category("Force")
@export_range(0.0, 20.0, 0.1) var maximum_acceleration: float = 6.0
@export_range(0.0, 1.0, 0.05) var minimum_strength: float = 0.10
@export_range(0.0, 1.0, 0.05) var maximum_strength: float = 1.0
@export_range(0.0, 1.0, 0.05) var strong_wind_threshold: float = 0.75
@export_range(0.0, 20.0, 0.1) var wake_impulse_speed: float = 4.5
@export_range(0.0, 2.0, 0.05) var terrain_acceleration_multiplier: float = 0.55


func is_valid() -> bool:
	return interval_seconds > 0.0 \
			and transition_seconds >= 0.0 \
			and transition_seconds < interval_seconds \
			and schedule_version > 0 \
			and maximum_acceleration >= 0.0 \
			and minimum_strength >= 0.0 \
			and maximum_strength >= minimum_strength \
			and maximum_strength <= 1.0 \
			and strong_wind_threshold >= 0.0 \
			and strong_wind_threshold <= 1.0 \
			and wake_impulse_speed >= 0.0 \
			and terrain_acceleration_multiplier >= 0.0


func interval_ticks(physics_ticks_per_second: int = 60) -> int:
	return maxi(1, roundi(interval_seconds * float(maxi(1, physics_ticks_per_second))))


func transition_ticks(physics_ticks_per_second: int = 60) -> int:
	return clampi(
		roundi(transition_seconds * float(maxi(1, physics_ticks_per_second))),
		0,
		interval_ticks(physics_ticks_per_second) - 1
	)
