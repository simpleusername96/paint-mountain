class_name ScoreScale
extends Control

## One fixed 0-100 score axis for live HUD instruments and result summaries.
## The component draws geometry from authoritative values; it never owns score rules.

enum Preset {
	VERTICAL_LIVE,
	HORIZONTAL_SUMMARY,
}

const DOMAIN_MINIMUM := 0.0
const DOMAIN_MAXIMUM := 100.0
const TICKS := [100.0, 75.0, 50.0, 25.0, 0.0]

@export var preset := Preset.VERTICAL_LIVE

@onready var _metric_icon: TextureRect = %MetricIcon
@onready var _current_value: Label = %CurrentValue
@onready var _contributions: HBoxContainer = %Contributions
@onready var _red: Label = %Red
@onready var _green: Label = %Green

var _value := 0.0
var _target_minimum := 0.0
var _target_maximum := 100.0
var _threshold_mode := true
var _show_percent := true
var _compact := false
var _world_mode := false


func _ready() -> void:
	resized.connect(_layout)
	_layout()


func set_preset(value: Preset) -> void:
	preset = value
	_apply_minimum_size()
	_layout()


func set_compact(compact: bool) -> void:
	_compact = compact
	_apply_minimum_size()
	_layout()


func set_world_mode(enabled: bool) -> void:
	_world_mode = enabled
	_current_value.theme_type_variation = &"ResultWorldValue" if enabled else &"HudValue"
	for index in TICKS.size():
		_tick_label(index).theme_type_variation = &"WorldCaption" if enabled else &"HudCaption"
	for contribution in [_red, _green]:
		if enabled:
			contribution.add_theme_color_override(
				&"font_outline_color", get_theme_color(&"world_outline", &"ScoreScale")
			)
			contribution.add_theme_constant_override(
				&"outline_size", get_theme_constant(&"world_outline_size", &"ScoreScale")
			)
		else:
			contribution.remove_theme_color_override(&"font_outline_color")
			contribution.remove_theme_constant_override(&"outline_size")
	queue_redraw()


func configure_coverage(target: float) -> void:
	_threshold_mode = true
	_target_minimum = clampf(target, DOMAIN_MINIMUM, DOMAIN_MAXIMUM)
	_target_maximum = DOMAIN_MAXIMUM
	_show_percent = true
	_contributions.hide()
	_apply_accessibility()
	queue_redraw()


func configure_target_band(target_band: TargetBandData, _score_rule: ColorScoreRuleData) -> void:
	_threshold_mode = false
	_target_minimum = clampf(target_band.target_min, DOMAIN_MINIMUM, DOMAIN_MAXIMUM)
	_target_maximum = clampf(target_band.target_max, _target_minimum, DOMAIN_MAXIMUM)
	_show_percent = false
	_contributions.show()
	_apply_accessibility()
	queue_redraw()


func update_coverage(value: float) -> void:
	set_value(value)


func update_target_band(
		snapshot: PaintCoverageSnapshot,
		score: float,
		red_weight: int,
		green_weight: int
) -> void:
	set_value(score)
	_red.text = "R %s %.1f" % [_sign(red_weight), snapshot.red_percent]
	_green.text = "G %s %.1f" % [_sign(green_weight), snapshot.green_percent]
	_red.add_theme_color_override(&"font_color", get_theme_color(&"red", &"ScoreScale"))
	_green.add_theme_color_override(&"font_color", get_theme_color(&"green", &"ScoreScale"))
	_apply_accessibility()


func set_value(value: float) -> void:
	_value = value
	_current_value.text = "%s%s" % [_format_value(_value), "%" if _show_percent else ""]
	_apply_accessibility()
	queue_redraw()


func value() -> float:
	return _value


func marker_value_for_test() -> float:
	return clampf(_value, DOMAIN_MINIMUM, DOMAIN_MAXIMUM)


func range_overflow_direction_for_test() -> int:
	return _range_overflow_direction()


func target_range() -> Vector2:
	return Vector2(_target_minimum, _target_maximum)


func marker_position_for_test() -> Vector2:
	return _point_for_value(_value)


