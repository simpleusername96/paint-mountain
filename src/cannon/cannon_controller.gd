class_name CannonController
extends Node3D

signal aim_changed(yaw_degrees: float, elevation_degrees: float, power_percent: float)
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

@onready var _yaw_pivot: Node3D = %YawPivot
@onready var _elevation_pivot: Node3D = %ElevationPivot
@onready var _muzzle: Marker3D = %Muzzle


func _ready() -> void:
	power_percent = default_power
	_apply_visuals()
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func _process(delta: float) -> void:
	if not input_enabled:
		return
	var yaw_axis := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var elevation_axis := float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S))
	var power_axis := float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))
	if not is_zero_approx(yaw_axis) or not is_zero_approx(elevation_axis) or not is_zero_approx(power_axis):
		set_aim(
			yaw_degrees + yaw_axis * 22.0 * delta,
			elevation_degrees + elevation_axis * 22.0 * delta,
			power_percent + power_axis * 32.0 * delta
		)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		set_aim(
			yaw_degrees + event.relative.x * 0.08,
			elevation_degrees - event.relative.y * 0.08,
			power_percent
		)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_aim(yaw_degrees, elevation_degrees, power_percent + 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_aim(yaw_degrees, elevation_degrees, power_percent - 2.0)
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		request_fire()


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
	_apply_visuals()
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func request_fire() -> bool:
	if not input_enabled or projectile_data == null:
		return false
	fire_requested.emit(get_launch_origin(), get_launch_velocity())
	return true


func get_launch_origin() -> Vector3:
	return _muzzle.global_position


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
