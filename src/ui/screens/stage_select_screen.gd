class_name StageSelectScreen
extends CanvasLayer

signal back_requested
signal start_requested(stage_id: StringName)
signal selection_changed(stage: StageData)

const PAGE_SIZE := 10
const INK := Color("172538")
const ACCENT := Color("2584FF")

var _selected_stage: StageData
var _stage_nodes: Array[Button] = []
var _window_start := 0
var _preparation_stage_id: StringName = &""
var _preparation_ready := false
var _preparation_failed := false
var _compact := false

@onready var _scrim: Control = %BottomScrim
@onready var _selected_info: VBoxContainer = %SelectedInfo
@onready var _stage_number: Label = %StageNumber
@onready var _stage_name: Label = %StageName
@onready var _preview_stats: StageRuleSummary = %PreviewStats
@onready var _preview_best: Label = %PreviewBest
@onready var _back: ActionControl = %Back
@onready var _previous: ActionControl = %PreviousTerrain
@onready var _next: ActionControl = %NextTerrain
@onready var _start_button: ActionControl = %Start
@onready var _stage_rail: StageRail = %StageRail


func _ready() -> void:
	_apply_reference_palette()
	_back.pressed.connect(func() -> void: back_requested.emit())
	_previous.pressed.connect(func() -> void: _select_relative(-1))
	_next.pressed.connect(func() -> void: _select_relative(1))
	_start_button.pressed.connect(_on_start_pressed)
	_stage_rail.stage_requested.connect(_on_stage_requested)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	refresh()
	_apply_responsive_layout.call_deferred()


func _apply_responsive_layout() -> void:
	if not is_instance_valid(_stage_rail):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var window_size := _responsive_window_size(viewport_size)
	_compact = window_size.x < 900.0 or window_size.y < 480.0
	var density := _display_density(viewport_size, window_size) if _compact else 1.0
	var safe := 12.0 * density if _compact else 24.0
	var routine_edge := 40.0 * density if _compact else 44.0
	var primary_edge := 48.0 * density if _compact else 56.0
	for action in [_back, _previous, _next]:
		action.set_compact(_compact, density)
	_start_button.set_compact(_compact, density)
	_previous.set_icon_width(38.0 if _compact else 42.0)
	_next.set_icon_width(38.0 if _compact else 42.0)
	_start_button.set_icon_width(32.0 if _compact else 36.0)
	_preview_stats.set_compact(_compact, density)
	_stage_rail.set_compact(_compact, density)
	_apply_type_density(density)

	var scrim_height := 152.0 * density if _compact else 190.0
	_set_rect(_scrim, Vector2(0.0, viewport_size.y - scrim_height),
			Vector2(viewport_size.x, scrim_height))
	_set_rect(_back, Vector2(safe, safe), Vector2(routine_edge, routine_edge))
	var info_left := safe + routine_edge + 16.0 * density
	var info_width := minf(760.0 * density, viewport_size.x - info_left - safe)
	_set_rect(_selected_info, Vector2(info_left, safe),
			Vector2(maxf(240.0 * density, info_width), 132.0 * density if _compact else 152.0))

	var arrow_y := (viewport_size.y - routine_edge) * 0.40
	_set_rect(_previous, Vector2(safe, arrow_y), Vector2(routine_edge, routine_edge))
	_set_rect(_next, Vector2(viewport_size.x - safe - routine_edge, arrow_y),
			Vector2(routine_edge, routine_edge))
	var rail_height := 64.0 * density if _compact else 64.0
	var rail_bottom := safe
	_set_rect(_stage_rail, Vector2(safe, viewport_size.y - rail_bottom - rail_height),
			Vector2(viewport_size.x - safe * 2.0, rail_height))
	_set_rect(_start_button,
			Vector2(viewport_size.x - safe - primary_edge,
				viewport_size.y - rail_bottom - rail_height - 16.0 * density - primary_edge),
			Vector2(primary_edge, primary_edge))
	_preview_best.visible = not _compact
	_update_preview()


