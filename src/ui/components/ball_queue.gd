class_name BallQueue
extends Control

## Shared queue presentation. Hover, keyboard focus, and press all publish the
## same description; press pins it until Escape or a second press.

@onready var _description: Label = %Description
@onready var _tokens: Array[BallQueueTokenView] = [%NowToken, %NextOne, %NextTwo]

var _pinned_source: BallQueueTokenView
var _active_source: BallQueueTokenView
var _compact := false
var _density := 1.0


func _ready() -> void:
	resized.connect(_layout_description)
	for token_view in _tokens:
		token_view.description_requested.connect(_show_description)
		token_view.description_released.connect(_release_description)
	_layout_description.call_deferred()


func configure(tokens: Array[BallToken]) -> void:
	dismiss_description()
	for index in _tokens.size():
		_tokens[index].configure(tokens[index] if index < tokens.size() else null, index)
	accessibility_name = _queue_accessibility_text()


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0)
	custom_minimum_size = Vector2(
		420.0 * _density if compact else 420.0,
		124.0 * _density if compact else 124.0
	)
	_description.add_theme_font_size_override(
		&"font_size", roundi(16.0 * _density) if compact else 16
	)
	for token_view in _tokens:
		token_view.set_compact(compact, _density)
	_layout_description.call_deferred()


func token_views() -> Array[BallQueueTokenView]:
	return _tokens


func description_visible() -> bool:
	return _description.visible


func description_value() -> String:
	return _description.text


func dismiss_description() -> void:
	_pinned_source = null
	_active_source = null
	_description.hide()
	_description.text = ""


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
	_description.text = text
	_description.show()
	_layout_description.call_deferred()


func _release_description(source: BallQueueTokenView) -> void:
	if _pinned_source != null or _active_source != source:
		return
	_active_source = null
	_description.hide()
	_description.text = ""


func _layout_description() -> void:
	if not is_node_ready() or _tokens.is_empty():
		return
	var token_rect := _tokens[0].get_global_rect()
	var token_x := token_rect.position.x - get_global_rect().position.x
	var local_x := maxf(0.0, token_x - 180.0 * _density)
	var token_bottom := token_rect.end.y - get_global_rect().position.y
	_description.position = Vector2(local_x, token_bottom + 6.0 * _density)
	_description.size = Vector2(
		minf(320.0 * _density, maxf(size.x - local_x, 1.0)),
		48.0 * _density
	)


func _queue_accessibility_text() -> String:
	var descriptions: Array[String] = []
	for token_view in _tokens:
		if token_view.visible:
			descriptions.append(token_view.description_text().replace("\n", " "))
	return "; ".join(descriptions)
