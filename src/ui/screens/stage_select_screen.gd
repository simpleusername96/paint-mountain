class_name StageSelectScreen
extends CanvasLayer

signal back_requested
signal start_requested(stage_id: StringName)
signal selection_changed(stage: StageData)

const PAGE_SIZE := 8

var _selected_stage: StageData
var _stage_nodes: Array[Button] = []
var _page_index := 0
var _preparation_stage_id: StringName = &""
var _preparation_ready := false
var _preparation_failed := false
var _compact := false

@onready var _root: Control = $Root
@onready var _scrim: Control = %BottomScrim
@onready var _heading: Label = %Heading
@onready var _selected_info: VBoxContainer = %SelectedInfo
@onready var _stage_number: Label = %StageNumber
@onready var _stage_name: Label = %StageName
@onready var _preview_stats: Label = %PreviewStats
@onready var _preview_best: Label = %PreviewBest
@onready var _start_button: ActionControl = %Start
@onready var _page_label: Label = %PageRange
@onready var _stage_rail: StageRail = %StageRail


func _ready() -> void:
	%Back.pressed.connect(func() -> void: back_requested.emit())
	_start_button.pressed.connect(_on_start_pressed)
	_stage_rail.stage_requested.connect(_on_stage_requested)
	_stage_rail.previous_page_requested.connect(func() -> void: _set_page(_page_index - 1))
	_stage_rail.next_page_requested.connect(func() -> void: _set_page(_page_index + 1))
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
	var safe := 12.0 if _compact else 24.0
	var scrim_height := 178.0 if _compact else 250.0
	_set_rect(_scrim, Vector2(0.0, viewport_size.y - scrim_height),
			Vector2(viewport_size.x, scrim_height))
	_set_rect(%Back, Vector2(safe, safe), Vector2(84.0, 44.0))
	_set_rect(_heading, Vector2(safe + 96.0, safe),
			Vector2(maxf(160.0, viewport_size.x - safe * 2.0 - 96.0), 48.0))
	if _compact:
		_set_rect(_selected_info, Vector2(safe, viewport_size.y - 174.0), Vector2(300.0, 92.0))
		_set_rect(_start_button, Vector2(viewport_size.x - safe - 240.0, viewport_size.y - 170.0),
				Vector2(240.0, 58.0))
		_page_label.hide()
		_stage_name.hide()
		_preview_best.hide()
		_stage_rail.set_compact(true)
	else:
		_set_rect(_selected_info, Vector2(safe + 24.0, viewport_size.y - 244.0), Vector2(520.0, 142.0))
		_set_rect(_start_button, Vector2(viewport_size.x - safe - 240.0, viewport_size.y - 202.0),
				Vector2(240.0, 58.0))
		_set_rect(_page_label, Vector2(safe, viewport_size.y - 124.0),
				Vector2(viewport_size.x - safe * 2.0, 22.0))
		_page_label.show()
		_stage_name.show()
		_preview_best.show()
		_stage_rail.set_compact(false)
	_set_rect(_stage_rail, Vector2(safe, viewport_size.y - (64.0 if _compact else 92.0)),
			Vector2(viewport_size.x - safe * 2.0, 52.0))
	_update_preview()


