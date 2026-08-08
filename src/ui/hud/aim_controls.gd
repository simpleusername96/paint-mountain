class_name AimControls
extends PanelContainer

signal power_step_requested(direction: float)
signal angle_step_requested(direction: float)

const HOLD_DELAY := 0.30
const HOLD_REPEAT := 0.08

@onready var direction_value: Label = %DirectionValue
@onready var elevation_value: Label = %ElevationValue
@onready var power_value: Label = %PowerValue
var _hold_direction := 0.0
var _hold_angle := false
var _hold_elapsed := 0.0
var _next_repeat := HOLD_DELAY


func _ready() -> void:
	%AngleDecrease.button_down.connect(_begin_hold.bind(-1.0, true))
	%AngleIncrease.button_down.connect(_begin_hold.bind(1.0, true))
	%PowerDecrease.button_down.connect(_begin_hold.bind(-2.0, false))
	%PowerIncrease.button_down.connect(_begin_hold.bind(2.0, false))
	%AngleDecrease.button_up.connect(_end_hold)
	%AngleIncrease.button_up.connect(_end_hold)
	%PowerDecrease.button_up.connect(_end_hold)
	%PowerIncrease.button_up.connect(_end_hold)
	refresh_locale()


func refresh_locale() -> void:
	$Content/ElevationCaption.text = tr("hud.angle")
	$Content/PowerCaption.text = tr("hud.power")
	%AngleDecrease.tooltip_text = tr("hud.angle_decrease")
	%AngleIncrease.tooltip_text = tr("hud.angle_increase")
	%PowerDecrease.tooltip_text = tr("hud.power_decrease")
	%PowerIncrease.tooltip_text = tr("hud.power_increase")


func _process(delta: float) -> void:
	if is_zero_approx(_hold_direction):
		return
	_hold_elapsed += delta
	while _hold_elapsed >= _next_repeat:
		_emit_step(_hold_direction, _hold_angle)
		_next_repeat += HOLD_REPEAT


func update_aim(yaw: float, elevation: float, power: float) -> void:
	var side := tr("hud.direction_center")
	if yaw < -0.05:
		side = tr("hud.direction_left")
	elif yaw > 0.05:
		side = tr("hud.direction_right")
	direction_value.text = "%s  %s %+.1f°" % [tr("hud.direction"), side, yaw]
	elevation_value.text = "%.1f°" % elevation
	power_value.text = "%.1f%%" % power


func _begin_hold(direction: float, angle: bool) -> void:
	_emit_step(direction, angle)
	_hold_direction = direction
	_hold_angle = angle
	_hold_elapsed = 0.0
	_next_repeat = HOLD_DELAY


func _end_hold() -> void:
	_hold_direction = 0.0


func _emit_step(direction: float, angle: bool) -> void:
	if angle:
		angle_step_requested.emit(direction)
	else:
		power_step_requested.emit(direction)
