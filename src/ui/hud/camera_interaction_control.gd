class_name CameraInteractionControl
extends Button

signal interaction_mode_requested(mode: int)

var _interaction_mode := CameraDirector.InteractionMode.AIM_LOCKED
var _mode_icon: Texture2D


func _ready() -> void:
	_mode_icon = icon
	pressed.connect(_request_other_mode)
	_refresh_copy()


func set_interaction_mode(mode: CameraDirector.InteractionMode) -> void:
	_interaction_mode = mode
	_refresh_copy()


func set_mode_switch_available(available: bool) -> void:
	disabled = not available


func refresh_locale() -> void:
	_refresh_copy()


func _request_other_mode() -> void:
	var requested := CameraDirector.InteractionMode.MAP_INSPECTION \
			if _interaction_mode == CameraDirector.InteractionMode.AIM_LOCKED \
			else CameraDirector.InteractionMode.AIM_LOCKED
	interaction_mode_requested.emit(requested)
	# The request may be rejected if the gameplay state changes in the same frame.
	# Keep the pressed visual tied to the last authoritative callback.
	button_pressed = _interaction_mode == CameraDirector.InteractionMode.MAP_INSPECTION


func _refresh_copy() -> void:
	theme_type_variation = &"HudModeButtonCompact"
	icon = _mode_icon
	text = ""
	button_pressed = _interaction_mode == CameraDirector.InteractionMode.MAP_INSPECTION
	if _interaction_mode == CameraDirector.InteractionMode.AIM_LOCKED:
		tooltip_text = tr("hud.switch_to_map_inspection")
	else:
		tooltip_text = tr("hud.switch_to_aim_lock")
	accessibility_name = tooltip_text
