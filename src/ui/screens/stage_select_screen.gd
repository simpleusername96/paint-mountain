class_name StageSelectScreen
extends CanvasLayer

signal back_requested
signal start_requested(stage_id: StringName)
signal selection_changed(stage: StageData)

const PAGE_SIZE := 8
const STAGE_CARD_SCENE := preload("res://scenes/ui/components/stage_card_button.tscn")

var _selected_stage: StageData
var _cards: Array[StageCardButton] = []
var _page_index := 0
var _page_label: Label
var _previous_page: Button
var _next_page: Button
var _cards_container: GridContainer
var _preparation_stage_id: StringName = &""
var _preparation_ready := false
var _preparation_failed := false
var _last_layout_columns := 0
@onready var _preview_title: Label = %PreviewTitle
@onready var _preview_stats: Label = %PreviewStats
@onready var _preview_best: Label = %PreviewBest
@onready var _start_button: Button = %Start
@onready var _cards_panel: Control = $Root/CardsPanel
@onready var _preview_panel: Control = $Root/PreviewPanel
@onready var _preview_spacer: Control = $Root/PreviewPanel/Margin/Content/ActionSpacer


func _ready() -> void:
	_cards_container = %Cards
	_page_label = %PageRange
	_previous_page = %PreviousPage
	_next_page = %NextPage
	_build_pager()
	%Back.pressed.connect(func() -> void: back_requested.emit())
	_start_button.pressed.connect(func() -> void:
		if _selected_stage != null:
			start_requested.emit(_selected_stage.stage_id)
		elif _preparation_failed:
			var retry_stage_ids := StageCatalog.all_stage_ids()
			if not retry_stage_ids.is_empty():
				start_requested.emit(retry_stage_ids[0])
	)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	refresh()
	_apply_responsive_layout.call_deferred()


func _build_pager() -> void:
	for child in _cards_container.get_children():
		child.queue_free()
	_cards.clear()
	_cards_container.columns = 4
	for index in range(PAGE_SIZE):
		var card := STAGE_CARD_SCENE.instantiate() as StageCardButton
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_cards_container.add_child(card)
		_cards.append(card)
		card.pressed.connect(_on_card_pressed.bind(index))
	_previous_page.pressed.connect(func() -> void: _set_page(_page_index - 1))
	_next_page.pressed.connect(func() -> void: _set_page(_page_index + 1))


## The screen owns only its card arrangement. Anchors in the scene keep the
## two regions inside the 24 px safe area; this branch preserves usable cards
## in compact desktop windows without creating a second screen variant.
func _apply_responsive_layout() -> void:
	if _cards_container == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var window_size := _responsive_window_size(viewport_size)
	var display_scale := viewport_size.x / maxf(window_size.x, 1.0)
	var safe_size := viewport_size - Vector2(48.0, 112.0)
	var compact := window_size.x < 900.0 or window_size.y < 480.0
	var roomy := window_size.x >= 1500.0 and window_size.y >= 700.0
	var columns := 1 if compact else (4 if roomy else 2)
	if columns != _last_layout_columns:
		_last_layout_columns = columns
		_cards_container.columns = columns
	for panel in [_cards_panel, _preview_panel]:
		panel.set_anchor(SIDE_LEFT, 0.0)
		panel.set_anchor(SIDE_TOP, 0.0)
		panel.set_anchor(SIDE_RIGHT, 0.0)
		panel.set_anchor(SIDE_BOTTOM, 0.0)
	if compact:
		var preview_height := minf(184.0 * display_scale, maxf(92.0, safe_size.y * 0.35))
		var cards_height := maxf(120.0, safe_size.y - preview_height - 10.0)
		_cards_panel.position = Vector2(24.0, 88.0)
		_cards_panel.size = Vector2(safe_size.x, cards_height)
		_preview_panel.position = Vector2(24.0, 88.0 + cards_height + 10.0)
		_preview_panel.size = Vector2(safe_size.x, preview_height)
		_preview_title.visible = false
		_preview_stats.visible = false
		_preview_best.visible = false
		_preview_spacer.visible = false
	else:
		var cards_width := safe_size.x * (0.58 if roomy else 0.54)
		_cards_panel.position = Vector2(24.0, 88.0)
		_cards_panel.size = Vector2(cards_width - 12.0, safe_size.y)
		_preview_panel.position = Vector2(24.0 + cards_width + 12.0, 88.0)
		_preview_panel.size = Vector2(safe_size.x - cards_width - 12.0, safe_size.y)
		_preview_title.visible = true
		_preview_stats.visible = true
		_preview_best.visible = true
		_preview_spacer.visible = true


