class_name WindSnapshot
extends RefCounted

var physics_tick: int
var acceleration: Vector3
var next_acceleration: Vector3
var normalized_strength: float
var next_normalized_strength: float
var seconds_until_change: float
var transition_progress: float
var strong: bool
var strong_episode_id: int
var schedule_identity: StringName


func _init(
		requested_tick: int,
		requested_acceleration: Vector3,
		requested_next_acceleration: Vector3,
		requested_strength: float,
		requested_next_strength: float,
		requested_seconds_until_change: float,
		requested_transition_progress: float,
		requested_schedule_identity: StringName
) -> void:
	physics_tick = requested_tick
	acceleration = requested_acceleration
	next_acceleration = requested_next_acceleration
	normalized_strength = clampf(requested_strength, 0.0, 1.0)
	next_normalized_strength = clampf(requested_next_strength, 0.0, 1.0)
	seconds_until_change = maxf(requested_seconds_until_change, 0.0)
	transition_progress = clampf(requested_transition_progress, 0.0, 1.0)
	schedule_identity = requested_schedule_identity


func push_direction() -> Vector3:
	return acceleration.normalized() if not acceleration.is_zero_approx() else Vector3.ZERO


func is_transitioning() -> bool:
	return transition_progress > 0.0
