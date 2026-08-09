class_name ShortcutHint
extends PanelContainer

## Presentational key legend only. Input remains owned by the relevant controller.

@export var key_text := "Space":
	set(value):
		key_text = value
		_refresh()

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_refresh()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	%Keycap.text = key_text
	%Keycap.visible = not key_text.is_empty()
	%Icon.texture = icon_texture
	%Icon.visible = icon_texture != null
