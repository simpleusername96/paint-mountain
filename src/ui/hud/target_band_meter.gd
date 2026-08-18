class_name TargetBandMeter
extends Control

@onready var _band: ColorRect = %Band
@onready var _track: ColorRect = %BandTrack
@onready var _marker: Control = %Marker
@onready var _band_area: Control = %BandArea
@onready var _score: Label = %Score
@onready var _target: Label = %Target
@onready var _red: Label = %Red
@onready var _green: Label = %Green

var _minimum := 0.0
var _maximum := 1.0
var _display_minimum := -0.5
var _display_maximum := 1.5
var _red_weight := 1
var _green_weight := 1
var _score_value := 0.0


func _ready() -> void:
	_band_area.resized.connect(_layout_band)
	_layout_band.call_deferred()

func configure(target_band: TargetBandData, score_rule: ColorScoreRuleData) -> void:
	_minimum = target_band.target_min
	_maximum = target_band.target_max
	var half_width := (_maximum - _minimum) * 0.5
	_display_minimum = _minimum - half_width
	_display_maximum = _maximum + half_width
	_red_weight = score_rule.red_weight
	_green_weight = score_rule.green_weight
	_target.text = "%s  %.1f–%.1f" % [tr("hud.target_band"), _minimum, _maximum]
	update_score(PaintCoverageSnapshot.new())
	_layout_band.call_deferred()

func update_score(snapshot: PaintCoverageSnapshot, score: float = 0.0) -> void:
	_score_value = score
	_score.text = "%s  %.1f" % [tr("hud.paint_score"), score]
	_red.text = "R %s  %.1f%%" % [_sign(_red_weight), snapshot.red_percent]
	_green.text = "G %s  %.1f%%" % [_sign(_green_weight), snapshot.green_percent]
	_red.add_theme_color_override("font_color", PaintChannel.RED_COLOR)
	_green.add_theme_color_override("font_color", PaintChannel.GREEN_COLOR)
	_layout_band()
	tooltip_text = "%s: %.1f–%.1f; %s %.1f" % [
		tr("hud.target_band"), _minimum, _maximum, tr("hud.paint_score"), score,
	]
	accessibility_name = tooltip_text

func _sign(weight: int) -> String:
	return "+" if weight > 0 else "−" if weight < 0 else "0"


func _normalized(value: float) -> float:
	return clampf(inverse_lerp(_display_minimum, _display_maximum, value), 0.0, 1.0)


func _layout_band() -> void:
	if not is_instance_valid(_track) or _track.size.x <= 0.0:
		return
	_band.position.x = _track.position.x + _normalized(_minimum) * _track.size.x
	_band.size.x = (_normalized(_maximum) - _normalized(_minimum)) * _track.size.x
	_marker.position.x = _track.position.x + _normalized(_score_value) * _track.size.x \
			- _marker.size.x * 0.5
