class_name ShortcutHint
extends MarginContainer

## Presentational key legend only. Input remains owned by the relevant controller.

@export var key_text := "Space":
	set(value):
		key_text = value
		_refresh()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	%Keycap.text = "[%s]" % key_text