func target_rect_for_test() -> Rect2:
	return _target_rect()


func track_rect_for_test() -> Rect2:
	return _track_rect()


func _layout() -> void:
	if not is_node_ready():
		return
	if preset == Preset.VERTICAL_LIVE:
		_layout_vertical()
	else:
		_layout_horizontal()
	queue_redraw()


func _apply_minimum_size() -> void:
	if preset == Preset.VERTICAL_LIVE:
		custom_minimum_size = Vector2(112.0, 272.0) if _compact else Vector2(132.0, 410.0)
	else:
		custom_minimum_size = Vector2(360.0, 78.0) if _compact else Vector2(440.0, 118.0)


func _layout_vertical() -> void:
	_metric_icon.hide()
	_current_value.position = Vector2(0.0, 0.0)
	_current_value.size = Vector2(72.0, 30.0)
	var track := _track_rect()
	for index in TICKS.size():
		var label := _tick_label(index)
		label.position = Vector2(track.end.x + 10.0, _point_for_value(TICKS[index]).y - 11.0)
		label.size = Vector2(42.0, 22.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_contributions.position = Vector2(0.0, size.y - 26.0)
	_contributions.size = Vector2(size.x, 24.0)


func _layout_horizontal() -> void:
	_metric_icon.show()
	_metric_icon.position = Vector2(0.0, 2.0)
	_metric_icon.size = Vector2(20.0, 20.0)
	_current_value.position = Vector2(26.0, 0.0)
	_current_value.size = Vector2(92.0, 30.0)
	var track := _track_rect()
	for index in TICKS.size():
		var label := _tick_label(index)
		label.position = Vector2(_point_for_value(TICKS[index]).x - 22.0, track.end.y + 5.0)
		label.size = Vector2(44.0, 22.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contributions.position = Vector2(maxf(130.0, size.x - 184.0), 0.0)
	_contributions.size = Vector2(184.0, 24.0)


func _draw() -> void:
	var track := _track_rect()
	draw_rect(track, _scale_color(&"track"))
	var target := _target_rect()
	draw_rect(target, get_theme_color(&"target", &"ScoreScale"))
	var edge_color := get_theme_color(&"target_edge", &"ScoreScale")
	if preset == Preset.VERTICAL_LIVE:
		if _threshold_mode:
			draw_line(Vector2(target.position.x - 4.0, target.end.y),
					Vector2(target.end.x + 4.0, target.end.y), edge_color, 2.0)
		else:
			draw_line(Vector2(target.position.x - 4.0, target.position.y),
					Vector2(target.end.x + 4.0, target.position.y), edge_color, 2.0)
			draw_line(Vector2(target.position.x - 4.0, target.end.y),
					Vector2(target.end.x + 4.0, target.end.y), edge_color, 2.0)
	else:
		if _threshold_mode:
			draw_line(Vector2(target.position.x, target.position.y - 4.0),
					Vector2(target.position.x, target.end.y + 4.0), edge_color, 2.0)
		else:
			draw_line(Vector2(target.position.x, target.position.y - 4.0),
					Vector2(target.position.x, target.end.y + 4.0), edge_color, 2.0)
			draw_line(Vector2(target.end.x, target.position.y - 4.0),
					Vector2(target.end.x, target.end.y + 4.0), edge_color, 2.0)
	var tick_color := _scale_color(&"tick")
	for tick in TICKS:
		var point := _point_for_value(tick)
		if preset == Preset.VERTICAL_LIVE:
			draw_line(Vector2(track.position.x - 3.0, point.y),
					Vector2(track.end.x + 3.0, point.y), tick_color, 1.0)
		else:
			draw_line(Vector2(point.x, track.position.y - 3.0),
					Vector2(point.x, track.end.y + 3.0), tick_color, 1.0)
	var marker := _point_for_value(_value)
	var marker_color := _scale_color(&"marker")
	if preset == Preset.VERTICAL_LIVE:
		draw_line(Vector2(track.position.x - 8.0, marker.y),
				Vector2(track.end.x + 8.0, marker.y), marker_color, 3.0)
	else:
		draw_line(Vector2(marker.x, track.position.y - 8.0),
				Vector2(marker.x, track.end.y + 8.0), marker_color, 3.0)
	_draw_range_overflow(track, marker_color)


func _track_rect() -> Rect2:
	if preset == Preset.VERTICAL_LIVE:
		return Rect2(24.0, 44.0, 24.0, maxf(160.0, size.y - 80.0))
	return Rect2(16.0, 34.0 if _compact else 42.0, maxf(160.0, size.x - 32.0), 14.0)


func _target_rect() -> Rect2:
	var track := _track_rect()
	var minimum_point := _point_for_value(_target_minimum)
	var maximum_point := _point_for_value(_target_maximum)
	if preset == Preset.VERTICAL_LIVE:
		return Rect2(track.position.x, maximum_point.y, track.size.x,
				maxf(2.0, minimum_point.y - maximum_point.y))
	return Rect2(minimum_point.x, track.position.y,
			maxf(2.0, maximum_point.x - minimum_point.x), track.size.y)


func _point_for_value(value: float) -> Vector2:
	var track := _track_rect()
	var normalized := clampf(value / DOMAIN_MAXIMUM, 0.0, 1.0)
	if preset == Preset.VERTICAL_LIVE:
		return Vector2(track.get_center().x, lerpf(track.end.y, track.position.y, normalized))
	return Vector2(lerpf(track.position.x, track.end.x, normalized), track.get_center().y)


func _tick_label(index: int) -> Label:
	return get_node("Tick%d" % int(TICKS[index])) as Label


func _scale_color(role: StringName) -> Color:
	var resolved := StringName("world_%s" % role) if _world_mode \
			and role in [&"track", &"marker", &"tick"] else role
	return get_theme_color(resolved, &"ScoreScale")


func _draw_range_overflow(track: Rect2, color: Color) -> void:
	var direction := _range_overflow_direction()
	if direction == 0:
		return
	var points := PackedVector2Array()
	if preset == Preset.VERTICAL_LIVE:
		var endpoint_y := track.position.y if direction > 0 else track.end.y
		var base_y := endpoint_y + 8.0 if direction > 0 else endpoint_y - 8.0
		points = PackedVector2Array([
			Vector2(track.get_center().x, endpoint_y),
			Vector2(track.get_center().x - 7.0, base_y),
			Vector2(track.get_center().x + 7.0, base_y),
		])
	else:
		var endpoint_x := track.end.x if direction > 0 else track.position.x
		var base_x := endpoint_x - 8.0 if direction > 0 else endpoint_x + 8.0
		points = PackedVector2Array([
			Vector2(endpoint_x, track.get_center().y),
			Vector2(base_x, track.get_center().y - 7.0),
			Vector2(base_x, track.get_center().y + 7.0),
		])
	draw_colored_polygon(points, color)


func _range_overflow_direction() -> int:
	return -1 if _value < DOMAIN_MINIMUM else 1 if _value > DOMAIN_MAXIMUM else 0


func _sign(weight: int) -> String:
	return "+" if weight > 0 else "−" if weight < 0 else "0"


func _format_value(value: float) -> String:
	var rounded := snappedf(value, 0.1)
	return "%.1f" % (0.0 if is_zero_approx(rounded) else rounded)


func _apply_accessibility() -> void:
	var target_text := "%.1f–%.1f" % [_target_minimum, _target_maximum]
	var range_state := ""
	if _value < DOMAIN_MINIMUM:
		range_state = "; %s" % tr("hud.score_below_scale")
	elif _value > DOMAIN_MAXIMUM:
		range_state = "; %s" % tr("hud.score_above_scale")
	tooltip_text = "%s %s; %s %s%s" % [
		tr("hud.paint_score") if not _show_percent else tr("hud.coverage"),
		_format_value(_value),
		tr("hud.target_band") if not _threshold_mode else tr("hud.target"),
		target_text if not _threshold_mode else "%.1f" % _target_minimum,
		range_state,
	]
	accessibility_name = tooltip_text
