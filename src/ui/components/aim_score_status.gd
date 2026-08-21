class_name AimScoreStatus
extends Control

## Live score instrument. Aim shows only the authored success range and its
## star tiers; Map and Follow collapse to an exact numeric readout.

enum Presentation {
	AIM_RANGE,
	COMPACT_VALUE,
}

const STAR_TEXTURE := preload("res://assets/ui/icons/status/star.png")
const PAINT_TEXTURE := preload("res://assets/ui/icons/paint_splash.svg")
const TARGET_TEXTURE := preload("res://assets/ui/icons/target.png")
const STAR_TIERS := [1, 2, 3, 2, 1]
const INK := Color("172538")
const ACCENT := Color("2584FF")
const RED := Color("E53935")
const GREEN := Color("249447")

@export var presentation := Presentation.AIM_RANGE

var _target_minimum := 0.0
var _target_maximum := 100.0
var _score := 0.0
var _paint_percent := 0.0
var _red_percent := 0.0
var _green_percent := 0.0
var _red_weight := 0
var _green_weight := 0
var _show_color_roles := false
var _compact := false
var _density := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	_apply_minimum_size()
	_apply_accessibility()


func configure_coverage(target: float) -> void:
	_target_minimum = clampf(target, 0.0, 100.0)
	_target_maximum = 100.0
	_red_weight = 0
	_green_weight = 0
	_show_color_roles = false
	_apply_accessibility()
	queue_redraw()


func configure_target_band(target_band: TargetBandData, score_rule: ColorScoreRuleData) -> void:
	if target_band == null or score_rule == null:
		return
	_target_minimum = target_band.target_min
	_target_maximum = maxf(target_band.target_max, target_band.target_min)
	_red_weight = score_rule.red_weight
	_green_weight = score_rule.green_weight
	_show_color_roles = true
	_apply_accessibility()
	queue_redraw()


func update_coverage(value: float) -> void:
	_score = value
	_paint_percent = value
	_apply_accessibility()
	queue_redraw()


func update_target_band(
		snapshot: PaintCoverageSnapshot,
		score: float,
		red_weight: int,
		green_weight: int
) -> void:
	_score = score
	_paint_percent = snapshot.total_percent
	_red_percent = snapshot.red_percent
	_green_percent = snapshot.green_percent
	_red_weight = red_weight
	_green_weight = green_weight
	_show_color_roles = true
	_apply_accessibility()
	queue_redraw()


func set_presentation(value: Presentation) -> void:
	presentation = value
	_apply_minimum_size()
	_apply_accessibility()
	queue_redraw()


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0) if compact else 1.0
	_apply_minimum_size()
	queue_redraw()


func target_range() -> Vector2:
	return Vector2(_target_minimum, _target_maximum)


func marker_normalized_for_test() -> float:
	return clampf(inverse_lerp(_target_minimum, _target_maximum, _score), 0.0, 1.0)


func overflow_direction_for_test() -> int:
	return -1 if _score < _target_minimum else 1 if _score > _target_maximum else 0


func paint_percent_for_test() -> float:
	return _paint_percent


func color_role_weights_for_test() -> Vector2i:
	return Vector2i(_red_weight, _green_weight)


func _draw() -> void:
	if presentation == Presentation.COMPACT_VALUE:
		_draw_compact_value()
	else:
		_draw_aim_range()


func _draw_aim_range() -> void:
	var scale := _density
	var font := get_theme_font(&"font", &"HudBody")
	var body_size := roundi(18.0 * scale)
	var caption_size := roundi(14.0 * scale)
	var track := Rect2(62.0 * scale, 50.0 * scale,
			maxf(240.0 * scale, size.x - 84.0 * scale), 18.0 * scale)
	var segment_width := track.size.x / float(STAR_TIERS.size())
	for index in STAR_TIERS.size():
		var segment := Rect2(
			Vector2(track.position.x + segment_width * index, track.position.y),
			Vector2(segment_width, track.size.y)
		)
		draw_rect(segment, Color(ACCENT, 0.24 + 0.12 * STAR_TIERS[index]))
		draw_rect(segment, Color(1.0, 1.0, 1.0, 0.84), false, 1.0 * scale)
		_draw_star_tier(segment.get_center().x, 16.0 * scale, STAR_TIERS[index], scale)
	draw_string(font, Vector2(track.position.x, 43.0 * scale), _format_number(_target_minimum),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, caption_size, INK)
	var maximum_text := _format_number(_target_maximum)
	var maximum_width := font.get_string_size(maximum_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, caption_size).x
	draw_string(font, Vector2(track.end.x - maximum_width, 43.0 * scale), maximum_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, caption_size, INK)
	_draw_score_marker(track, font, caption_size, scale)

	var paint_rect := Rect2(2.0 * scale, 92.0 * scale, 30.0 * scale, 30.0 * scale)
	draw_texture_rect(PAINT_TEXTURE, paint_rect, false, INK)
	draw_string(font, Vector2(40.0 * scale, 116.0 * scale),
			"%s%%" % _format_number(_paint_percent), HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, body_size, INK)
	if _show_color_roles:
		var role_y := 150.0 * scale
		draw_texture_rect(PAINT_TEXTURE,
				Rect2(2.0 * scale, 128.0 * scale, 30.0 * scale, 30.0 * scale), false, RED)
		draw_string(font, Vector2(40.0 * scale, role_y), _weight_text(_red_weight),
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, body_size, INK)
		draw_texture_rect(TARGET_TEXTURE,
				Rect2(130.0 * scale, 128.0 * scale, 28.0 * scale, 28.0 * scale), false, GREEN)
		draw_string(font, Vector2(166.0 * scale, role_y), _weight_text(_green_weight),
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, body_size, INK)


