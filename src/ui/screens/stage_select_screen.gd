class_name StageSelectScreen
extends CanvasLayer

signal back_requested
signal start_requested(stage_id: StringName)
signal selection_changed(stage: StageData)

var _selected_stage: StageData
var _cards: Array[Button] = []
@onready var _preview_title: Label = %PreviewTitle
@onready var _preview_objective: Label = %PreviewObjective
@onready var _preview_stats: Label = %PreviewStats
@onready var _preview_best: Label = %PreviewBest
@onready var _start_button: Button = %Start


func _ready() -> void:
	_cards.assign([%Card1, %Card2, %Card3])
	%Back.pressed.connect(func() -> void: back_requested.emit())
	for index in range(_cards.size()):
		_cards[index].pressed.connect(_select_stage.bind(StageCatalog.all_stages()[index]))
	_start_button.pressed.connect(func() -> void:
		if _selected_stage != null:
			start_requested.emit(_selected_stage.stage_id)
	)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
	refresh()


func refresh() -> void:
	var game_state := get_node_or_null("/root/GameState")
	for index in range(_cards.size()):
		var stage := StageCatalog.all_stages()[index]
		var unlocked: bool = game_state == null or game_state.unlocked_stages.has(stage.stage_id)
		var best: Dictionary = game_state.best_for(stage.stage_id) if game_state != null else {}
		_cards[index].disabled = not unlocked
		_cards[index].text = "%02d  %s\n%s · %s %.2f%%" % [stage.stage_number, tr(String(stage.display_name_key)), _stars_text(int(best.get("stars", 0))) if unlocked else tr("stage.locked"), tr("stage.best"), float(best.get("coverage", 0.0))]
	if _selected_stage == null or (game_state != null and not game_state.unlocked_stages.has(_selected_stage.stage_id)):
		_selected_stage = StageCatalog.all_stages()[0]
	_update_preview()


func focus_primary() -> void:
	if not _cards.is_empty():
		_cards[0].grab_focus()


func selected_stage_id() -> StringName:
	return _selected_stage.stage_id if _selected_stage != null else &""


func _select_stage(stage: StageData) -> void:
	_selected_stage = stage
	_update_preview()
	selection_changed.emit(stage)


func _update_preview() -> void:
	if _selected_stage == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	var best: Dictionary = game_state.best_for(_selected_stage.stage_id) if game_state != null else {}
	_preview_title.text = tr(String(_selected_stage.display_name_key))
	_preview_objective.text = tr(String(_selected_stage.objective_key))
	_preview_stats.text = "%s %.0f%% · %s %d\n%s %s" % [tr("stage.target"), _selected_stage.target_coverage, tr("stage.shots"), _selected_stage.maximum_shots, tr("stage.mechanisms"), _mechanism_names(_selected_stage)]
	_preview_best.text = "%s %.2f%%  %s" % [tr("stage.best"), float(best.get("coverage", 0.0)), _stars_text(int(best.get("stars", 0)))]
	_start_button.disabled = game_state != null and not game_state.unlocked_stages.has(_selected_stage.stage_id)
	for index in range(_cards.size()):
		_cards[index].set_pressed_no_signal(StageCatalog.all_stages()[index] == _selected_stage)


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
