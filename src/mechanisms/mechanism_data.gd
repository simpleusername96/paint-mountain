class_name MechanismData
extends Resource

enum Kind {
	BURST,
	SPLITTER,
	BUMPER,
}

@export_category("Identity")
@export var kind: Kind = Kind.BURST
@export var display_name_key: StringName = &"mechanism.burst"
@export var description_key: StringName = &"mechanism.burst.description"

@export_category("Activation")
@export_range(0, 8, 1) var maximum_charges: int = 1
@export_range(0.0, 5.0, 0.05) var cooldown_seconds: float = 0.35

@export_category("Burst")
@export_range(0.5, 40.0, 0.5) var burst_radius: float = 14.0
@export_range(1.0, 800.0, 1.0) var burst_paint_amount: float = 140.0
@export_range(0, 12, 1) var burst_maximum_flow_steps: int = 12

@export_category("Splitter")
@export_range(2, 5, 1) var child_count: int = 3
@export_range(0.05, 0.45, 0.01) var child_payload_ratio: float = 0.3
@export_range(0.2, 1.5, 0.05) var child_speed_multiplier: float = 0.78
@export_range(1.0, 60.0, 0.5) var child_minimum_route_speed: float = 22.0
@export_range(0.0, 20.0, 0.5) var child_target_lift: float = 5.0
@export_range(0.0, 1.0, 0.01) var child_target_t: float = 0.82
@export var child_target_route_roles := PackedInt32Array([
	StageRouteProfile.Role.SAFE,
	StageRouteProfile.Role.SPLITTER,
	StageRouteProfile.Role.BUMPER,
])


func has_finite_charges() -> bool:
	return maximum_charges > 0
