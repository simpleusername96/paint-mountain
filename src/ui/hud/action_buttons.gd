class_name ActionButtons
extends Control

signal fire_requested


func _ready() -> void:
	%FireButton.pressed.connect(func() -> void: fire_requested.emit())
	(%FireButton as ActionControl).configure("ui.fire")
	refresh_locale()


func refresh_locale() -> void:
	(%FireButton as ActionControl).refresh_locale()


func set_fire_readiness(snapshot: Dictionary) -> void:
	var enabled := bool(snapshot.get("fireable", false))
	var reason := String(snapshot.get("reason", tr("ui.fire")))
	(%FireButton as ActionControl).set_readiness(enabled, reason)
	%ReadinessLabel.text = reason if not enabled else ""
	var show_readiness := not enabled and not reason.is_empty()
	%ReadinessLabel.visible = show_readiness
	%ReadinessBackdrop.visible = show_readiness


func focus_fire() -> void:
	%FireButton.grab_focus()


func set_compact(compact: bool, density: float = 1.0) -> void:
	var scale := maxf(density, 1.0) if compact else 1.0
	custom_minimum_size = Vector2(256.0, 96.0) * scale
	%ReadinessBackdrop.position = Vector2.ZERO
	%ReadinessBackdrop.size = Vector2(256.0, 22.0) * scale
	%ReadinessLabel.position = Vector2.ZERO
	%ReadinessLabel.size = Vector2(256.0, 22.0) * scale
	%ReadinessLabel.add_theme_font_size_override(
		&"font_size", roundi(14.0 * scale) if compact else 14
	)
	var fire := %FireButton as ActionControl
	fire.set_compact(compact, scale)
	fire.set_icon_width(34.0)
	var edge := (48.0 if compact else 56.0) * scale
	fire.position = Vector2((256.0 * scale - edge) * 0.5, 32.0 * scale)
	fire.size = Vector2(edge, edge)
	fire.custom_minimum_size = fire.size
