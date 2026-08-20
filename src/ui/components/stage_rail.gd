class_name StageRail
extends HBoxContainer

signal stage_requested(stage_id: StringName)
signal previous_page_requested
signal next_page_requested

@onready var _previous: Button = %Previous
@onready var _next: Button = %Next
@onready var _nodes: HBoxContainer = %Nodes

var _selected_id := &""


func _ready() -> void:
	_previous.pressed.connect(func() -> void: previous_page_requested.emit())
	_next.pressed.connect(func() -> void: next_page_requested.emit())
	refresh_locale()


func configure(items: Array[Dictionary], selected_id: StringName) -> void:
	_selected_id = selected_id
	for child in _nodes.get_children():
		child.queue_free()
	for item in items:
		var button := Button.new()
		var stage_id := StringName(item.get("id", &""))
		var stage_number := int(item.get("number", 0))
		var stage_name := String(item.get("name", ""))
		var locked := bool(item.get("locked", false))
		var completed := bool(item.get("completed", false))
		button.custom_minimum_size = Vector2(44.0, 44.0)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.button_pressed = stage_id == selected_id
		button.disabled = locked
		button.theme_type_variation = &"StageRailButton"
		button.text = str(stage_number)
		var state := "✓" if completed else "—"
		button.tooltip_text = "%02d · %s · %s" % [stage_number, stage_name, state]
		button.accessibility_name = button.tooltip_text
		button.pressed.connect(_request_stage.bind(stage_id))
		_nodes.add_child(button)


func set_page_availability(has_previous: bool, has_next: bool) -> void:
	_previous.disabled = not has_previous
	_next.disabled = not has_next


func refresh_locale() -> void:
	_previous.tooltip_text = tr("ui.previous")
	_next.tooltip_text = tr("ui.next")
	_previous.accessibility_name = _previous.tooltip_text
	_next.accessibility_name = _next.tooltip_text


func _request_stage(stage_id: StringName) -> void:
	stage_requested.emit(stage_id)
