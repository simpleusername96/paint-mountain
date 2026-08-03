class_name ObservationControls
extends PanelContainer

signal camera_mode_requested(mode: int)
signal simulation_speed_requested(speed: float)
signal pause_requested

@onready var payload_bar: ProgressBar = %PayloadBar
@onready var payload_value: Label = %PayloadValue


func _ready() -> void:
	%Follow.pressed.connect(func() -> void: camera_mode_requested.emit(CameraDirector.Mode.FOLLOW))
	%Wide.pressed.connect(func() -> void: camera_mode_requested.emit(CameraDirector.Mode.WIDE))
	%Cannon.pressed.connect(func() -> void: camera_mode_requested.emit(CameraDirector.Mode.CANNON))
	%Speed1.pressed.connect(func() -> void: simulation_speed_requested.emit(1.0))
	%Speed2.pressed.connect(func() -> void: simulation_speed_requested.emit(2.0))
	%Pause.pressed.connect(func() -> void: pause_requested.emit())


func update_payload(remaining: float, initial: float) -> void:
	payload_bar.max_value = maxf(initial, 1.0)
	payload_bar.value = clampf(remaining, 0.0, payload_bar.max_value)
	payload_value.text = "%s  %.0f / %.0f" % [tr("hud.payload"), remaining, initial]
