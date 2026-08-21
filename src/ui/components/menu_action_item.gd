class_name MenuActionItem
extends Control

signal pressed

const REVEAL_DURATION := 0.16
const HIDE_DELAY := 0.10

@onready var action: ActionControl = %Action
@onready var _label: Label = %RevealLabel

var _label_key := "ui.play"
var _compact := false
var _density := 1.0
var _reveal_tween: Tween
var _hide_generation := 0


func _ready() -> void:
	action.pressed.connect(func() -> void: pressed.emit())
	action.mouse_entered.connect(_show_label)
	action.mouse_exited.connect(_schedule_hide)
	action.focus_entered.connect(_show_label)
	action.focus_exited.connect(_schedule_hide)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.modulate.a = 0.0
	refresh_locale()
	_apply_layout()


func configure(
		localized_label_key: String,
		icon_kind: ActionControl.IconKind,
		role: ActionControl.VisualRole = ActionControl.VisualRole.ROUTINE
) -> void:
	_label_key = localized_label_key
	action.configure(localized_label_key, icon_kind, role)
	refresh_locale()


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0)
	action.set_compact(compact, _density)
	_apply_layout()


func set_readiness(enabled: bool, reason: String = "") -> void:
	action.set_readiness(enabled, reason)


func focus_action() -> void:
	action.grab_focus()


func action_has_focus() -> bool:
	return action.has_focus()


func reveal_for_capture() -> void:
	_show_label()


func refresh_locale() -> void:
	_label.text = tr(_label_key)
	action.refresh_locale()


func _show_label() -> void:
	_hide_generation += 1
	if _reveal_tween != null:
		_reveal_tween.kill()
	_label.show()
	_label.position.x = _label_hidden_x()
	_reveal_tween = create_tween().set_parallel(true)
	_reveal_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(_label, "modulate:a", 1.0, REVEAL_DURATION)
	_reveal_tween.tween_property(_label, "position:x", _label_visible_x(), REVEAL_DURATION)


func _schedule_hide() -> void:
	_hide_generation += 1
	var generation := _hide_generation
	await get_tree().create_timer(HIDE_DELAY).timeout
	if generation != _hide_generation or action.has_focus() or action.is_hovered():
		return
	_hide_label()


func _hide_label() -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
	_reveal_tween = create_tween().set_parallel(true)
	_reveal_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_reveal_tween.tween_property(_label, "modulate:a", 0.0, REVEAL_DURATION)
	_reveal_tween.tween_property(_label, "position:x", _label_hidden_x(), REVEAL_DURATION)


func _apply_layout() -> void:
	var action_edge := (40.0 if _compact else 44.0) * _density
	var row_height := maxf(action_edge, (44.0 if _compact else 48.0) * _density)
	custom_minimum_size = Vector2(264.0 * _density, row_height)
	action.position = Vector2(0.0, (row_height - action_edge) * 0.5)
	action.size = Vector2(action_edge, action_edge)
	action.set_icon_width(30.0 if _compact else 34.0)
	_label.position = Vector2(_label_hidden_x(), 0.0)
	_label.size = Vector2(196.0 * _density, row_height)
	_label.add_theme_font_size_override(&"font_size", roundi((15.0 if _compact else 17.0) * _density))


func _label_hidden_x() -> float:
	return (52.0 if _compact else 56.0) * _density


func _label_visible_x() -> float:
	return (60.0 if _compact else 68.0) * _density