func _set_rect(control: Control, position: Vector2, control_size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = position
	control.size = control_size


## Canvas-item stretching retains the logical viewport in compact OS windows.
## Breakpoints follow physical dimensions while geometry stays logical.
func _responsive_window_size(viewport_size: Vector2) -> Vector2:
	if get_viewport() is SubViewport:
		return viewport_size
	var window_size := Vector2(DisplayServer.window_get_size())
	return window_size if window_size.x > 0.0 and window_size.y > 0.0 else viewport_size


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
		_page_index = maxi(floori(float(_selected_stage.stage_number - 1) / float(PAGE_SIZE)), 0)
	_set_page(_page_index)
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
	_set_page(page)
	var stages := StageCatalog.all_stages()
	var first_index := _page_index * PAGE_SIZE
	if first_index >= 0 and first_index < stages.size():
		_selected_stage = stages[first_index]
		_set_page(_page_index)
		_update_preview()
		selection_changed.emit(_selected_stage)


func _set_page(requested_page: int) -> void:
	var stages := StageCatalog.all_stages()
	if stages.is_empty():
		return
	var total_pages := maxi(1, ceili(float(stages.size()) / float(PAGE_SIZE)))
	_page_index = clampi(requested_page, 0, total_pages - 1)
	var first_stage_index := _page_index * PAGE_SIZE
	var selected_changed := _selected_stage != null and (
			_selected_stage.stage_number < first_stage_index + 1
			or _selected_stage.stage_number > first_stage_index + PAGE_SIZE
	)
	if _selected_stage == null or selected_changed:
		_selected_stage = stages[first_stage_index]
	var items: Array[Dictionary] = []
	var game_state := get_node_or_null("/root/GameState")
	for slot in range(PAGE_SIZE):
		var stage_index := first_stage_index + slot
		if stage_index >= stages.size():
			break
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
	_stage_rail.set_compact(_compact)
	_stage_rail.set_page_availability(_page_index > 0, _page_index < total_pages - 1)
	_stage_nodes = _stage_rail.stage_buttons()
	var first_stage := first_stage_index + 1
	var last_stage := mini(first_stage + PAGE_SIZE - 1, stages.size())
	_page_label.text = "%02d–%02d / %02d" % [first_stage, last_stage, stages.size()]
	if selected_changed:
		_update_preview()
		selection_changed.emit(_selected_stage)


func _on_stage_requested(stage_id: StringName) -> void:
	var stage := StageCatalog.get_stage(stage_id)
	if stage == null:
		return
	_selected_stage = stage
	_set_page(_page_index)
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
	var full_stats := ""
	var compact_stats := ""
	if _selected_stage.uses_target_band():
		full_stats = "◎ %s  ·  R %s / G %s  ·  ● %s  ·  ◉ %d  ·  ◷ %s" % [
			_band_text(_selected_stage),
			_weight_text(_selected_stage.color_score_rule.red_weight),
			_weight_text(_selected_stage.color_score_rule.green_weight),
			_ball_kind_names(_selected_stage),
			_selected_stage.maximum_shots,
			_format_duration(_selected_stage.resolved_duration_seconds()),
		]
		compact_stats = "◎ %s · R%s/G%s · ◉ %d" % [
			_band_text(_selected_stage),
			_weight_text(_selected_stage.color_score_rule.red_weight),
			_weight_text(_selected_stage.color_score_rule.green_weight),
			_selected_stage.maximum_shots,
		]
		_preview_best.text = "%s —" % tr("stage.best") if best.is_empty() else "%s %s  %s" % [
			tr("stage.best"), _format_number(float(best.get("paint_score", 0.0))),
			_stars_text(int(best.get("stars", 0))),
		]
	else:
		full_stats = "◎ %.1f%%  ·  ◉ %d  ·  ◷ %s  ·  ◆ %s" % [
			_selected_stage.target_coverage,
			_selected_stage.maximum_shots,
			_format_duration(_selected_stage.resolved_duration_seconds()),
			_mechanism_names(_selected_stage),
		]
		compact_stats = "◎ %.1f%% · ◉ %d · ◆ %d" % [
			_selected_stage.target_coverage,
			_selected_stage.maximum_shots,
			_selected_stage.mechanism_loadout.size(),
		]
		_preview_best.text = "%s %.1f%%  %s" % [
			tr("stage.best"), float(best.get("coverage", 0.0)),
			_stars_text(int(best.get("stars", 0))),
		]
	_preview_stats.text = compact_stats if _compact else full_stats
	_preview_stats.tooltip_text = full_stats
	_preview_stats.accessibility_name = full_stats
	_apply_start_preparation_state()


func _apply_start_preparation_state() -> void:
	var state_matches := _selected_stage != null and _preparation_stage_id == _selected_stage.stage_id
	var ready := state_matches and _preparation_ready
	var failed := _preparation_failed and (_selected_stage == null or state_matches)
	_start_button.configure("ui.retry_stage_load" if failed else "ui.start_stage" if ready else "ui.loading_stage")
	_start_button.set_readiness(ready or failed, tr("ui.stage_load_failed") if failed else "")


func _refresh_locale() -> void:
	%Back.text = tr("ui.back")
	%Back.accessibility_name = %Back.text
	_heading.text = tr("ui.choose_mountain")
	_stage_rail.refresh_locale()
	_apply_start_preparation_state()


func _display_name(stage: StageData) -> String:
	var translated := tr(String(stage.display_name_key))
	return translated if translated != String(stage.display_name_key) else "Stage %02d" % stage.stage_number


func _mechanism_names(stage: StageData) -> String:
	if stage.mechanism_loadout.is_empty():
		return tr("mechanism.none")
	var names: Array[String] = []
	for mechanism_data in stage.mechanism_loadout:
		var key := "mechanism.uphill_rebound"
		match mechanism_data.canonical_kind():
			MechanismData.Kind.BURST:
				key = "mechanism.burst"
			MechanismData.Kind.SPLITTER:
				key = "mechanism.splitter"
		names.append(tr(key))
	return " + ".join(names)


func _band_text(stage: StageData) -> String:
	if stage.target_band == null:
		return "—"
	return "%s–%s" % [
		_format_number(stage.target_band.target_min),
		_format_number(stage.target_band.target_max),
	]


func _ball_kind_names(stage: StageData) -> String:
	if stage.ball_deal_profile == null:
		return "—"
	var names: Array[String] = []
	for kind in stage.ball_deal_profile.allowed_kinds:
		var stable_id := BallKind.stable_id(kind)
		if not stable_id.is_empty():
			names.append(tr("ball.%s" % stable_id))
	return " / ".join(names)


func _weight_text(weight: int) -> String:
	return "+%d" % weight if weight > 0 else "−%d" % absi(weight) if weight < 0 else "0"


func _format_number(value: float) -> String:
	return "%d" % roundi(value) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _stars_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(maxi(0, 3 - stars))


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(roundi(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _on_settings_changed(_settings: Dictionary) -> void:
	refresh()
