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