## Canvas-item stretching retains the 1280x720 logical viewport in a compact
## OS window. Use physical dimensions for the breakpoint, but keep all geometry
## in the viewport's logical coordinates.
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
		_page_index = maxi(floori(
			float(_selected_stage.stage_number - 1) / float(PAGE_SIZE)
		), 0)
	_set_page(_page_index)
	_update_preview()


func focus_primary() -> void:
	if not _cards.is_empty():
		_cards[0].grab_focus()


func selected_stage_id() -> StringName:
	return _selected_stage.stage_id if _selected_stage != null else &""


func set_stage_preparation_state(
		stage_id: StringName,
		ready: bool,
		failed: bool = false
) -> void:
	if _selected_stage == null or _selected_stage.stage_id != stage_id:
		return
	_preparation_stage_id = stage_id
	_preparation_ready = ready
	_preparation_failed = failed
	_apply_start_preparation_state()


## Catalog failures have no repository stage identity. Reuse the selected
## stage's existing retry control so Stage Select remains actionable.
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
		_update_preview()
		selection_changed.emit(_selected_stage)


func _set_page(requested_page: int) -> void:
	var total_pages := maxi(1, ceili(float(StageCatalog.all_stages().size()) / float(PAGE_SIZE)))
	_page_index = clampi(requested_page, 0, total_pages - 1)
	var stages := StageCatalog.all_stages()
	var first_stage_index := _page_index * PAGE_SIZE
	var selected_changed := _selected_stage != null and (
			_selected_stage.stage_number < first_stage_index + 1
			or _selected_stage.stage_number > first_stage_index + PAGE_SIZE
	)
	if selected_changed:
		_selected_stage = stages[first_stage_index]
	for slot in range(_cards.size()):
		var stage_index := _page_index * PAGE_SIZE + slot
		var card := _cards[slot]
		if stage_index >= stages.size():
			card.hide()
			continue
		var stage := stages[stage_index]
		card.show()
		var game_state := get_node_or_null("/root/GameState")
		var best: Dictionary = game_state.best_for(stage.stage_id) if game_state != null else {}
		card.disabled = false # Every stage is intentionally open in the MVP.
		card.present(
			stage.stage_number,
			_display_name(stage),
			_card_facts(stage, best),
			tr("stage.prototype") if stage.uses_target_band() else "",
			stage == _selected_stage
		)
	if _page_label != null:
		var first_stage := _page_index * PAGE_SIZE + 1
		var last_stage := mini(first_stage + PAGE_SIZE - 1, stages.size())
		_page_label.text = "%d-%d / %d" % [first_stage, last_stage, stages.size()]
		_previous_page.disabled = _page_index <= 0
		_next_page.disabled = _page_index >= total_pages - 1
		if _previous_page.has_focus() and _previous_page.disabled:
			_next_page.grab_focus.call_deferred()
		elif _next_page.has_focus() and _next_page.disabled:
			_previous_page.grab_focus.call_deferred()
	if selected_changed:
		_update_preview()
		selection_changed.emit(_selected_stage)


func _on_card_pressed(slot: int) -> void:
	var stage_index := _page_index * PAGE_SIZE + slot
	var stages := StageCatalog.all_stages()
	if stage_index < 0 or stage_index >= stages.size():
		return
	_selected_stage = stages[stage_index]
	_update_preview()
	selection_changed.emit(_selected_stage)


