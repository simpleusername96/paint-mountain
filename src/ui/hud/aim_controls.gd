class_name AimControls
extends PanelContainer

signal power_step_requested(direction: float)

const HOLD_DELAY := 0.30
const HOLD_REPEAT := 0.08

@onready var direction_value: Label = %DirectionValue
@onready var elevation_value: Label = %ElevationValue
@onready var power_value: Label = %PowerValue
var _hold_direction := 0.0
var _hold_elapsed := 0.0
var _next_repeat := HOLD_DELAY


func _ready() -> void:
	%PowerDecrease.button_down.connect(_begin_hold.bind(-1.0))
	%PowerIncrease.button_down.connect(_begin_hold.bind(1.0))
	%PowerDecrease.button_up.connect(_end_hold)
	%PowerIncrease.button_up.connect(_end_hold)


func _process(delta: float) -> void:
	if is_zero_approx(_hold_direction):
		return
	_hold_elapsed += delta
	while _hold_elapsed >= _next_repeat:
		power_step_requested.emit(_hold_direction)
		_next_repeat += HOLD_REPEAT


func update_aim(yaw: float, elevation: float, power: float) -> void:
	var side := tr("hud.direction_center")
	if yaw < -0.05:
		side = tr("hud.direction_left")
	elif yaw > 0.05:
		side = tr("hud.direction_right")
	direction_value.text = "%s  %s %+.1f°" % [tr("hud.direction"), side, yaw]
	elevation_value.text = "%.1f°" % elevation
	power_value.text = "%d%%" % roundi(power)


func _begin_hold(direction: float) -> void:
	power_step_requested.emit(direction)
	_hold_direction = direction
	_hold_elapsed = 0.0
	_next_repeat = HOLD_DELAY


func _end_hold() -> void:
	_hold_direction = 0.0
