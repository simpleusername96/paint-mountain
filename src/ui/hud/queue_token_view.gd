class_name QueueTokenView
extends PanelContainer

@onready var _label: Label = %TokenLabel
var _token: BallToken
var _is_now := false

func configure(token: BallToken, now: bool = false) -> void:
	visible = token != null and token.is_valid()
	_token = token
	_is_now = now
	queue_redraw()
	if not visible:
		return
	var channel := "R" if token.channel == PaintChannel.Value.RED else "G"
	_label.text = channel
	_label.add_theme_color_override("font_color", PaintChannel.visual_color(token.channel))
	var position_name := tr("hud.now") if now else tr("hud.next")
	var kind_name := tr("ball.%s" % BallKind.stable_id(token.kind))
	var channel_name := tr("paint.%s" % PaintChannel.stable_id(token.channel))
	tooltip_text = "%s · %s (%s)" % [kind_name, channel_name, channel]
	_label.tooltip_text = tooltip_text
	_label.accessibility_name = "%s: %s" % [position_name, tooltip_text]


func _draw() -> void:
	if _token == null or not _token.is_valid():
		return
	var color := PaintChannel.visual_color(_token.channel)
	var outline := Color(0.09, 0.145, 0.22, 0.36)
	var radius := 7.0 if _is_now else 5.0
	var center := Vector2(size.x * 0.36, size.y * 0.5)
	match _token.kind:
		BallKind.Value.IMPACT_BURST:
			for spoke in range(8):
				var direction := Vector2.from_angle(float(spoke) * TAU / 8.0)
				draw_line(center + direction * radius * 0.5,
					center + direction * radius * 1.35, outline, 3.0)
			draw_circle(center, radius * 0.72, outline)
			draw_circle(center, radius * 0.56, color)
		BallKind.Value.APEX_SPLIT:
			for angle in [-PI * 0.5, PI / 6.0, PI * 5.0 / 6.0]:
				var lobe_center := center + Vector2.from_angle(angle) * radius * 0.62
				draw_circle(lobe_center, radius * 0.55, outline)
				draw_circle(lobe_center, radius * 0.43, color)
		_:
			draw_circle(center, radius, outline)
			draw_circle(center, radius * 0.78, color)
