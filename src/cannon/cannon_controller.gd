class_name CannonController
extends Node3D

signal aim_changed(yaw_degrees: float, elevation_degrees: float, power_percent: float)
signal aim_validity_changed(is_valid: bool)
signal prediction_changed(prediction: TrajectoryPrediction)

@export var projectile_data: ProjectileData
@export_range(0.0, 100.0, 1.0) var default_power: float = 68.0

var yaw_degrees: float = 0.0
var elevation_degrees: float = 38.0
var power_percent: float = 68.0
var input_enabled: bool = true
var _prediction: TrajectoryPrediction
var _prediction_aim_key: StringName = &""

@onready var _yaw_pivot: Node3D = %YawPivot
@onready var _elevation_pivot: Node3D = %ElevationPivot
@onready var _muzzle: Marker3D = %Muzzle


func _ready() -> void:
	assert(
		_yaw_pivot.position.is_equal_approx(CannonBallistics.YAW_PIVOT_OFFSET) \
				and _elevation_pivot.position.is_equal_approx(
					CannonBallistics.ELEVATION_PIVOT_OFFSET
				) \
				and _muzzle.position.is_equal_approx(CannonBallistics.MUZZLE_OFFSET),
		"Cannon scene offsets must match the shared ballistic geometry contract."
	)
	power_percent = default_power
	_apply_visuals()
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func set_aim(
		new_yaw: float,
		new_elevation: float,
		new_power: float,
		publish_if_unchanged: bool = false
) -> void:
	var canonical := AimTuple.canonicalize(new_yaw, new_elevation, new_power)
	if canonical == null:
		return
	if is_equal_approx(canonical.yaw_degrees, yaw_degrees) \
			and is_equal_approx(canonical.elevation_degrees, elevation_degrees) \
			and is_equal_approx(float(canonical.power_percent), power_percent):
		if publish_if_unchanged:
			publish_current_aim()
		return
	yaw_degrees = canonical.yaw_degrees
	elevation_degrees = canonical.elevation_degrees
	power_percent = float(canonical.power_percent)
	var was_valid := is_aim_valid()
	_prediction = null
	_prediction_aim_key = &""
	if was_valid:
		aim_validity_changed.emit(false)
	_apply_visuals()
	publish_current_aim()


func publish_current_aim() -> void:
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func set_prediction(value: TrajectoryPrediction, prediction_aim_key: StringName = &"") -> void:
	var was_valid := is_aim_valid()
	_prediction = value
	_prediction_aim_key = prediction_aim_key if not prediction_aim_key.is_empty() else aim_key()
	prediction_changed.emit(_prediction)
	var is_valid := is_aim_valid()
	if was_valid != is_valid:
		aim_validity_changed.emit(is_valid)


func current_prediction() -> TrajectoryPrediction:
	return _prediction if prediction_matches_current_aim() else null


func aim_key() -> StringName:
	return AimTuple.new(yaw_degrees, elevation_degrees, int(power_percent)).stable_key()


func prediction_key() -> StringName:
	return _prediction_aim_key


func prediction_matches_current_aim() -> bool:
	return _prediction != null and not _prediction_aim_key.is_empty() \
			and _prediction_aim_key == aim_key()


func prediction_status() -> StringName:
	if not prediction_matches_current_aim():
		return &"pending"
	return &"fireable" if _prediction.is_fireable() else &"invalid"


func is_aim_valid() -> bool:
	return prediction_status() == &"fireable"


## Compatibility preflight for low-level fixtures. Production Fire admission is
## owned by StageController; this method intentionally has no firing side effect.
func request_fire() -> bool:
	return input_enabled and projectile_data != null and is_aim_valid()


func get_launch_origin() -> Vector3:
	return _muzzle.global_position


func get_launch_origin_for(requested_yaw: float, requested_elevation: float) -> Vector3:
	return CannonBallistics.launch_origin_for_transform(
		global_transform,
		requested_yaw,
		requested_elevation
	)


func get_launch_velocity() -> Vector3:
	return CannonBallistics.launch_velocity(
		projectile_data,
		yaw_degrees,
		elevation_degrees,
		power_percent
	)


func _apply_visuals() -> void:
	if not is_node_ready():
		return
	_yaw_pivot.rotation.y = deg_to_rad(yaw_degrees)
	_elevation_pivot.rotation.x = deg_to_rad(elevation_degrees)
