class_name CannonController
extends Node3D

signal aim_changed(yaw_degrees: float, elevation_degrees: float, power_percent: float)
signal aim_validity_changed(is_valid: bool)
signal prediction_changed(prediction: TrajectoryPrediction)
signal fire_requested(origin: Vector3, velocity: Vector3)

@export var projectile_data: ProjectileData
@export_range(-35.0, 35.0, 0.5) var minimum_yaw: float = -28.0
@export_range(-35.0, 35.0, 0.5) var maximum_yaw: float = 28.0
@export_range(10.0, 80.0, 0.5) var minimum_elevation: float = 18.0
@export_range(10.0, 80.0, 0.5) var maximum_elevation: float = 68.0
@export_range(0.0, 100.0, 1.0) var default_power: float = 68.0

var yaw_degrees: float = 0.0
var elevation_degrees: float = 38.0
var power_percent: float = 68.0
var input_enabled: bool = true
var _prediction: TrajectoryPrediction

@onready var _yaw_pivot: Node3D = %YawPivot
@onready var _elevation_pivot: Node3D = %ElevationPivot
@onready var _muzzle: Marker3D = %Muzzle


func _ready() -> void:
	power_percent = default_power
	_apply_visuals()
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func set_aim(new_yaw: float, new_elevation: float, new_power: float) -> void:
	var clamped_yaw := clampf(new_yaw, minimum_yaw, maximum_yaw)
	var clamped_elevation := clampf(new_elevation, minimum_elevation, maximum_elevation)
	var clamped_power := clampf(new_power, 0.0, 100.0)
	if is_equal_approx(clamped_yaw, yaw_degrees) \
			and is_equal_approx(clamped_elevation, elevation_degrees) \
			and is_equal_approx(clamped_power, power_percent):
		return
	yaw_degrees = clamped_yaw
	elevation_degrees = clamped_elevation
	power_percent = clamped_power
	var was_valid := is_aim_valid()
	_prediction = null
	if was_valid:
		aim_validity_changed.emit(false)
	_apply_visuals()
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func set_prediction(value: TrajectoryPrediction) -> void:
	var was_valid := is_aim_valid()
	_prediction = value
	prediction_changed.emit(_prediction)
	var is_valid := is_aim_valid()
	if was_valid != is_valid:
		aim_validity_changed.emit(is_valid)


func current_prediction() -> TrajectoryPrediction:
	return _prediction


func is_aim_valid() -> bool:
	return _prediction != null and _prediction.is_fireable()


func request_fire() -> bool:
	if not input_enabled or projectile_data == null or not is_aim_valid():
		return false
	fire_requested.emit(get_launch_origin(), get_launch_velocity())
	return true


func get_launch_origin() -> Vector3:
	return _muzzle.global_position


func get_launch_origin_for(requested_yaw: float, requested_elevation: float) -> Vector3:
	var yaw_basis := Basis(Vector3.UP, deg_to_rad(requested_yaw))
	var elevation_basis := Basis(Vector3.RIGHT, deg_to_rad(requested_elevation))
	var local_origin := _yaw_pivot.position + yaw_basis * (
		_elevation_pivot.position + elevation_basis * _muzzle.position
	)
	return global_transform * local_origin


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
