class_name HudRootLayout
extends Control

## Owns Cannon Focus responsive geometry. Compact presentation reflows the
## essential instruments and never removes score, queue, angle, power, or Fire.

const SAFE_MARGIN := 24.0
const COMPACT_SAFE_MARGIN := 12.0
const COMPACT_WIDTH := 960.0
const COMPACT_HEIGHT := 620.0

@onready var _actions := get_node("ActionButtons") as ActionButtons
@onready var _aim := get_node("AimControls") as AimControls
@onready var _top := get_node("TopStatusBar") as TopStatusBar
@onready var _score_scale := get_node("ScoreScale") as ScoreScale
@onready var _queue := get_node("BallQueue") as BallQueue
@onready var _interaction := get_node("CameraInteractionControl") as CameraInteractionControl
@onready var _return_to_cannon := get_node("ReturnToCannon") as ActionControl
@onready var _briefing_actions := get_node("BriefingActions") as Control
@onready var _briefing_back := get_node("BriefingActions/Back") as ActionControl
@onready var _briefing_start := get_node("BriefingActions/Start") as ActionControl
@onready var _legend := get_node("ContextLegend") as ContextLegend
@onready var _result := get_node("ResultPanel") as ResultPanel

var _compact_active := false
var _score_summary := false
var _restore_legend_visible := false
var _suppress_visibility_capture := false


func _ready() -> void:
	resized.connect(_apply_layout)
	get_viewport().size_changed.connect(_apply_layout)
	_legend.visibility_changed.connect(_on_legend_visibility_changed)
	_apply_layout.call_deferred()


func set_score_summary(summary: bool) -> void:
	_score_summary = summary
	_apply_layout()


func _apply_layout() -> void:
	var responsive_size := _responsive_window_size()
	var compact := responsive_size.x < COMPACT_WIDTH or responsive_size.y < COMPACT_HEIGHT
	if compact != _compact_active:
		if compact:
			_restore_legend_visible = _legend.visible
		else:
			_restore_legend()
	_compact_active = compact
	_apply_score_preset()
	if compact:
		_apply_compact_layout(_display_density(responsive_size))
	else:
		_apply_standard_layout()


## Canvas-item stretching can retain a 1280x720 logical root in a compact OS
## window. Breakpoints follow the physical window while positions stay logical.
func _responsive_window_size() -> Vector2:
	if get_viewport() is SubViewport:
		return size
	var window_size := Vector2(DisplayServer.window_get_size())
	return window_size if window_size.x > 0.0 and window_size.y > 0.0 else size


func _display_density(responsive_size: Vector2) -> float:
	if get_viewport() is SubViewport or responsive_size.x <= 0.0 or responsive_size.y <= 0.0:
		return 1.0
	return clampf(minf(size.x / responsive_size.x, size.y / responsive_size.y), 1.0, 2.0)


func _apply_score_preset() -> void:
	_score_scale.set_preset(
		ScoreScale.Preset.HORIZONTAL_SUMMARY
		if _score_summary and not _compact_active
		else ScoreScale.Preset.VERTICAL_LIVE
	)


func _apply_standard_layout() -> void:
	_top.set_compact(false)
	_actions.set_compact(false)
	_set_rect(_briefing_actions, Vector2(SAFE_MARGIN, size.y - 146.0), Vector2(356.0, 56.0))
	_set_rect(_briefing_back, Vector2.ZERO, Vector2(108.0, 52.0))
	_set_rect(_briefing_start, Vector2(120.0, 0.0), Vector2(236.0, 52.0))
	for briefing_action in [_briefing_back, _briefing_start]:
		briefing_action.add_theme_font_size_override(&"font_size", 17)
	_aim.set_compact(false)
	_set_rect(_aim, Vector2((size.x - 628.0) * 0.5, size.y - 146.0), Vector2(628.0, 56.0))
	_set_rect(_actions, Vector2((size.x - 256.0) * 0.5, size.y - 170.0), Vector2(256.0, 86.0))
	_queue.set_compact(false)
	_set_rect(_queue, Vector2(size.x - SAFE_MARGIN - 420.0, 92.0), Vector2(420.0, 124.0))
	_set_rect(_interaction, Vector2(size.x - 430.0, SAFE_MARGIN), Vector2(48.0, 48.0))
	_score_scale.set_compact(false)
	if _score_summary:
		_set_rect(_score_scale, Vector2(SAFE_MARGIN, 138.0), Vector2(440.0, 118.0))
	else:
		_set_rect(_score_scale, Vector2(SAFE_MARGIN, 84.0), Vector2(132.0, 410.0))
	_result.set_compact(false)
	_set_rect(
		_result,
		Vector2(size.x - SAFE_MARGIN - 496.0, maxf(88.0, (size.y - 560.0) * 0.5)),
		Vector2(496.0, 560.0)
	)
	_return_to_cannon.set_compact_glyph("↩", 1.0)
	_return_to_cannon.custom_minimum_size = Vector2(64.0, 56.0)
	_set_rect(
		_return_to_cannon,
		Vector2(size.x - SAFE_MARGIN - 64.0, size.y - SAFE_MARGIN - 56.0),
		Vector2(64.0, 56.0)
	)


