class_name ActionControl
extends Button

var _label_key := "ui.fire"


func configure(label_key: String) -> void:
	_label_key = label_key
	refresh_locale()


func refresh_locale() -> void:
	text = tr(_label_key)
	accessibility_name = text


func set_readiness(enabled: bool, reason: String = "") -> void:
	disabled = not enabled
	tooltip_text = reason if not enabled and not reason.is_empty() else text
	accessibility_description = tooltip_text
