class_name StageSelectScreen
extends CanvasLayer

signal back_requested
signal start_requested(stage_id: StringName)
signal selection_changed(stage: StageData)

var _selected_stage: StageData
var _cards: Array[Button] = []
var _preview_title: Label
var _preview_objective: Label
var _preview_stats: Label
var _preview_best: Label
var _start_button: Button


func _ready() -> void:
	layer = 20
	_build()
	refresh()


func refresh() -> void:
	var game_state := get_node_or_null("/root/GameState")
	for index in range(_cards.size()):
		var stage := StageCatalog.all_stages()[index]
		var unlocked: bool = game_state == null or game_state.unlocked_stages.has(stage.stage_id)
		var best: Dictionary = game_state.best_for(stage.stage_id) if game_state != null else {}
		_cards[index].disabled = not unlocked
		_cards[index].text = "%02d  %s\n%s  ·  BEST %.2f%%" % [
			stage.stage_number,
			stage.display_name,
			_stars_text(int(best.get("stars", 0))) if unlocked else "LOCKED",
			float(best.get("coverage", 0.0)),
		]
	if _selected_stage == null or (game_state != null and not game_state.unlocked_stages.has(_selected_stage.stage_id)):
		_selected_stage = StageCatalog.all_stages()[0]
	_update_preview()


func focus_primary() -> void:
	if not _cards.is_empty():
		_cards[0].grab_focus()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.07, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var back := UIFactory.button("←  BACK", false, Vector2(180.0, 58.0))
	back.position = Vector2(54.0, 42.0)
	back.pressed.connect(func() -> void: back_requested.emit())
	root.add_child(back)
	var title := UIFactory.label("CHOOSE A MOUNTAIN", 42, Color.WHITE)
	title.position = Vector2(278.0, 43.0)
	title.size = Vector2(620.0, 58.0)
	root.add_child(title)

	var cards_panel := UIFactory.panel(Vector2(620.0, 790.0), Color(0.98, 0.97, 0.94, 0.93), 24)
	cards_panel.position = Vector2(54.0, 144.0)
	root.add_child(cards_panel)
	var cards_margin := UIFactory.margin(cards_panel, Vector4(30, 30, 30, 30))
	var cards_content := VBoxContainer.new()
	cards_content.add_theme_constant_override("separation", 18)
	cards_margin.add_child(cards_content)
	for stage in StageCatalog.all_stages():
		var card := UIFactory.button(stage.display_name, false, Vector2(0.0, 190.0))
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 20)
		card.pressed.connect(_select_stage.bind(stage))
		cards_content.add_child(card)
		_cards.append(card)

	var preview_panel := UIFactory.panel(Vector2(560.0, 370.0), Color(0.98, 0.97, 0.94, 0.95), 24)
	preview_panel.anchor_left = 1.0
	preview_panel.anchor_right = 1.0
	preview_panel.anchor_top = 1.0
	preview_panel.anchor_bottom = 1.0
	preview_panel.offset_left = -630.0
	preview_panel.offset_right = -54.0
	preview_panel.offset_top = -424.0
	preview_panel.offset_bottom = -54.0
	root.add_child(preview_panel)
	var preview_margin := UIFactory.margin(preview_panel, Vector4(34, 30, 34, 30))
	var preview_content := VBoxContainer.new()
	preview_content.add_theme_constant_override("separation", 13)
	preview_margin.add_child(preview_content)
	_preview_title = UIFactory.label("FIRST DESCENT", 32, UIFactory.NAVY)
	preview_content.add_child(_preview_title)
	_preview_objective = UIFactory.label("", 17, UIFactory.CHARCOAL)
	_preview_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_objective.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_content.add_child(_preview_objective)
	_preview_stats = UIFactory.label("", 16, UIFactory.MUTED)
	preview_content.add_child(_preview_stats)
	_preview_best = UIFactory.label("", 17, UIFactory.NAVY)
	preview_content.add_child(_preview_best)
	_start_button = UIFactory.button("START STAGE", true, Vector2(0.0, 64.0))
	_start_button.pressed.connect(func() -> void:
		if _selected_stage != null:
			start_requested.emit(_selected_stage.stage_id)
	)
	preview_content.add_child(_start_button)


func _select_stage(stage: StageData) -> void:
	_selected_stage = stage
	_update_preview()
	selection_changed.emit(stage)


func _update_preview() -> void:
	if _selected_stage == null or _preview_title == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	var best: Dictionary = game_state.best_for(_selected_stage.stage_id) if game_state != null else {}
	_preview_title.text = _selected_stage.display_name
	_preview_objective.text = _selected_stage.objective
	_preview_stats.text = "TARGET  %.0f%%    ·    SHOTS  %d\nMECHANISMS  %s" % [
		_selected_stage.target_coverage,
		_selected_stage.maximum_shots,
		_mechanism_names(_selected_stage),
	]
	_preview_best.text = "BEST  %.2f%%    %s" % [float(best.get("coverage", 0.0)), _stars_text(int(best.get("stars", 0)))]
	_start_button.disabled = game_state != null and not game_state.unlocked_stages.has(_selected_stage.stage_id)


func _mechanism_names(stage: StageData) -> String:
	if stage.mechanism_loadout.is_empty():
		return "NONE"
	var names: Array[String] = []
	for mechanism_data in stage.mechanism_loadout:
		names.append(mechanism_data.display_name)
	return " + ".join(names)


func _stars_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(maxi(0, 3 - stars))