func _apply_compact_layout(density: float) -> void:
	_suppress_visibility_capture = true
	_legend.hide()
	_suppress_visibility_capture = false
	_top.set_compact(true, density)
	_actions.set_compact(true, density)
	var briefing_safe := COMPACT_SAFE_MARGIN * density
	var briefing_size := Vector2(356.0, 52.0) * density
	_set_rect(
		_briefing_actions,
		Vector2(size.x - briefing_safe - briefing_size.x, size.y - briefing_safe - briefing_size.y),
		briefing_size
	)
	_set_rect(_briefing_back, Vector2.ZERO, Vector2(108.0, 52.0) * density)
	_set_rect(_briefing_start, Vector2(120.0, 0.0) * density, Vector2(236.0, 52.0) * density)
	for briefing_action in [_briefing_back, _briefing_start]:
		briefing_action.add_theme_font_size_override(&"font_size", roundi(17.0 * density))
	_aim.set_compact(true, density)
	var action_size := Vector2(256.0, 86.0) * density
	var aim_size := Vector2(568.0, 52.0) * density
	var action_top := size.y - COMPACT_SAFE_MARGIN * density - action_size.y
	_set_rect(_actions, Vector2((size.x - action_size.x) * 0.5, action_top), action_size)
	_set_rect(_aim, Vector2((size.x - aim_size.x) * 0.5, action_top + 24.0 * density), aim_size)
	_queue.set_compact(true, density)
	var queue_height := 124.0 * density
	var queue_width := 420.0 * density
	_set_rect(
		_queue,
		Vector2(size.x - COMPACT_SAFE_MARGIN - queue_width, 72.0),
		Vector2(queue_width, queue_height)
	)
	_set_rect(_interaction, Vector2(size.x - 430.0, 24.0), Vector2(48.0, 48.0))
	_score_scale.set_compact(true, density)
	var score_top := 68.0 * density
	var score_height := 210.0 * density
	_set_rect(
		_score_scale,
		Vector2(COMPACT_SAFE_MARGIN, score_top),
		Vector2(192.0 * density, score_height)
	)
	_result.set_compact(true, density)
	var result_safe := COMPACT_SAFE_MARGIN * density
	_set_rect(
		_result,
		Vector2(result_safe, result_safe),
		Vector2(size.x - result_safe * 2.0, size.y - result_safe * 2.0)
	)
	_return_to_cannon.set_compact_glyph("↩", density)
	var return_width := 64.0 * density
	var return_height := 56.0 * density
	_return_to_cannon.custom_minimum_size = Vector2(return_width, return_height)
	_set_rect(
		_return_to_cannon,
		Vector2(
			size.x - COMPACT_SAFE_MARGIN * density - return_width,
			size.y - COMPACT_SAFE_MARGIN * density - return_height
		),
		Vector2(return_width, return_height)
	)


func _set_rect(control: Control, position: Vector2, control_size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = position
	control.size = control_size


func _restore_legend() -> void:
	_suppress_visibility_capture = true
	_legend.visible = _restore_legend_visible
	_suppress_visibility_capture = false


func _on_legend_visibility_changed() -> void:
	if not _compact_active or _suppress_visibility_capture:
		return
	_restore_legend_visible = _legend.visible
	if _legend.visible:
		_suppress_visibility_capture = true
		_legend.hide()
		_suppress_visibility_capture = false
