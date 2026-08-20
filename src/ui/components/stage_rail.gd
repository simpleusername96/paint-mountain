class_name StageRail
extends HBoxContainer

signal stage_requested(stage_id: StringName)
signal previous_page_requested
signal next_page_requested

@onready var _previous: Button = %Previous
@onready var _next: Button = %Next
@onready var _nodes: HBoxContainer = %Nodes

var _selected_id := &""
var _buttons: Array[Button] = []
var _compact := false
var _density := 1.0


func _ready() -> void:
	_previous.pressed.connect(func() -> void: previous_page_requested.emit())
	_next.pressed.connect(func() -> void: next_page_requested.emit())
	refresh_locale()


func configure(items: Array[Dictionary], selected_id: StringName) -> void:
	_selected_id = selected_id
	for child in _nodes.get_children():
		_nodes.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for item in items:
		var button := Button.new()
		var stage_id := StringName(item.get("id", &""))
		var stage_number := int(item.get("number", 0))
		var stage_name := String(item.get("name", ""))
		var locked := bool(item.get("locked", false))
		var completed := bool(item.get("completed", false))
		button.custom_minimum_size = _stage_button_size()
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.button_pressed = stage_id == selected_id
		button.disabled = locked
		button.theme_type_variation = &"StageRailButton"
		button.add_theme_font_size_override(
			&"font_size", roundi(16.0 * _density) if _compact else 17
		)
		button.text = str(stage_number)
		var state := tr("result.completed") if completed else "—"
		button.tooltip_text = "%02d · %s · %s" % [stage_number, stage_name, state]
		button.accessibility_name = button.tooltip_text
		button.pressed.connect(_request_stage.bind(stage_id))
		_nodes.add_child(button)
		_buttons.append(button)


func set_page_availability(has_previous: bool, has_next: bool) -> void:
	_previous.disabled = not has_previous
	_next.disabled = not has_next


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0)
	custom_minimum_size.x = 520.0 * _density if compact else 688.0
	_nodes.add_theme_constant_override(&"separation", roundi(4.0 * _density) if compact else 10)
	var target_size := _stage_button_size()
	for button in _buttons:
		button.custom_minimum_size = target_size
		button.add_theme_font_size_override(
			&"font_size", roundi(16.0 * _density) if compact else 17
		)
	_previous.custom_minimum_size = Vector2(40.0, 40.0) * _density \
			if compact else Vector2(44.0, 44.0)
	_next.custom_minimum_size = _previous.custom_minimum_size
	for pager in [_previous, _next]:
		pager.add_theme_font_size_override(
			&"font_size", roundi(20.0 * _density) if compact else 20
		)


func stage_buttons() -> Array[Button]:
	return _buttons


func focus_selected_or_first() -> void:
	for button in _buttons:
		if button.button_pressed and not button.disabled:
			button.grab_focus()
			return
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func refresh_locale() -> void:
	_previous.tooltip_text = tr("ui.previous")
	_next.tooltip_text = tr("ui.next")
	_previous.accessibility_name = _previous.tooltip_text
	_next.accessibility_name = _next.tooltip_text


func _request_stage(stage_id: StringName) -> void:
	stage_requested.emit(stage_id)


func _stage_button_size() -> Vector2:
	var edge := 40.0 * _density if _compact else 52.0
	return Vector2(edge, edge)
