class_name TargetBandData
extends Resource

@export var target_min: float = 0.0
@export var target_max: float = 1.0


func is_valid() -> bool:
	return is_finite(target_min) and is_finite(target_max) and target_min < target_max


func contains(score: float) -> bool:
	return is_valid() and score >= target_min and score <= target_max


func center() -> float:
	return (target_min + target_max) * 0.5


func stars_for(score: float) -> int:
	if not contains(score):
		return 0
	var half_width := (target_max - target_min) * 0.5
	var center_distance := absf(score - center())
	if center_distance <= half_width * 0.25:
		return 3
	if center_distance <= half_width * 0.5:
		return 2
	return 1
