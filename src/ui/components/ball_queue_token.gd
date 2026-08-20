class_name BallQueueTokenView
extends Button

## Focusable presentation of one authoritative queue token. The parent queue
## owns the shared description bubble and pin/dismiss policy.

signal description_requested(source: BallQueueTokenView, description: String, pin: bool)
signal description_released(source: BallQueueTokenView)

var _token: BallToken
var _queue_index := 0
var _description := ""
var _compact := false
var _density := 1.0


func _ready() -> void:
	mouse_entered.connect(_request_description.bind(false))
	mouse_exited.connect(_release_description)
	focus_entered.connect(_request_description.bind(false))
	focus_exited.connect(_release_description)
	pressed.connect(_request_description.bind(true))


func configure(token: BallToken, queue_index: int) -> void:
	_token = token
	_queue_index = queue_index
	visible = token != null and token.is_valid()
	if not visible:
		_description = ""
		text = ""
		tooltip_text = ""
		return
	_apply_size()
	text = ""
	add_theme_color_override(&"font_color", PaintChannel.visual_color(token.channel))
	add_theme_color_override(&"font_hover_color", PaintChannel.visual_color(token.channel))
	add_theme_color_override(&"font_pressed_color", PaintChannel.visual_color(token.channel))
	add_theme_color_override(&"font_focus_color", PaintChannel.visual_color(token.channel))
	_description = _build_description()
	# BallQueue owns the single visible description. Native tooltips would show a
	# second delayed message on top of that shared overlay.
	tooltip_text = ""
	accessibility_name = _description
	queue_redraw()


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0)
	add_theme_font_size_override(
		&"font_size", roundi(15.0 * _density) if compact else 14
	)
	_apply_size()
	queue_redraw()


func token() -> BallToken:
	return _token


func queue_index() -> int:
	return _queue_index


func description_text() -> String:
	return _description


func channel_label() -> String:
	return PaintChannel.short_label(_token.channel) if _token != null and _token.is_valid() else ""


func request_description_for_test(pin: bool = false) -> void:
	_request_description(pin)


func release_description_for_test() -> void:
	_release_description()


func _request_description(pin: bool) -> void:
	if not visible or _description.is_empty():
		return
	description_requested.emit(self, _description, pin)


func _release_description() -> void:
	description_released.emit(self)


func _build_description() -> String:
	var position_name := tr("hud.now") if _queue_index == 0 else "%s %d" % [tr("hud.next"), _queue_index]
	var kind_id := BallKind.stable_id(_token.kind)
	var kind_name := tr("ball.%s" % kind_id)
	var channel_name := tr("paint.%s" % PaintChannel.stable_id(_token.channel))
	var behavior_key := "ball.%s.description" % kind_id
	return "%s · %s · %s\n%s" % [position_name, kind_name, channel_name, tr(behavior_key)]


func _draw() -> void:
	if _token == null or not _token.is_valid():
		return
	var color := PaintChannel.visual_color(_token.channel)
	var outline := get_theme_color(&"outline", &"BallQueueToken")
	var draw_density := _density if _compact else 1.0
	var radius := (7.0 if _queue_index == 0 else 5.5) * draw_density
	var center := Vector2(
		(16.0 if _queue_index == 0 else 14.0) * draw_density,
		size.y * 0.5
	)
	match _token.kind:
		BallKind.Value.IMPACT_BURST:
			for spoke in range(8):
				var direction := Vector2.from_angle(float(spoke) * TAU / 8.0)
				draw_line(center + direction * radius * 0.5,
						center + direction * radius * 1.35, outline, 2.0)
			draw_circle(center, radius * 0.72, outline)
			draw_circle(center, radius * 0.54, color)
		BallKind.Value.APEX_SPLIT:
			for angle in [-PI * 0.5, PI / 6.0, PI * 5.0 / 6.0]:
				var lobe_center := center + Vector2.from_angle(angle) * radius * 0.62
				draw_circle(lobe_center, radius * 0.55, outline)
				draw_circle(lobe_center, radius * 0.40, color)
		_:
			draw_circle(center, radius, outline)
			draw_circle(center, radius * 0.76, color)
	var label := channel_label()
	var font := get_theme_font(&"font", &"BallQueueToken")
	var font_size := get_theme_font_size(&"font_size", &"BallQueueToken")
	var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline := (size.y - label_size.y) * 0.5 + font.get_ascent(font_size)
	draw_string(
		font,
		Vector2(size.x - label_size.x - 6.0, baseline),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)


func _apply_size() -> void:
	var base := Vector2(52.0, 52.0) if _queue_index == 0 else Vector2(44.0, 44.0)
	custom_minimum_size = base * (_density if _compact else 1.0)
