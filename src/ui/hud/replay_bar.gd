class_name ReplayBar
extends PanelContainer

signal pause_toggled(paused: bool)
signal restart_requested
signal speed_requested(speed: float)
signal exit_requested

var _paused := false


func _ready() -> void:
	%Pause.pressed.connect(_toggle_pause)
	%Restart.pressed.connect(func() -> void: restart_requested.emit())
	%Speed1.pressed.connect(func() -> void: speed_requested.emit(1.0))
	%Speed2.pressed.connect(func() -> void: speed_requested.emit(2.0))
	%Exit.pressed.connect(func() -> void: exit_requested.emit())


func reset_controls() -> void:
	_paused = false
	%Pause.text = tr("replay.pause")


func _toggle_pause() -> void:
	_paused = not _paused
	%Pause.text = tr("replay.play") if _paused else tr("replay.pause")
	pause_toggled.emit(_paused)
