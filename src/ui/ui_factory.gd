class_name UIFactory
extends RefCounted

const NAVY := Color(0.055, 0.095, 0.16, 1.0)
const CHARCOAL := Color(0.16, 0.18, 0.22, 1.0)
const MUTED := Color(0.38, 0.41, 0.46, 1.0)
const OFF_WHITE := Color(0.98, 0.97, 0.94, 0.96)
const BLUE := Color(0.035, 0.38, 0.98, 1.0)
const BLUE_HOVER := Color(0.08, 0.46, 1.0, 1.0)


static func panel(minimum_size: Vector2 = Vector2.ZERO, color: Color = OFF_WHITE, radius: int = 18) -> PanelContainer:
	var result := PanelContainer.new()
	result.custom_minimum_size = minimum_size
	result.add_theme_stylebox_override("panel", style(color, radius, true))
	return result


static func label(text: String, font_size: int, color: Color = CHARCOAL) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return result


static func button(text: String, accent: bool = false, minimum_size: Vector2 = Vector2(240.0, 62.0)) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_font_size_override("font_size", 20)
	result.add_theme_color_override("font_color", Color.WHITE if accent else NAVY)
	result.add_theme_color_override("font_hover_color", Color.WHITE if accent else NAVY)
	result.add_theme_color_override("font_pressed_color", Color.WHITE if accent else NAVY)
	result.add_theme_color_override("font_focus_color", Color.WHITE if accent else NAVY)
	result.add_theme_stylebox_override("normal", style(BLUE if accent else OFF_WHITE, 16, true))
	result.add_theme_stylebox_override("hover", style(BLUE_HOVER if accent else Color(0.92, 0.95, 1.0, 0.98), 16, true))
	result.add_theme_stylebox_override("pressed", style(Color(0.02, 0.28, 0.78, 1.0) if accent else Color(0.86, 0.9, 0.96, 1.0), 16))
	result.add_theme_stylebox_override("disabled", style(Color(0.72, 0.74, 0.77, 0.84), 16))
	result.add_theme_color_override("font_disabled_color", Color(0.38, 0.4, 0.44, 0.9))
	result.add_theme_stylebox_override("focus", outline_style(BLUE, 16))
	return result


static func margin(parent: Control, values: Vector4) -> MarginContainer:
	var result := MarginContainer.new()
	result.add_theme_constant_override("margin_left", roundi(values.x))
	result.add_theme_constant_override("margin_top", roundi(values.y))
	result.add_theme_constant_override("margin_right", roundi(values.z))
	result.add_theme_constant_override("margin_bottom", roundi(values.w))
	parent.add_child(result)
	return result


static func style(color: Color, radius: int, shadow: bool = false) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.corner_radius_top_left = radius
	result.corner_radius_top_right = radius
	result.corner_radius_bottom_left = radius
	result.corner_radius_bottom_right = radius
	if shadow:
		result.shadow_color = Color(0.02, 0.04, 0.08, 0.2)
		result.shadow_size = 12
		result.shadow_offset = Vector2(0.0, 4.0)
	return result


static func outline_style(color: Color, radius: int) -> StyleBoxFlat:
	var result := style(Color.TRANSPARENT, radius)
	result.border_width_left = 3
	result.border_width_top = 3
	result.border_width_right = 3
	result.border_width_bottom = 3
	result.border_color = color
	result.expand_margin_left = 3.0
	result.expand_margin_top = 3.0
	result.expand_margin_right = 3.0
	result.expand_margin_bottom = 3.0
	return result
