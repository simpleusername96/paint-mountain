class_name StageRail
extends Control

signal stage_requested(stage_id: StringName)

const NAVY := Color("172538")
const BLUE := Color("2584ff")
const MUTED := Color(1, 1, 1, 0.72)

var _selected_id := &""
var _buttons: Array[Button] = []
var _items: Array[Dictionary] = []
var _hovered_index := -1
var _compact := false
var _density := 1.0
var _drag_origin := Vector2.ZERO
var _dragging := false


func _ready() -> void:
	resized.connect(_layout_buttons)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func configure(items: Array[Dictionary], selected_id: StringName) -> void:
	_selected_id = selected_id
	_items = items.duplicate(true)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	for index in items.size():
		var item := items[index]
		var button := Button.new()
		var stage_id := StringName(item.get("id", &""))
		var stage_number := int(item.get("number", 0))
		var stage_name := String(item.get("name", ""))
		var locked := bool(item.get("locked", false))
		var completed := bool(item.get("completed", false))
		button.custom_minimum_size = _stage_button_size()
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = locked
		button.theme_type_variation = &"StageRailButton"
		var state := tr("result.completed") if completed else "—"
		button.tooltip_text = "%02d · %s · %s" % [stage_number, stage_name, state]
		button.accessibility_name = button.tooltip_text
		button.pressed.connect(_request_stage.bind(stage_id))
		button.mouse_entered.connect(_set_hovered.bind(index))
		button.mouse_exited.connect(_clear_hovered.bind(index))
		button.focus_entered.connect(queue_redraw)
		button.focus_exited.connect(queue_redraw)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(button)
		_buttons.append(button)
	_layout_buttons.call_deferred()
	queue_redraw()


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0)
	custom_minimum_size = Vector2(520.0, 64.0) * _density if compact else Vector2(688.0, 64.0)
	var target_size := _stage_button_size()
	for button in _buttons:
		button.custom_minimum_size = target_size
	_layout_buttons()
	queue_redraw()


func stage_buttons() -> Array[Button]:
	return _buttons


func selected_stage_id() -> StringName:
	return _selected_id


func focus_selected_or_first() -> void:
	for index in _items.size():
		if StringName(_items[index].get("id", &"")) == _selected_id \
				and not _buttons[index].disabled:
			_buttons[index].grab_focus()
			return
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func refresh_locale() -> void:
	for index in _items.size():
		var item := _items[index]
		var state := tr("result.completed") if bool(item.get("completed", false)) else "—"
		var copy := "%02d · %s · %s" % [
			int(item.get("number", 0)), String(item.get("name", "")), state,
		]
		_buttons[index].tooltip_text = copy
		_buttons[index].accessibility_name = copy


func _request_stage(stage_id: StringName) -> void:
	stage_requested.emit(stage_id)


func _stage_button_size() -> Vector2:
	return Vector2(40.0, 64.0) * _density if _compact else Vector2(44.0, 64.0)


func _layout_buttons() -> void:
	if _buttons.is_empty() or size.x <= 0.0:
		return
	var button_size := _stage_button_size()
	var left_center := button_size.x * 0.5
	var usable := maxf(0.0, size.x - button_size.x)
	var step := usable / float(maxi(_buttons.size() - 1, 1))
	for index in _buttons.size():
		_buttons[index].position = Vector2(left_center + step * index - button_size.x * 0.5, 0.0)
		_buttons[index].size = button_size
	queue_redraw()


func _draw() -> void:
	if _items.is_empty():
		return
	var centers := _node_centers()
	if centers.size() > 1:
		draw_line(centers[0], centers[centers.size() - 1], Color(1, 1, 1, 0.38), 2.0 * _density, true)
	var font := get_theme_default_font()
	var font_size := roundi((14.0 if _compact else 15.0) * _density)
	for index in _items.size():
		var item := _items[index]
		var center := centers[index]
		var selected := StringName(item.get("id", &"")) == _selected_id
		var completed := bool(item.get("completed", false))
		var hovered := index == _hovered_index or _buttons[index].has_focus()
		var fill := BLUE if selected else Color(BLUE, 0.18) if hovered else Color(1, 1, 1, 0.92)
		var stroke := BLUE if selected or hovered else MUTED
		draw_circle(center, (6.0 if selected else 5.0) * _density, fill)
		draw_arc(center, (6.0 if selected else 5.0) * _density, 0.0, TAU, 32, stroke, 2.0 * _density, true)
		if completed and not selected:
			draw_circle(center, 1.8 * _density, Color(1, 1, 1, 0.92))
		var number := "%02d" % int(item.get("number", 0))
		var text_size := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(center.x - text_size.x * 0.5, 52.0 * _density), number,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			BLUE if selected else Color(1, 1, 1, 0.84))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_origin = event.position
			_dragging = true
		else:
			if _dragging and event.position.distance_to(_drag_origin) >= 8.0 * _density:
				_request_nearest(event.position.x)
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		accept_event()


func _request_nearest(local_x: float) -> void:
	var centers := _node_centers()
	if centers.is_empty():
		return
	var nearest := 0
	var nearest_distance := absf(local_x - centers[0].x)
	for index in range(1, centers.size()):
		var distance := absf(local_x - centers[index].x)
		if distance < nearest_distance:
			nearest = index
			nearest_distance = distance
	_request_stage(StringName(_items[nearest].get("id", &"")))


func _node_centers() -> PackedVector2Array:
	var result := PackedVector2Array()
	for button in _buttons:
		result.append(button.position + Vector2(button.size.x * 0.5, 18.0 * _density))
	return result


func _set_hovered(index: int) -> void:
	_hovered_index = index
	queue_redraw()


func _clear_hovered(index: int) -> void:
	if _hovered_index == index:
		_hovered_index = -1
	queue_redraw()
