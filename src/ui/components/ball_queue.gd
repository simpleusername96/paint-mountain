class_name BallQueue
extends Control

## Shared queue presentation. Hover, keyboard focus, and press all publish the
## same description; press pins it until Escape or a second press.

signal detail_visibility_changed(visible: bool)

@onready var _description_card: Panel = %DescriptionCard
@onready var _description_icon: TextureRect = %DescriptionIcon
@onready var _description: Label = %Description
@onready var _tokens: Array[BallQueueTokenView] = [%NowToken, %NextOne, %NextTwo]

var _pinned_source: BallQueueTokenView
var _active_source: BallQueueTokenView
var _compact := false
var _density := 1.0
var _card_hovered := false
var _release_generation := 0


func _ready() -> void:
	resized.connect(_layout_description)
	for token_view in _tokens:
		token_view.description_requested.connect(_show_description)
		token_view.description_released.connect(_release_description)
	_description_card.mouse_entered.connect(_on_card_mouse_entered)
	_description_card.mouse_exited.connect(_on_card_mouse_exited)
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
		280.0 * _density if compact else 420.0,
		172.0 * _density if compact else 172.0
	)
	_description.add_theme_font_size_override(
		&"font_size", roundi(16.0 * _density) if compact else 16
	)
	_description.add_theme_constant_override(&"outline_size", 0)
	for token_view in _tokens:
		token_view.set_compact(compact, _density)
	_layout_description.call_deferred()


func token_views() -> Array[BallQueueTokenView]:
	return _tokens


func description_visible() -> bool:
	return _description_card.visible


func description_value() -> String:
	return _description.text


func dismiss_description() -> void:
	var was_visible := _description_card.visible
	_pinned_source = null
	_active_source = null
	_release_generation += 1
	_description_card.hide()
	_description.text = ""
	if was_visible:
		detail_visibility_changed.emit(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _description_card.visible:
		dismiss_description()
		get_viewport().set_input_as_handled()


func _show_description(source: BallQueueTokenView, text: String, pin: bool) -> void:
	if pin and _pinned_source == source:
		dismiss_description()
		return
	_active_source = source
	_release_generation += 1
	if pin:
		_pinned_source = source
	_description.text = text
	var token := source.token()
	_description_icon.modulate = PaintChannel.visual_color(token.channel) \
			if token != null and token.is_valid() else Color.WHITE
	_description_card.show()
	detail_visibility_changed.emit(true)
	_layout_description.call_deferred()


func _release_description(source: BallQueueTokenView) -> void:
	if _pinned_source != null or _active_source != source:
		return
	_release_generation += 1
	var generation := _release_generation
	await get_tree().create_timer(0.08).timeout
	if generation != _release_generation or _card_hovered or _pinned_source != null:
		return
	_active_source = null
	_description_card.hide()
	_description.text = ""
	detail_visibility_changed.emit(false)


func _layout_description() -> void:
	if not is_node_ready() or _tokens.is_empty():
		return
	var source := _active_source if _active_source != null else _tokens[0]
	var token_rect := source.get_global_rect()
	var token_x := token_rect.position.x - get_global_rect().position.x
	var card_width := minf(390.0 * _density, size.x)
	var local_x := clampf(token_x + token_rect.size.x * 0.5 - card_width * 0.72,
			0.0, maxf(size.x - card_width, 0.0))
	var token_bottom := token_rect.end.y - get_global_rect().position.y
	_description_card.position = Vector2(local_x, token_bottom + 8.0 * _density)
	_description_card.size = Vector2(card_width, 88.0 * _density)


func _on_card_mouse_entered() -> void:
	_card_hovered = true
	_release_generation += 1


func _on_card_mouse_exited() -> void:
	_card_hovered = false
	if _pinned_source == null:
		dismiss_description()


func _queue_accessibility_text() -> String:
	var descriptions: Array[String] = []
	for token_view in _tokens:
		if token_view.visible:
			descriptions.append(token_view.description_text().replace("\n", " "))
	return "; ".join(descriptions)
