class_name BallQueue
extends Control

## Shared queue presentation. Hover, keyboard focus, and press all publish the
## same description; press pins it until Escape or a second press.

@onready var _token_box: BoxContainer = %TokenBox
@onready var _description: PanelContainer = %Description
@onready var _description_text: Label = %Text
@onready var _tokens: Array[BallQueueTokenView] = [%NowToken, %NextOne, %NextTwo]

var _pinned_source: BallQueueTokenView
var _active_source: BallQueueTokenView


func _ready() -> void:
	for token_view in _tokens:
		token_view.description_requested.connect(_show_description)
		token_view.description_released.connect(_release_description)


func configure(tokens: Array[BallToken]) -> void:
	dismiss_description()
	for index in _tokens.size():
		_tokens[index].configure(tokens[index] if index < tokens.size() else null, index)
	accessibility_name = _queue_accessibility_text()


func set_vertical(vertical: bool) -> void:
	_token_box.vertical = vertical
	custom_minimum_size = Vector2(172.0, 180.0) if vertical else Vector2(260.0, 104.0)


func token_views() -> Array[BallQueueTokenView]:
	return _tokens


func description_visible() -> bool:
	return _description.visible


func description_value() -> String:
	return _description_text.text


func dismiss_description() -> void:
	_pinned_source = null
	_active_source = null
	_description.hide()
	_description_text.text = ""


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _description.visible:
		dismiss_description()
		get_viewport().set_input_as_handled()


func _show_description(source: BallQueueTokenView, text: String, pin: bool) -> void:
	if pin and _pinned_source == source:
		dismiss_description()
		return
	_active_source = source
	if pin:
		_pinned_source = source
	_description_text.text = text
	_description.show()


func _release_description(source: BallQueueTokenView) -> void:
	if _pinned_source != null or _active_source != source:
		return
	_active_source = null
	_description.hide()
	_description_text.text = ""


func _queue_accessibility_text() -> String:
	var descriptions: Array[String] = []
	for token_view in _tokens:
		if token_view.visible:
			descriptions.append(token_view.description_text().replace("\n", " "))
	return "; ".join(descriptions)