func _update_preview() -> void:
	if _selected_stage == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	var best: Dictionary = game_state.best_for(_selected_stage.stage_id) if game_state != null else {}
	_preview_title.text = _display_name(_selected_stage)
	if _selected_stage.uses_target_band():
		_preview_stats.text = "%s  %s\n%s  %s\n%s  %s\n%s %d · %s %s" % [
			tr("stage.target_band"), _band_text(_selected_stage),
			tr("stage.score_roles"), _score_roles(_selected_stage.color_score_rule),
			tr("stage.allowed_balls"), _ball_kind_names(_selected_stage),
			tr("stage.shots"), _selected_stage.maximum_shots,
			tr("hud.time"), _format_duration(_selected_stage.resolved_duration_seconds()),
		]
		_preview_best.text = "%s —" % tr("stage.best") if best.is_empty() else "%s %s  %s" % [
			tr("stage.best"), _format_number(float(best.get("paint_score", 0.0))),
			_stars_text(int(best.get("stars", 0))),
		]
	else:
		_preview_stats.text = "%s %.1f%% · %s %d\n%s %s · %s %s" % [
			tr("stage.target"), _selected_stage.target_coverage,
			tr("stage.shots"), _selected_stage.maximum_shots,
			tr("hud.time"), _format_duration(_selected_stage.resolved_duration_seconds()),
			tr("stage.mechanisms"), _mechanism_names(_selected_stage),
		]
		_preview_best.text = "%s %.1f%%  %s" % [
			tr("stage.best"), float(best.get("coverage", 0.0)),
			_stars_text(int(best.get("stars", 0))),
		]
	_apply_start_preparation_state()
	_set_page(_page_index)


func _apply_start_preparation_state() -> void:
	var state_matches := _selected_stage != null \
			and _preparation_stage_id == _selected_stage.stage_id
	var ready := state_matches and _preparation_ready
	var failed := _preparation_failed and (_selected_stage == null or state_matches)
	_start_button.disabled = not ready and not failed
	if failed:
		_start_button.text = tr("ui.retry_stage_load")
		_start_button.tooltip_text = tr("ui.stage_load_failed")
	elif not ready:
		_start_button.text = tr("ui.loading_stage")
		_start_button.tooltip_text = ""
	else:
		_start_button.text = tr("ui.start_stage")
		_start_button.tooltip_text = ""


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


func _card_facts(stage: StageData, best: Dictionary) -> String:
	if stage.uses_target_band():
		return "%s %s\n%s" % [
			tr("stage.target_band"), _band_text(stage), _ball_kind_names(stage),
		]
	return "%s %.1f%%  ·  %s %.1f%%" % [
		tr("stage.target"), stage.target_coverage,
		tr("stage.best"), float(best.get("coverage", 0.0)),
	]


func _band_text(stage: StageData) -> String:
	if stage.target_band == null:
		return "—"
	return "%s–%s" % [
		_format_number(stage.target_band.target_min),
		_format_number(stage.target_band.target_max),
	]


func _score_roles(rule: ColorScoreRuleData) -> String:
	if rule == null:
		return "—"
	return "%s %s · %s %s" % [
		tr("paint.green"), _weight_text(rule.green_weight),
		tr("paint.red"), _weight_text(rule.red_weight),
	]


func _ball_kind_names(stage: StageData) -> String:
	if stage.ball_deal_profile == null:
		return "—"
	var names: Array[String] = []
	for kind in stage.ball_deal_profile.allowed_kinds:
		var stable_id := BallKind.stable_id(kind)
		if stable_id.is_empty():
			continue
		names.append(tr("ball.%s" % stable_id))
	return " · ".join(names)


func _weight_text(weight: int) -> String:
	if weight > 0:
		return "+%d" % weight
	if weight < 0:
		return "−%d" % absi(weight)
	return "0"


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)
	return "%.1f" % value


func _stars_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(maxi(0, 3 - stars))


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(roundi(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _on_settings_changed(_settings: Dictionary) -> void:
	refresh()
