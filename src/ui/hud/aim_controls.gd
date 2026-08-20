class_name AimControls
extends Control

signal power_step_requested(direction: float)
signal angle_step_requested(direction: float)

@onready var angle_stepper: ValueStepper = %AngleStepper
@onready var power_stepper: ValueStepper = %PowerStepper
@onready var elevation_value: Label = angle_stepper.value_label
@onready var power_value: Label = power_stepper.value_label


func _ready() -> void:
	angle_stepper.configure("hud.angle", "hud.angle_decrease", "hud.angle_increase", "°", -1.0, 1.0)
	power_stepper.configure("hud.power", "hud.power_decrease", "hud.power_increase", "%", -2.0, 2.0)
	angle_stepper.step_requested.connect(func(direction: float) -> void: angle_step_requested.emit(direction))
	power_stepper.step_requested.connect(func(direction: float) -> void: power_step_requested.emit(direction))
	refresh_locale()


func refresh_locale() -> void:
	angle_stepper.refresh_locale()
	power_stepper.refresh_locale()


func update_aim(_yaw: float, elevation: float, power: float) -> void:
	angle_stepper.set_value(elevation, AimTuple.MINIMUM_ELEVATION_DEGREES, AimTuple.MAXIMUM_ELEVATION_DEGREES)
	power_stepper.set_value(power, AimTuple.MINIMUM_POWER_PERCENT, AimTuple.MAXIMUM_POWER_PERCENT)


func set_compact(compact: bool) -> void:
	angle_stepper.set_compact(compact)
	power_stepper.set_compact(compact)
	%FireGap.visible = not compact
	%FireGap.custom_minimum_size.x = 0.0 if compact else 252.0
	custom_minimum_size.x = 340.0 if compact else 704.0