func _set_rect(control: Control, position: Vector2, control_size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = position
	control.size = control_size


func _responsive_window_size(viewport_size: Vector2) -> Vector2:
	if get_viewport() is SubViewport:
		return viewport_size
	var window_size := Vector2(DisplayServer.window_get_size())
	return window_size if window_size.x > 0.0 and window_size.y > 0.0 else viewport_size


func _display_density(viewport_size: Vector2, window_size: Vector2) -> float:
	if get_viewport() is SubViewport or window_size.x <= 0.0 or window_size.y <= 0.0:
		return 1.0
	return clampf(minf(viewport_size.x / window_size.x, viewport_size.y / window_size.y), 1.0, 2.0)


func _apply_type_density(density: float) -> void:
	var scale := density if _compact else 1.0
	_stage_number.add_theme_font_size_override(&"font_size", roundi((30.0 if _compact else 46.0) * scale))
	_stage_name.add_theme_font_size_override(&"font_size", roundi((18.0 if _compact else 30.0) * scale))
	_preview_best.add_theme_font_size_override(&"font_size", roundi((14.0 if _compact else 15.0) * scale))


func _apply_reference_palette() -> void:
	for label in [_stage_number, _stage_name, _preview_best]:
		label.add_theme_color_override(&"font_color", INK)
		label.add_theme_constant_override(&"outline_size", 0)
	_preview_stats.set_foreground(INK, ACCENT)
	for arrow in [_previous, _next]:
		arrow.add_theme_color_override(&"icon_normal_color", Color.WHITE)
		arrow.add_theme_color_override(&"icon_hover_color", Color.WHITE)
		arrow.add_theme_color_override(&"icon_pressed_color", Color.WHITE)
		arrow.add_theme_color_override(&"icon_focus_color", Color.WHITE)


func refresh() -> void:
	var stages := StageCatalog.all_stages()
	if stages.is_empty():
		return
	if _selected_stage == null:
		var game_state := get_node_or_null("/root/GameState")
		_selected_stage = StageCatalog.get_stage(game_state.selected_stage_id) \
				if game_state != null else null
		if _selected_stage == null:
			_selected_stage = stages[0]
		_window_start = _window_start_for(_selected_stage.stage_number - 1, stages.size())
	_rebuild_stage_window()
	_update_preview()
	_refresh_locale()


func focus_primary() -> void:
	_stage_rail.focus_selected_or_first()


func selected_stage_id() -> StringName:
	return _selected_stage.stage_id if _selected_stage != null else &""


func set_stage_preparation_state(stage_id: StringName, ready: bool, failed: bool = false) -> void:
	if _selected_stage == null or _selected_stage.stage_id != stage_id:
		return
	_preparation_stage_id = stage_id
	_preparation_ready = ready
	_preparation_failed = failed
	_apply_start_preparation_state()


func set_catalog_load_failed() -> void:
	_preparation_stage_id = _selected_stage.stage_id if _selected_stage != null else &""
	_preparation_ready = false
	_preparation_failed = true
	_apply_start_preparation_state()


func set_page_for_capture(page: int) -> void:
	var stages := StageCatalog.all_stages()
	if stages.is_empty():
		return
	_window_start = clampi(page * PAGE_SIZE, 0, maxi(0, stages.size() - 1))
	_selected_stage = stages[_window_start]
	_rebuild_stage_window()
	_update_preview()
	selection_changed.emit(_selected_stage)


func select_relative_for_capture(direction: int) -> void:
	_select_relative(direction)


func _rebuild_stage_window() -> void:
	var stages := StageCatalog.all_stages()
	if stages.is_empty() or _selected_stage == null:
		return
	var selected_index := clampi(_selected_stage.stage_number - 1, 0, stages.size() - 1)
	if selected_index < _window_start or selected_index >= _window_start + PAGE_SIZE:
		_window_start = _window_start_for(selected_index, stages.size())
	_window_start = clampi(_window_start, 0, maxi(0, stages.size() - PAGE_SIZE))
	var items: Array[Dictionary] = []
	var game_state := get_node_or_null("/root/GameState")
	for stage_index in range(_window_start, mini(_window_start + PAGE_SIZE, stages.size())):
		var stage := stages[stage_index]
		var best: Dictionary = game_state.best_for(stage.stage_id) if game_state != null else {}
		items.append({
			"id": stage.stage_id,
			"number": stage.stage_number,
			"name": _display_name(stage),
			"completed": not best.is_empty(),
			"locked": false,
		})
	_stage_rail.configure(items, _selected_stage.stage_id)
	_stage_nodes = _stage_rail.stage_buttons()
	_previous.set_readiness(selected_index > 0)
	_next.set_readiness(selected_index < stages.size() - 1)


func _window_start_for(selected_index: int, stage_count: int) -> int:
	return clampi((selected_index / PAGE_SIZE) * PAGE_SIZE, 0, maxi(0, stage_count - PAGE_SIZE))


func _select_relative(direction: int) -> void:
	var stages := StageCatalog.all_stages()
	if stages.is_empty() or _selected_stage == null:
		return
	var next_index := clampi(_selected_stage.stage_number - 1 + signi(direction), 0, stages.size() - 1)
	_on_stage_requested(stages[next_index].stage_id)


func _on_stage_requested(stage_id: StringName) -> void:
	var stage := StageCatalog.get_stage(stage_id)
	if stage == null or stage == _selected_stage:
		return
	_selected_stage = stage
	_rebuild_stage_window()
	_update_preview()
	selection_changed.emit(_selected_stage)


func _on_start_pressed() -> void:
	if _selected_stage != null:
		start_requested.emit(_selected_stage.stage_id)


func _update_preview() -> void:
	if _selected_stage == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	var best: Dictionary = game_state.best_for(_selected_stage.stage_id) if game_state != null else {}
	_stage_number.text = "%02d" % _selected_stage.stage_number
	_stage_name.text = _display_name(_selected_stage)
	if _selected_stage.uses_target_band():
		_preview_best.text = "%s —" % tr("stage.best") if best.is_empty() else "%s %s  %s" % [
			tr("stage.best"), _format_number(float(best.get("paint_score", 0.0))),
			_grade_text(int(best.get("stars", 0))),
		]
	else:
		_preview_best.text = "%s %.1f%%  %s" % [
			tr("stage.best"), float(best.get("coverage", 0.0)),
			_grade_text(int(best.get("stars", 0))),
		]
	_preview_stats.configure(_selected_stage)
	_apply_start_preparation_state()


func _apply_start_preparation_state() -> void:
	var state_matches := _selected_stage != null and _preparation_stage_id == _selected_stage.stage_id
	var ready := state_matches and _preparation_ready
	var failed := _preparation_failed and (_selected_stage == null or state_matches)
	_start_button.configure(
		"ui.retry_stage_load" if failed else "ui.start_stage" if ready else "ui.loading_stage",
		ActionControl.IconKind.RETRY if failed else ActionControl.IconKind.AIM,
		ActionControl.VisualRole.PRIMARY
	)
	_start_button.set_readiness(ready or failed, tr("ui.stage_load_failed") if failed else "")


func _refresh_locale() -> void:
	_back.configure("ui.back", ActionControl.IconKind.PREVIOUS)
	_previous.configure("ui.previous", ActionControl.IconKind.PREVIOUS)
	_next.configure("ui.next", ActionControl.IconKind.NEXT)
	_stage_rail.refresh_locale()
	_apply_start_preparation_state()


func _display_name(stage: StageData) -> String:
	var translated := tr(String(stage.display_name_key))
	return translated if translated != String(stage.display_name_key) else "Stage %02d" % stage.stage_number


func _format_number(value: float) -> String:
	return "%d" % roundi(value) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _grade_text(stars: int) -> String:
	return "%d/3" % clampi(stars, 0, 3)


func _on_settings_changed(_settings: Dictionary) -> void:
	refresh()
