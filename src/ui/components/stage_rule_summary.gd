class_name StageRuleSummary
extends Control

## Compact, font-independent rule summary shared by stage-selection surfaces.

const BALL_GLYPH_PAINTER := preload("res://src/ui/components/ball_glyph_painter.gd")

var _stage: StageData
var _compact := false
var _density := 1.0
var _foreground_override := Color(0.0, 0.0, 0.0, 0.0)
var _accent_override := Color(0.0, 0.0, 0.0, 0.0)


func configure(stage: StageData) -> void:
	_stage = stage
	tooltip_text = _detail_text()
	accessibility_name = tooltip_text
	queue_redraw()


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0) if compact else 1.0
	custom_minimum_size = Vector2(320.0, 28.0) * _density if compact \
			else Vector2(560.0, 32.0)
	queue_redraw()


func set_foreground(foreground: Color, accent: Color) -> void:
	_foreground_override = foreground
	_accent_override = accent
	queue_redraw()


func detail_text() -> String:
	return tooltip_text


func _draw() -> void:
	if _stage == null:
		return
	var scale := _density if _compact else 1.0
	var font := get_theme_font(&"font", &"WorldBody")
	var font_size := roundi((15.0 if _compact else 18.0) * scale)
	var color := _foreground_override if _foreground_override.a > 0.0 \
			else get_theme_color(&"font_color", &"WorldBody")
	var muted := Color(color, 0.72)
	var accent := _accent_override if _accent_override.a > 0.0 \
			else get_theme_color(&"font_color", &"HudAccentValue")
	var baseline := (size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	var x := 2.0 * scale
	var icon_radius := (6.0 if _compact else 7.0) * scale
	_draw_target_icon(Vector2(x + icon_radius, size.y * 0.5), icon_radius, color, accent)
	x += icon_radius * 2.0 + 8.0 * scale
	var primary := _band_text() if _stage.uses_target_band() \
			else "%.1f%%" % _stage.target_coverage
	x = _draw_text(font, font_size, primary, Vector2(x, baseline), color) + 16.0 * scale
	x = _draw_separator(Vector2(x, size.y * 0.5), muted, scale)
	if _stage.uses_target_band():
		x = _draw_text(font, font_size, "R%s/G%s" % [
			_weight_text(_stage.color_score_rule.red_weight),
			_weight_text(_stage.color_score_rule.green_weight),
		], Vector2(x, baseline), color) + 16.0 * scale
		x = _draw_separator(Vector2(x, size.y * 0.5), muted, scale)
	BALL_GLYPH_PAINTER.draw(self, Vector2(x + icon_radius, size.y * 0.5),
			icon_radius, BallKind.Value.STANDARD, color, color, 1.5 * scale)
	x += icon_radius * 2.0 + 8.0 * scale
	x = _draw_text(font, font_size, "%d" % _stage.maximum_shots,
			Vector2(x, baseline), color) + 16.0 * scale
	if _stage.uses_target_band():
		for kind in _stage.required_ball_kinds_for_clear:
			x = _draw_separator(Vector2(x, size.y * 0.5), muted, scale)
			BALL_GLYPH_PAINTER.draw(self, Vector2(x + icon_radius, size.y * 0.5),
					icon_radius, kind, color, color, 1.5 * scale)
			x += icon_radius * 2.8
	elif not _stage.mechanism_loadout.is_empty():
		x = _draw_separator(Vector2(x, size.y * 0.5), muted, scale)
		_draw_mechanism_icon(Vector2(x + icon_radius, size.y * 0.5), icon_radius, color, scale)
		x += icon_radius * 2.0 + 6.0 * scale
		_draw_text(font, font_size, "%d" % _stage.mechanism_loadout.size(),
				Vector2(x, baseline), color)


func _draw_text(font: Font, font_size: int, value: String, position: Vector2, color: Color) -> float:
	draw_string(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
	return position.x + font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x


func _draw_separator(center: Vector2, color: Color, scale: float) -> float:
	draw_circle(center, 1.5 * scale, color)
	return center.x + 12.0 * scale


func _draw_target_icon(center: Vector2, radius: float, color: Color, accent: Color) -> void:
	draw_circle(center, radius, color)
	draw_circle(center, radius * 0.68, accent)
	draw_circle(center, radius * 0.30, color)


func _draw_mechanism_icon(center: Vector2, radius: float, color: Color, scale: float) -> void:
	for spoke in range(6):
		var direction := Vector2.from_angle(float(spoke) * TAU / 6.0)
		draw_line(center + direction * radius * 0.55,
				center + direction * radius * 1.15, color, 1.5 * scale)
	draw_circle(center, radius * 0.68, color)
	draw_circle(center, radius * 0.28, Color(0.0, 0.0, 0.0, 0.0))


func _detail_text() -> String:
	if _stage == null:
		return ""
	var parts: Array[String] = []
	if _stage.uses_target_band():
		parts.append("%s %s" % [tr("hud.paint_score"), _band_text()])
		parts.append("R %s / G %s" % [
			_weight_text(_stage.color_score_rule.red_weight),
			_weight_text(_stage.color_score_rule.green_weight),
		])
		parts.append(_ball_kind_names())
		if not _stage.required_ball_kinds_for_clear.is_empty():
			parts.append("%s: %s" % [
				tr("hud.finish_use_required_balls"),
				_required_kind_names(),
			])
	else:
		parts.append("%s %.1f%%" % [tr("hud.coverage"), _stage.target_coverage])
		parts.append(_mechanism_names())
	parts.append("%s %d" % [tr("hud.shots"), _stage.maximum_shots])
	parts.append("%s %s" % [tr("hud.time"), _format_duration(_stage.resolved_duration_seconds())])
	return " · ".join(parts)


func _band_text() -> String:
	if _stage == null or _stage.target_band == null:
		return "--"
	return "%s-%s" % [
		_format_number(_stage.target_band.target_min),
		_format_number(_stage.target_band.target_max),
	]


func _ball_kind_names() -> String:
	if _stage.ball_deal_profile == null:
		return ""
	var names: Array[String] = []
	for kind in _stage.ball_deal_profile.allowed_kinds:
		var stable_id := BallKind.stable_id(kind)
		if not stable_id.is_empty():
			names.append(tr("ball.%s" % stable_id))
	return " / ".join(names)


func _required_kind_names() -> String:
	var names: Array[String] = []
	for kind in _stage.required_ball_kinds_for_clear:
		var stable_id := BallKind.stable_id(kind)
		if not stable_id.is_empty():
			names.append(tr("ball.%s" % stable_id))
	return " / ".join(names)


func _mechanism_names() -> String:
	if _stage.mechanism_loadout.is_empty():
		return tr("mechanism.none")
	var names: Array[String] = []
	for mechanism_data in _stage.mechanism_loadout:
		var key := "mechanism.uphill_rebound"
		match mechanism_data.canonical_kind():
			MechanismData.Kind.BURST:
				key = "mechanism.burst"
			MechanismData.Kind.SPLITTER:
				key = "mechanism.splitter"
		names.append(tr(key))
	return " + ".join(names)


func _weight_text(weight: int) -> String:
	return "+%d" % weight if weight > 0 else "-%d" % absi(weight) if weight < 0 else "0"


func _format_number(value: float) -> String:
	return "%d" % roundi(value) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(roundi(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
