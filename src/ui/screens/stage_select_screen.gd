class_name StageSelectScreen
extends CanvasLayer

signal back_requested
signal start_requested(stage_id: StringName)
signal selection_changed(stage: StageData)

const PAGE_SIZE := 10

var _selected_stage: StageData
var _cards: Array[Button] = []
var _page_index := 0
var _page_label: Label
var _previous_page: Button
var _next_page: Button
var _cards_container: GridContainer
@onready var _preview_title: Label = %PreviewTitle
@onready var _preview_objective: Label = %PreviewObjective
@onready var _preview_stats: Label = %PreviewStats
@onready var _preview_best: Label = %PreviewBest
@onready var _start_button: Button = %Start


func _ready() -> void:
	_cards_container = get_node("Root/CardsPanel/Margin/Cards") as GridContainer
	_build_pager()
	%Back.pressed.connect(func() -> void: back_requested.emit())
	_start_button.pressed.connect(func() -> void:
		if _selected_stage != null:
			start_requested.emit(_selected_stage.stage_id)
	)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
	refresh()


func _build_pager() -> void:
	for child in _cards_container.get_children():
		child.queue_free()
	_cards.clear()
	_cards_container.columns = 2
	for index in range(PAGE_SIZE):
		var card := Button.new()
		card.custom_minimum_size = Vector2(0.0, 88.0)
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.toggle_mode = true
		card.focus_mode = Control.FOCUS_ALL
		_cards_container.add_child(card)
		_cards.append(card)
		card.pressed.connect(_on_card_pressed.bind(index))
	var pager := HBoxContainer.new()
	pager.name = "PageControls"
	pager.add_theme_constant_override("separation", 10)
	pager.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pager.position = Vector2(310.0, 664.0)
	pager.size = Vector2(300.0, 40.0)
	get_node("Root").add_child(pager)
	_previous_page = Button.new()
	_previous_page.text = "‹"
	_previous_page.custom_minimum_size = Vector2(48.0, 40.0)
	pager.add_child(_previous_page)
	_page_label = Label.new()
	_page_label.custom_minimum_size = Vector2(150.0, 40.0)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pager.add_child(_page_label)
	_next_page = Button.new()
	_next_page.text = "›"
	_next_page.custom_minimum_size = Vector2(48.0, 40.0)
	pager.add_child(_next_page)
	_previous_page.pressed.connect(func() -> void: _set_page(_page_index - 1))
	_next_page.pressed.connect(func() -> void: _set_page(_page_index + 1))


func refresh() -> void:
	var stages := StageCatalog.all_stages()
	if stages.is_empty():
		return
	if _selected_stage == null:
		_selected_stage = stages[0]
	_set_page(_page_index)
	_update_preview()


func focus_primary() -> void:
	if not _cards.is_empty():
		_cards[0].grab_focus()


func selected_stage_id() -> StringName:
	return _selected_stage.stage_id if _selected_stage != null else &""


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
		card.text = "%02d  %s\n%s %.1f%% · %s %.1f%%" % [
			stage.stage_number,
			_display_name(stage),
			tr("stage.target"),
			stage.target_coverage,
			tr("stage.best"),
			float(best.get("coverage", 0.0)),
		]
		card.set_pressed_no_signal(stage == _selected_stage)
	if _page_label != null:
		_page_label.text = "%d / %d" % [_page_index + 1, total_pages]
		_previous_page.disabled = _page_index <= 0
		_next_page.disabled = _page_index >= total_pages - 1


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
	_preview_objective.text = _display_objective(_selected_stage)
	_preview_stats.text = "%s %.1f%% · %s %d\n%s %s" % [
		tr("stage.target"), _selected_stage.target_coverage,
		tr("stage.shots"), _selected_stage.maximum_shots,
		tr("stage.mechanisms"), _mechanism_names(_selected_stage),
	]
	_preview_best.text = "%s %.1f%%  %s" % [
		tr("stage.best"), float(best.get("coverage", 0.0)), _stars_text(int(best.get("stars", 0)))
	]
	_start_button.disabled = false
	_set_page(_page_index)


func _display_name(stage: StageData) -> String:
	var translated := tr(String(stage.display_name_key))
	return translated if translated != String(stage.display_name_key) else "Stage %02d" % stage.stage_number


func _display_objective(stage: StageData) -> String:
	var translated := tr(String(stage.objective_key))
	return translated if translated != String(stage.objective_key) else tr("stage.generated.objective")


func _mechanism_names(stage: StageData) -> String:
	if stage.mechanism_loadout.is_empty():
		return tr("mechanism.none")
	var names: Array[String] = []
	for mechanism_data in stage.mechanism_loadout:
		names.append(tr(["mechanism.burst", "mechanism.splitter", "mechanism.bumper"][mechanism_data.kind]))
	return " + ".join(names)


func _stars_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(maxi(0, 3 - stars))


func _on_settings_changed(_settings: Dictionary) -> void:
	refresh()
