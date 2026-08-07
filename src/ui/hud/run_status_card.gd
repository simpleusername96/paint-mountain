class_name RunStatusCard
extends PanelContainer

signal finish_requested

enum DepthCue {
	NONE,
	INTO_SCREEN,
	OUT_OF_SCREEN,
}

var _shots_remaining := 0
var _resident_total := 0
var _moving_residents := 0
var _resting_residents := 0
var _has_resident_breakdown := false
var _remaining_seconds := 0.0
var _duration_seconds := 0.0
var _clock_started := false
var _wind_snapshot: WindSnapshot
var _wind_screen_direction := Vector2.RIGHT
var _wind_depth_cue := DepthCue.NONE
var _next_wind_screen_direction := Vector2.RIGHT
var _next_wind_depth_cue := DepthCue.NONE
var _wind_display_key: StringName = &""


func _ready() -> void:
	%Finish.pressed.connect(func() -> void: finish_requested.emit())
	var finish_shortcut := Shortcut.new()
	var finish_key := InputEventKey.new()
	finish_key.physical_keycode = KEY_F
	finish_shortcut.events = [finish_key]
	%Finish.shortcut = finish_shortcut
	refresh_locale()


func reset_for_stage(maximum_shots: int, duration_seconds: float) -> void:
	_shots_remaining = maxi(maximum_shots, 0)
	_moving_residents = 0
	_resting_residents = 0
	_resident_total = 0
	_has_resident_breakdown = false
	_duration_seconds = maxf(duration_seconds, 0.0)
	_remaining_seconds = _duration_seconds
	_clock_started = false
	_wind_snapshot = null
	_wind_display_key = &""
	set_finish_available(false)
	_refresh_values()


func update_shots(remaining: int) -> void:
	_shots_remaining = maxi(remaining, 0)
	_refresh_activity()


func update_resident_activity(moving: int, resting: int) -> void:
	_moving_residents = maxi(moving, 0)
	_resting_residents = maxi(resting, 0)
	_resident_total = _moving_residents + _resting_residents
	_has_resident_breakdown = true
	_refresh_activity()


func update_resident_total(total: int) -> void:
	_resident_total = maxi(total, 0)
	_has_resident_breakdown = false
	_refresh_activity()


func update_clock(snapshot: Dictionary) -> void:
	_clock_started = bool(snapshot.get("started", false))
	var ticks_per_second := maxi(int(snapshot.get("ticks_per_second", Engine.physics_ticks_per_second)), 1)
	var duration_ticks := maxi(int(snapshot.get("duration_ticks", 0)), 0)
	var remaining_ticks := maxi(int(snapshot.get("remaining_ticks", duration_ticks)), 0)
	if duration_ticks > 0:
		_duration_seconds = float(duration_ticks) / float(ticks_per_second)
		_remaining_seconds = float(remaining_ticks) / float(ticks_per_second)
	_refresh_clock()


func update_wind(
		snapshot: WindSnapshot,
		screen_direction: Vector2,
		depth_cue: DepthCue = DepthCue.NONE,
		next_screen_direction: Vector2 = Vector2.ZERO,
		next_depth_cue: DepthCue = DepthCue.NONE
) -> void:
	_wind_snapshot = snapshot
	_wind_screen_direction = screen_direction
	_wind_depth_cue = depth_cue
	_next_wind_screen_direction = next_screen_direction \
			if not next_screen_direction.is_zero_approx() else screen_direction
	_next_wind_depth_cue = next_depth_cue
	var next_display_key := wind_display_key(
		snapshot,
		screen_direction,
		depth_cue,
		_next_wind_screen_direction,
		next_depth_cue
	)
	if next_display_key == _wind_display_key:
		return
	_refresh_wind()


func set_finish_available(available: bool) -> void:
	%Finish.disabled = not available
	%Finish.tooltip_text = tr("hud.finish_tooltip") if available else tr("hud.finish_disabled_tooltip")


func finish_is_available() -> bool:
	return not %Finish.disabled


func focus_finish() -> void:
	if finish_is_available():
		%Finish.grab_focus()


func refresh_locale() -> void:
	_wind_display_key = &""
	%TimeMetric.set_caption_key("hud.time")
	%ShotsMetric.set_caption_key("hud.shots")
	%ActivityMetric.set_caption_key("hud.resident_balls")
	%WindLabel.text = tr("hud.wind")
	%Finish.text = "%s  [F]" % tr("ui.finish")
	_refresh_values()
	set_finish_available(finish_is_available())


func _refresh_values() -> void:
	_refresh_clock()
	_refresh_activity()
	_refresh_wind()


func _refresh_clock() -> void:
	var shown_seconds := _remaining_seconds if _clock_started else _duration_seconds
	%TimeMetric.set_value(_format_duration(shown_seconds) if shown_seconds > 0.0 else "--:--")
	%TimeMetric.tooltip_text = tr("hud.timer_starts_on_first_shot") if not _clock_started else ""


