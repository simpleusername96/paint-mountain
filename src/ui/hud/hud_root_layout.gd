class_name HudRootLayout
extends Control

## Keeps compact fallback presentation local to the HUD scene. Gameplay input
## remains available when the Windows-first layout cannot fit every instrument.

const SAFE_MARGIN := 24.0
const COMPACT_WIDTH := 900.0
const COMPACT_HEIGHT := 500.0

@onready var _actions := get_node("ActionButtons") as ActionButtons
@onready var _aim := get_node("AimControls") as AimControls
@onready var _legend := get_node("ContextLegend") as ContextLegend

var _compact_active := false
var _restore_aim_visible := false
var _restore_legend_visible := false
var _suppress_visibility_capture := false


func _ready() -> void:
	resized.connect(_apply_layout)
	get_viewport().size_changed.connect(_apply_layout)
	_aim.visibility_changed.connect(_on_aim_visibility_changed)
	_legend.visibility_changed.connect(_on_legend_visibility_changed)
	_apply_layout.call_deferred()


func _apply_layout() -> void:
	var responsive_size := _responsive_window_size()
	var compact := responsive_size.x < COMPACT_WIDTH \
			or responsive_size.y < COMPACT_HEIGHT
	if compact == _compact_active:
		if compact:
			_apply_compact_layout()
		return
	_compact_active = compact
	if compact:
		_restore_aim_visible = _aim.visible
		_restore_legend_visible = _legend.visible
		_apply_compact_layout()
		return
	_restore_standard_layout()


## Canvas-item stretching can retain a 1280x720 logical root in a compact OS
## window. Breakpoints follow the physical window while positions stay logical.
func _responsive_window_size() -> Vector2:
	if get_viewport() is SubViewport:
		return size
	var window_size := Vector2(DisplayServer.window_get_size())
	return window_size if window_size.x > 0.0 and window_size.y > 0.0 else size


func _apply_compact_layout() -> void:
	_actions.anchor_left = 0.0
	_actions.anchor_top = 0.0
	_actions.anchor_right = 0.0
	_actions.anchor_bottom = 0.0
	var left := clampf(
		maxf((size.x - _actions.size.x) * 0.5, 236.0),
		SAFE_MARGIN,
		maxf(SAFE_MARGIN, size.x - SAFE_MARGIN - _actions.size.x)
	)
	var top := maxf(SAFE_MARGIN, size.y - SAFE_MARGIN - _actions.size.y)
	_actions.position = Vector2(left, top)
	_hide_compact_instruments()


func _restore_standard_layout() -> void:
	_actions.anchor_left = 0.5
	_actions.anchor_top = 1.0
	_actions.anchor_right = 0.5
	_actions.anchor_bottom = 1.0
	_actions.offset_left = -146.0
	_actions.offset_top = -170.0
	_actions.offset_right = 146.0
	_actions.offset_bottom = -84.0
	_aim.visible = _restore_aim_visible
	_legend.visible = _restore_legend_visible


func _hide_compact_instruments() -> void:
	_suppress_visibility_capture = true
	_aim.hide()
	_legend.hide()
	_suppress_visibility_capture = false


func _on_aim_visibility_changed() -> void:
	if not _compact_active or _suppress_visibility_capture:
		return
	_restore_aim_visible = _aim.visible
	if _aim.visible:
		_hide_compact_instruments()


func _on_legend_visibility_changed() -> void:
	if not _compact_active or _suppress_visibility_capture:
		return
	_restore_legend_visible = _legend.visible
	if _legend.visible:
		_hide_compact_instruments()
