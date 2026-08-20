class_name ActionControl
extends Button

@export var show_icon := true

var _label_key := "ui.fire"
var _compact_glyph := ""
var _compact_density := 1.0


func _ready() -> void:
	if not show_icon:
		icon = null
	refresh_locale()


func configure(label_key: String) -> void:
	_label_key = label_key
	refresh_locale()


func refresh_locale() -> void:
	var localized := tr(_label_key)
	text = _compact_glyph if not _compact_glyph.is_empty() else localized
	accessibility_name = localized
	tooltip_text = localized if not _compact_glyph.is_empty() else tooltip_text


func set_compact_glyph(glyph: String, density: float = 1.0) -> void:
	_compact_glyph = glyph
	_compact_density = maxf(density, 1.0)
	show_icon = false
	icon = null
	add_theme_font_size_override(&"font_size", roundi(24.0 * _compact_density))
	refresh_locale()


func set_readiness(enabled: bool, reason: String = "") -> void:
	disabled = not enabled
	tooltip_text = reason if not enabled and not reason.is_empty() else text
	accessibility_description = tooltip_text
