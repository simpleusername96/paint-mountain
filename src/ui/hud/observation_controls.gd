class_name ObservationControls
extends PanelContainer

signal camera_mode_requested(mode: int)
signal simulation_speed_requested(speed: float)
signal pause_requested


func _ready() -> void:
	%Follow.pressed.connect(func() -> void: camera_mode_requested.emit(CameraDirector.Mode.FOLLOW))
	%Wide.pressed.connect(func() -> void: camera_mode_requested.emit(CameraDirector.Mode.WIDE))
	%Cannon.pressed.connect(func() -> void: camera_mode_requested.emit(CameraDirector.Mode.CANNON))
	%Speed1.pressed.connect(func() -> void: simulation_speed_requested.emit(1.0))
	%Speed2.pressed.connect(func() -> void: simulation_speed_requested.emit(2.0))
	%Pause.pressed.connect(func() -> void: pause_requested.emit())
