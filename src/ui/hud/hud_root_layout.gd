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
@onready var _run_status := get_node("RunStatusCard") as RunStatusCard
@onready var _score_status := get_node("AimScoreStatus") as AimScoreStatus
@onready var _queue := get_node("BallQueue") as BallQueue
@onready var _interaction := get_node("CameraInteractionControl") as CameraInteractionControl
@onready var _return_to_cannon := get_node("ReturnToCannon") as ActionControl
@onready var _legend := get_node("ContextLegend") as ContextLegend
@onready var _result := get_node("ResultPanel") as ResultPanel

var _compact_active := false
var _score_presentation := AimScoreStatus.Presentation.AIM_RANGE
var _result_active := false
var _restore_legend_visible := false
var _suppress_visibility_capture := false


func _ready() -> void:
	resized.connect(_apply_layout)
	get_viewport().size_changed.connect(_apply_layout)
	_legend.visibility_changed.connect(_on_legend_visibility_changed)
	_apply_layout.call_deferred()


func set_score_presentation(presentation: AimScoreStatus.Presentation) -> void:
	_score_presentation = presentation
	_apply_layout()


func set_result_active(active: bool) -> void:
	_result_active = active
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
	_score_status.set_presentation(_score_presentation)
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


func _apply_standard_layout() -> void:
	_top.visible = not _result_active
	_top.set_compact(false)
	_actions.set_compact(false)
	_aim.set_compact(false)
	_set_rect(_aim, Vector2((size.x - 648.0) * 0.5, size.y - 146.0), Vector2(648.0, 56.0))
	_set_rect(_actions, Vector2((size.x - 256.0) * 0.5, size.y - 178.0), Vector2(256.0, 96.0))
	_queue.set_compact(false)
	_set_rect(_queue, Vector2(size.x - SAFE_MARGIN - 420.0, 92.0), Vector2(420.0, 172.0))
	_set_rect(_interaction, Vector2(size.x - 430.0, SAFE_MARGIN), Vector2(48.0, 48.0))
	_set_rect(
		_run_status,
		Vector2(size.x - 374.0, SAFE_MARGIN),
		Vector2(284.0, 52.0)
	)
	_score_status.set_compact(false)
	if _score_presentation == AimScoreStatus.Presentation.AIM_RANGE:
		_set_rect(_score_status, Vector2(SAFE_MARGIN, 88.0), Vector2(520.0, 176.0))
	else:
		_set_rect(_score_status, Vector2(SAFE_MARGIN, 88.0), Vector2(210.0, 136.0))
	_result.set_compact(false)
	_result.set_scrim_right_outset(SAFE_MARGIN)
	_set_rect(
		_result,
		Vector2(size.x - SAFE_MARGIN - 496.0, maxf(88.0, (size.y - 560.0) * 0.5)),
		Vector2(496.0, 560.0)
	)
	_return_to_cannon.set_compact(false)
	_set_rect(
		_return_to_cannon,
		Vector2(size.x - SAFE_MARGIN - 44.0, size.y - SAFE_MARGIN - 44.0),
		Vector2(44.0, 44.0)
	)


func _apply_compact_layout(density: float) -> void:
	_suppress_visibility_capture = true
	_legend.hide()
	_suppress_visibility_capture = false
	_top.set_compact(true, density)
	_top.visible = not _result_active
	_actions.set_compact(true, density)
	_aim.set_compact(true, density)
	var action_size := Vector2(256.0, 96.0) * density
	var aim_size := Vector2(568.0, 52.0) * density
	var action_top := size.y - COMPACT_SAFE_MARGIN * density - action_size.y
	_set_rect(_actions, Vector2((size.x - action_size.x) * 0.5, action_top), action_size)
	_set_rect(_aim, Vector2((size.x - aim_size.x) * 0.5, action_top + 24.0 * density), aim_size)
	_queue.set_compact(true, density)
	var queue_height := 172.0 * density
	var queue_width := 280.0 * density
	_set_rect(
		_queue,
		Vector2(size.x - COMPACT_SAFE_MARGIN - queue_width, 72.0),
		Vector2(queue_width, queue_height)
	)
	var compact_safe := COMPACT_SAFE_MARGIN * density
	var settings_size := 44.0 * density
	var settings_left := size.x - compact_safe - settings_size
	var status_size := Vector2(284.0, 52.0)
	var status_right := settings_left - compact_safe
	_set_rect(
		_run_status,
		Vector2(status_right - status_size.x, compact_safe),
		status_size
	)
	_set_rect(
		_interaction,
		Vector2(status_right - status_size.x - compact_safe - 48.0, compact_safe),
		Vector2(48.0, 48.0)
	)
	_score_status.set_compact(true, density)
	var score_top := 68.0 * density
	var score_size := Vector2(300.0, 176.0) * density \
			if _score_presentation == AimScoreStatus.Presentation.AIM_RANGE \
			else Vector2(210.0, 136.0) * density
	_set_rect(_score_status, Vector2(COMPACT_SAFE_MARGIN * density, score_top), score_size)
	_result.set_compact(true, density)
	var result_safe := COMPACT_SAFE_MARGIN * density
	_result.set_scrim_right_outset(result_safe)
	var result_width := minf(496.0 * density, size.x * 0.54)
	var result_minimum := _result.get_combined_minimum_size()
	var result_height := minf(
		maxf(result_minimum.y, 420.0 * density),
		size.y - result_safe * 2.0
	)
	_set_rect(
		_result,
		Vector2(
			size.x - result_safe - result_width,
			maxf(result_safe, (size.y - result_height) * 0.5)
		),
		Vector2(result_width, result_height)
	)
	_return_to_cannon.set_compact(true, density)
	var return_width := 40.0 * density
	var return_height := 40.0 * density
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