func _draw_compact_value() -> void:
	var scale := _density
	var font := get_theme_font(&"font", &"HudBody")
	var font_size := roundi(18.0 * scale)
	var row_gap := 30.0 * scale
	var baseline := 23.0 * scale
	var value_x := 78.0 * scale
	draw_string(font, Vector2(0.0, baseline), tr("hud.now"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)
	draw_string(font, Vector2(value_x, baseline), _format_score(_score),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)
	draw_string(font, Vector2(0.0, baseline + row_gap), tr("hud.target_band"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)
	draw_string(font, Vector2(value_x, baseline + row_gap), "%s–%s" % [
		_format_number(_target_minimum), _format_number(_target_maximum)
	], HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)
	if _show_color_roles:
		draw_texture_rect(PAINT_TEXTURE,
				Rect2(0.0, baseline + row_gap * 2.0 - 20.0 * scale,
						20.0 * scale, 20.0 * scale), false, RED)
		draw_string(font, Vector2(28.0 * scale, baseline + row_gap * 2.0),
				_signed_value(_red_percent), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)
		draw_texture_rect(TARGET_TEXTURE,
				Rect2(0.0, baseline + row_gap * 3.0 - 20.0 * scale,
						20.0 * scale, 20.0 * scale), false, GREEN)
		draw_string(font, Vector2(28.0 * scale, baseline + row_gap * 3.0),
				_signed_value(_green_percent), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)


func _draw_star_tier(center_x: float, center_y: float, count: int, scale: float) -> void:
	var icon_edge := 14.0 * scale
	var gap := 2.0 * scale
	var width := icon_edge * count + gap * maxi(0, count - 1)
	var left := center_x - width * 0.5
	for index in count:
		draw_texture_rect(STAR_TEXTURE,
				Rect2(left + (icon_edge + gap) * index, center_y - icon_edge * 0.5,
						icon_edge, icon_edge), false, ACCENT)


func _draw_score_marker(track: Rect2, font: Font, font_size: int, scale: float) -> void:
	var direction := overflow_direction_for_test()
	var normalized := marker_normalized_for_test()
	var marker_x := lerpf(track.position.x, track.end.x, normalized)
	draw_line(Vector2(marker_x, track.position.y - 3.0 * scale),
			Vector2(marker_x, track.end.y + 3.0 * scale), ACCENT, 2.0 * scale)
	var triangle := PackedVector2Array()
	if direction < 0:
		triangle = PackedVector2Array([
			Vector2(track.position.x - 8.0 * scale, track.get_center().y),
			Vector2(track.position.x - 2.0 * scale, track.position.y),
			Vector2(track.position.x - 2.0 * scale, track.end.y),
		])
	elif direction > 0:
		triangle = PackedVector2Array([
			Vector2(track.end.x + 8.0 * scale, track.get_center().y),
			Vector2(track.end.x + 2.0 * scale, track.position.y),
			Vector2(track.end.x + 2.0 * scale, track.end.y),
		])
	else:
		triangle = PackedVector2Array([
			Vector2(marker_x, track.end.y + 7.0 * scale),
			Vector2(marker_x - 5.0 * scale, track.end.y + 1.0 * scale),
			Vector2(marker_x + 5.0 * scale, track.end.y + 1.0 * scale),
		])
	draw_colored_polygon(triangle, ACCENT)
	var score_text := _format_score(_score)
	var score_width := font.get_string_size(score_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var score_x := 0.0 if direction < 0 else size.x - score_width if direction > 0 \
			else clampf(marker_x - score_width * 0.5, 0.0, size.x - score_width)
	draw_string(font, Vector2(score_x, track.end.y + 17.0 * scale), score_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, ACCENT)


func _apply_minimum_size() -> void:
	custom_minimum_size = (Vector2(300.0 if _compact else 600.0, 164.0)
			if presentation == Presentation.AIM_RANGE else Vector2(190.0, 126.0)) * _density


func _apply_accessibility() -> void:
	var parts: Array[String] = [
		"%s %s" % [tr("hud.paint_score"), _format_number(_score)],
		"%s %s–%s" % [tr("hud.target_band"), _format_number(_target_minimum),
				_format_number(_target_maximum)],
		"%s %s%%" % [tr("hud.total"), _format_number(_paint_percent)],
	]
	if _show_color_roles:
		parts.append("R %s %.1f" % [_weight_text(_red_weight), _red_percent])
		parts.append("G %s %.1f" % [_weight_text(_green_weight), _green_percent])
	accessibility_name = "; ".join(parts)
	tooltip_text = accessibility_name


func _weight_text(weight: int) -> String:
	return "+%d" % weight if weight > 0 else "−%d" % absi(weight) if weight < 0 else "0"


func _signed_value(value: float) -> String:
	return "%+.1f" % value


func _format_number(value: float) -> String:
	return "%d" % roundi(value) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _format_score(value: float) -> String:
	return "%.1f" % value
