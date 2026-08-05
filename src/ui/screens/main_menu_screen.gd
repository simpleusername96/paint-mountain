class_name MainMenuScreen
extends CanvasLayer

signal play_requested
signal stage_select_requested
signal settings_requested
signal quit_requested

var _play_ready := false
var _play_failed := false


func _ready() -> void:
	%Play.pressed.connect(func() -> void: play_requested.emit())
	%StageSelect.pressed.connect(func() -> void: stage_select_requested.emit())
	%Settings.pressed.connect(func() -> void: settings_requested.emit())
	%Quit.pressed.connect(func() -> void: quit_requested.emit())
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
	_apply_play_preparation_state()


func set_play_preparation_state(ready: bool, failed: bool = false) -> void:
	_play_ready = ready
	_play_failed = failed
	_apply_play_preparation_state()


func focus_primary() -> void:
	if not %Play.disabled:
		%Play.grab_focus()
	else:
		%StageSelect.grab_focus()


func _apply_play_preparation_state() -> void:
	%Play.disabled = not _play_ready
	if _play_failed:
		%Play.text = tr("ui.stage_unavailable")
	elif not _play_ready:
		%Play.text = tr("ui.preparing_stage")
	else:
		%Play.text = tr("ui.play")


func _on_settings_changed(_settings: Dictionary) -> void:
	_apply_play_preparation_state()
