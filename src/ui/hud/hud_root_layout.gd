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
@onready var _score_scale := get_node("ScoreScale") as ScoreScale
@onready var _queue := get_node("BallQueue") as BallQueue
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
	_score_scale.set_preset(
		ScoreScale.Preset.HORIZONTAL_SUMMARY if summary else ScoreScale.Preset.VERTICAL_LIVE
	)
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
	if compact:
		_apply_compact_layout()
	else:
		_apply_standard_layout()


## Canvas-item stretching can retain a 1280x720 logical root in a compact OS
## window. Breakpoints follow the physical window while positions stay logical.
func _responsive_window_size() -> Vector2:
	if get_viewport() is SubViewport:
		return size
	var window_size := Vector2(DisplayServer.window_get_size())
	return window_size if window_size.x > 0.0 and window_size.y > 0.0 else size


func _apply_standard_layout() -> void:
	_aim.set_compact(false)
	_set_rect(_aim, Vector2((size.x - 704.0) * 0.5, size.y - 146.0), Vector2(704.0, 56.0))
	_set_rect(_actions, Vector2((size.x - 292.0) * 0.5, size.y - 170.0), Vector2(292.0, 86.0))
	_queue.set_vertical(false)
	_set_rect(_queue, Vector2(size.x - SAFE_MARGIN - 260.0, 92.0), Vector2(260.0, 104.0))
	_score_scale.set_compact(false)
	if _score_summary:
		_set_rect(_score_scale, Vector2(SAFE_MARGIN, 138.0), Vector2(440.0, 118.0))
	else:
		_set_rect(_score_scale, Vector2(SAFE_MARGIN, 138.0), Vector2(116.0, 286.0))
	_result.set_compact(false)
	_set_rect(
		_result,
		Vector2(size.x - SAFE_MARGIN - 496.0, maxf(88.0, (size.y - 560.0) * 0.5)),
		Vector2(496.0, 560.0)
	)


func _apply_compact_layout() -> void:
	_suppress_visibility_capture = true
	_legend.hide()
	_suppress_visibility_capture = false
	_aim.set_compact(true)
	var action_top := size.y - COMPACT_SAFE_MARGIN - 86.0
	_set_rect(_actions, Vector2((size.x - 292.0) * 0.5, action_top), Vector2(292.0, 86.0))
	_set_rect(_aim, Vector2((size.x - 340.0) * 0.5, action_top - 58.0), Vector2(340.0, 52.0))
	_queue.set_vertical(false)
	_set_rect(_queue, Vector2(size.x - COMPACT_SAFE_MARGIN - 260.0, 84.0), Vector2(260.0, 104.0))
	_score_scale.set_compact(true)
	if _score_summary:
		_set_rect(_score_scale, Vector2(COMPACT_SAFE_MARGIN, 82.0), Vector2(360.0, 104.0))
	else:
		_set_rect(_score_scale, Vector2(COMPACT_SAFE_MARGIN, 76.0), Vector2(116.0, 272.0))
	_result.set_compact(true)
	_set_rect(
		_result,
		Vector2(COMPACT_SAFE_MARGIN, 72.0),
		Vector2(size.x - COMPACT_SAFE_MARGIN * 2.0, size.y - 84.0)
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
