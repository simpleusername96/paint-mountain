class_name MechanismData
extends Resource

enum Kind {
	BURST,
	SPLITTER,
	BUMPER,
}

@export_category("Identity")
@export var kind: Kind = Kind.BURST
@export var display_name: String = "BURST"
@export_multiline var description: String = "Paints a wide area once when struck."

@export_category("Activation")
@export_range(0, 8, 1) var maximum_charges: int = 1
@export_range(0.0, 5.0, 0.05) var cooldown_seconds: float = 0.35
@export_range(0.5, 8.0, 0.1) var trigger_radius: float = 2.1

@export_category("Burst")
@export_range(0.5, 40.0, 0.5) var burst_radius: float = 28.0
@export_range(1.0, 800.0, 1.0) var burst_paint_amount: float = 320.0

@export_category("Splitter")
@export_range(2, 5, 1) var child_count: int = 3
@export_range(0.05, 0.45, 0.01) var child_payload_ratio: float = 0.3
@export_range(5.0, 120.0, 1.0) var fan_angle_degrees: float = 34.0
@export_range(0.2, 1.5, 0.05) var child_speed_multiplier: float = 0.78

@export_category("Bumper")
@export var impulse_direction := Vector3(0.0, 0.62, -0.78)
@export_range(1.0, 100.0, 1.0) var impulse_strength: float = 34.0


func has_finite_charges() -> bool:
	return maximum_charges > 0