func _refresh_activity() -> void:
	%ShotsMetric.set_value(str(_shots_remaining))
	if _has_resident_breakdown:
		%ActivityMetric.set_value(tr("hud.resident_activity_format") % [
			_moving_residents,
			_resting_residents,
		])
	else:
		%ActivityMetric.set_value(tr("hud.resident_total_format") % _resident_total)


func _refresh_wind() -> void:
	_wind_display_key = wind_display_key(
		_wind_snapshot,
		_wind_screen_direction,
		_wind_depth_cue,
		_next_wind_screen_direction,
		_next_wind_depth_cue
	)
	if _wind_snapshot == null:
		%WindArrow.text = "—"
		%WindDirection.text = tr("hud.wind_waiting")
		%WindStrength.text = tr("hud.wind_strength_format") % [tr("hud.wind_calm"), 0]
		%WindCountdown.text = tr("hud.wind_change_waiting")
		%WindForecast.visible = false
		%WindBox.tooltip_text = tr("hud.wind_waiting")
		return
	var direction_label := _direction_label(_wind_screen_direction, _wind_depth_cue)
	var percent := clampi(roundi(_wind_snapshot.normalized_strength * 100.0), 0, 100)
	var strength_label := tr(_strength_key(_wind_snapshot.normalized_strength))
	var countdown := maxi(ceili(_wind_snapshot.seconds_until_change), 0)
	%WindArrow.text = _direction_arrow(_wind_screen_direction, _wind_depth_cue)
	%WindDirection.text = direction_label
	%WindStrength.text = tr("hud.wind_strength_format") % [strength_label, percent]
	%WindCountdown.text = tr("hud.wind_change_format") % countdown
	var description := tr("hud.wind_accessible_format") % [direction_label, strength_label, percent, countdown]
	%WindBox.tooltip_text = description
	%WindArrow.tooltip_text = description
	%WindForecast.visible = _wind_snapshot.is_transitioning()
	if _wind_snapshot.is_transitioning():
		var next_direction := _direction_label(_next_wind_screen_direction, _next_wind_depth_cue)
		var next_percent := clampi(roundi(_wind_snapshot.next_normalized_strength * 100.0), 0, 100)
		var next_strength := tr(_strength_key(_wind_snapshot.next_normalized_strength))
		%NextWindArrow.text = _direction_arrow(_next_wind_screen_direction, _next_wind_depth_cue)
		%NextWindText.text = tr("hud.wind_next_format") % [next_direction, next_strength, next_percent]


static func wind_display_key(
		snapshot: WindSnapshot,
		screen_direction: Vector2,
		depth_cue: DepthCue,
		next_screen_direction: Vector2,
		next_depth_cue: DepthCue
) -> StringName:
	if snapshot == null:
		return &"none"
	var direction_bucket := _direction_bucket(screen_direction, depth_cue)
	var next_direction_bucket := _direction_bucket(next_screen_direction, next_depth_cue)
	return StringName("%d|%d|%d|%d|%d|%d" % [
		direction_bucket,
		clampi(roundi(snapshot.normalized_strength * 100.0), 0, 100),
		maxi(ceili(snapshot.seconds_until_change), 0),
		1 if snapshot.is_transitioning() else 0,
		next_direction_bucket,
		clampi(roundi(snapshot.next_normalized_strength * 100.0), 0, 100),
	])


static func _direction_bucket(screen_direction: Vector2, depth_cue: DepthCue) -> int:
	match depth_cue:
		DepthCue.INTO_SCREEN:
			return 8
		DepthCue.OUT_OF_SCREEN:
			return 9
	if screen_direction.is_zero_approx():
		return 10
	return posmod(roundi(screen_direction.angle() / (PI / 4.0)), 8)


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(ceili(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _strength_key(value: float) -> String:
	if value < 0.25:
		return "hud.wind_calm"
	if value < 0.55:
		return "hud.wind_light"
	if value < 0.75:
		return "hud.wind_steady"
	return "hud.wind_strong"


func _direction_label(screen_direction: Vector2, depth_cue: DepthCue) -> String:
	match depth_cue:
		DepthCue.INTO_SCREEN:
			return tr("hud.wind_into_screen")
		DepthCue.OUT_OF_SCREEN:
			return tr("hud.wind_out_of_screen")
	if screen_direction.is_zero_approx():
		return tr("hud.wind_calm_direction")
	var octant := posmod(roundi(screen_direction.angle() / (PI / 4.0)), 8)
	return tr([
		"hud.wind_right",
		"hud.wind_down_right",
		"hud.wind_down",
		"hud.wind_down_left",
		"hud.wind_left",
		"hud.wind_up_left",
		"hud.wind_up",
		"hud.wind_up_right",
	][octant])


func _direction_arrow(screen_direction: Vector2, depth_cue: DepthCue) -> String:
	match depth_cue:
		DepthCue.INTO_SCREEN:
			return "⊗"
		DepthCue.OUT_OF_SCREEN:
			return "⊙"
	if screen_direction.is_zero_approx():
		return "•"
	var octant := posmod(roundi(screen_direction.angle() / (PI / 4.0)), 8)
	return ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"][octant]
