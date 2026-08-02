class_name HUDController
extends CanvasLayer

signal begin_aiming_requested
signal fire_requested
signal restart_requested
signal pause_requested
signal settings_requested
signal stage_select_requested
signal main_menu_requested
signal next_stage_requested
signal replay_requested
signal camera_mode_requested(mode: int)
signal simulation_speed_requested(speed: float)

const NAVY := Color(0.055, 0.095, 0.16, 1.0)
const CHARCOAL := Color(0.16, 0.18, 0.22, 1.0)
const MUTED := Color(0.38, 0.41, 0.46, 1.0)
const OFF_WHITE := Color(0.98, 0.97, 0.94, 0.95)
const BLUE := Color(0.035, 0.38, 0.98, 1.0)
const BLUE_HOVER := Color(0.08, 0.46, 1.0, 1.0)

var _stage_data: StageData
var _root: Control
var _stage_value: Label
var _target_value: Label
var _shots_value: Label
var _status_value: Label
var _angle_value: Label
var _power_value: Label
var _coverage_value: Label
var _coverage_bar: ProgressBar
var _coverage_panel: Control
var _briefing_panel: Control
var _briefing_title: Label
var _briefing_objective: Label
var _briefing_mechanisms: Label
var _aim_panel: Control
var _action_panel: Control
var _observation_panel: Control
var _shot_result_panel: Control
var _shot_result_value: Label
var _result_panel: Control
var _result_title: Label
var _result_details: Label
var _pause_overlay: Control
var _fire_button: Button
var _start_button: Button
var _next_button: Button
var _result_stars: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()


func configure(stage_data: StageData) -> void:
	_stage_data = stage_data
	_stage_value.text = "LEVEL %02d" % stage_data.stage_number
	_target_value.text = "TARGET COVERAGE   %.2f%%" % stage_data.target_coverage
	_briefing_title.text = stage_data.display_name
	_briefing_objective.text = stage_data.objective
	_briefing_mechanisms.text = _mechanism_brief(stage_data)
	_next_button.disabled = StageCatalog.next_stage_id(stage_data.stage_id).is_empty()
	update_shots(stage_data.maximum_shots, stage_data.maximum_shots)
	update_coverage(0.0)
	update_aim(38.0, 68.0)


func update_aim(elevation: float, power: float) -> void:
	_angle_value.text = "%d°" % roundi(elevation)
	_power_value.text = "%d%%" % roundi(power)


func update_shots(remaining: int, _maximum: int) -> void:
	_shots_value.text = "SHOTS LEFT   %d" % remaining


func update_coverage(coverage: float) -> void:
	_coverage_value.text = "%05.2f%%" % coverage
	_coverage_bar.value = coverage


func show_state(state: StageController.State) -> void:
	_briefing_panel.visible = state == StageController.State.BRIEFING
	_aim_panel.visible = state == StageController.State.AIMING
	_action_panel.visible = state == StageController.State.AIMING
	_observation_panel.visible = state in [
		StageController.State.PROJECTILE_IN_FLIGHT,
		StageController.State.PAINT_SETTLING,
		StageController.State.SHOT_RESULT,
	]
	_shot_result_panel.visible = state == StageController.State.SHOT_RESULT
	_result_panel.visible = state in [StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED]
	_coverage_panel.visible = state not in [StageController.State.LOADING, StageController.State.BRIEFING]
	_pause_overlay.visible = state == StageController.State.PAUSED
	_status_value.text = _display_state_name(state)
	match state:
		StageController.State.BRIEFING:
			_start_button.grab_focus()
		StageController.State.AIMING:
			_fire_button.grab_focus()
		StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED:
			_result_panel.get_node("Margin/Content/Retry").grab_focus()


func show_shot_result(gain: float, total: float) -> void:
	_shot_result_value.text = "+%.2f%%  ·  TOTAL %.2f%%" % [gain, total]


func show_clear(final_coverage: float, shots_used: int, stars: int = 1, previous_best: float = 0.0) -> void:
	_result_title.text = "MOUNTAIN PAINTED"
	_result_title.add_theme_color_override("font_color", BLUE)
	_result_stars.text = "★".repeat(stars) + "☆".repeat(maxi(0, 3 - stars))
	_result_details.text = "FINAL COVERAGE  %.2f%%\nTARGET  %.2f%%\nSHOTS USED  %d\nPREVIOUS BEST  %.2f%%" % [
		final_coverage,
		_stage_data.target_coverage,
		shots_used,
		previous_best,
	]


func show_failure(final_coverage: float, missing: float, previous_best: float = 0.0) -> void:
	_result_title.text = "TARGET NOT REACHED"
	_result_title.add_theme_color_override("font_color", NAVY)
	_result_stars.text = "☆☆☆"
	_result_details.text = "FINAL COVERAGE  %.2f%%\nMISSING  %.2f%%\nPREVIOUS BEST  %.2f%%\nTRY A HIGHER ROUTE" % [
		final_coverage,
		missing,
		previous_best,
	]


func _build_interface() -> void:
	_root = Control.new()
	_root.name = "HUDRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_build_top_information()
	_build_briefing()
	_build_aim_controls()
	_build_coverage()
	_build_actions()
	_build_observation_controls()
	_build_shot_result()
	_build_result_panel()
	_build_pause_overlay()


func _build_top_information() -> void:
	var stage_panel := _make_panel(Vector2(174.0, 58.0))
	stage_panel.position = Vector2(24.0, 20.0)
	_root.add_child(stage_panel)
	_stage_value = _make_label("LEVEL 01", 21, NAVY)
	_add_centered(stage_panel, _stage_value)

	var target_panel := _make_panel(Vector2(430.0, 58.0))
	target_panel.anchor_left = 0.5
	target_panel.anchor_right = 0.5
	target_panel.offset_left = -215.0
	target_panel.offset_right = 215.0
	target_panel.offset_top = 20.0
	target_panel.offset_bottom = 78.0
	_root.add_child(target_panel)
	_target_value = _make_label("TARGET COVERAGE   0.25%", 21, NAVY)
	_add_centered(target_panel, _target_value)

	var shots_panel := _make_panel(Vector2(226.0, 58.0))
	shots_panel.anchor_left = 1.0
	shots_panel.anchor_right = 1.0
	shots_panel.offset_left = -250.0
	shots_panel.offset_right = -24.0
	shots_panel.offset_top = 20.0
	shots_panel.offset_bottom = 78.0
	_root.add_child(shots_panel)
	_shots_value = _make_label("SHOTS LEFT   4", 21, NAVY)
	_add_centered(shots_panel, _shots_value)

	var status_panel := _make_panel(Vector2(170.0, 44.0), NAVY, 12)
	status_panel.position = Vector2(30.0, 92.0)
	_root.add_child(status_panel)
	_status_value = _make_label("BRIEFING", 15, Color.WHITE)
	_add_centered(status_panel, _status_value)


func _build_briefing() -> void:
	_briefing_panel = _make_panel(Vector2(760.0, 210.0))
	_briefing_panel.name = "BriefingPanel"
	_briefing_panel.anchor_left = 0.5
	_briefing_panel.anchor_right = 0.5
	_briefing_panel.anchor_top = 1.0
	_briefing_panel.anchor_bottom = 1.0
	_briefing_panel.offset_left = -380.0
	_briefing_panel.offset_right = 380.0
	_briefing_panel.offset_top = -236.0
	_briefing_panel.offset_bottom = -24.0
	_root.add_child(_briefing_panel)
	var margin := _add_margin(_briefing_panel, 24, 18, 24, 18)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	_briefing_title = _make_label("FIRST DESCENT", 28, NAVY)
	content.add_child(_briefing_title)
	_briefing_objective = _make_label("Read the slope, then choose one high-value landing point.", 16, CHARCOAL)
	_briefing_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_briefing_objective)
	_briefing_mechanisms = _make_label("NO MECHANISMS", 13, BLUE)
	_briefing_mechanisms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_briefing_mechanisms)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var hint := _make_label("LEFT-DRAG ORBIT  ·  WHEEL ZOOM", 13, MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hint)
	var back := _make_button("BACK", false, Vector2(104.0, 52.0))
	back.pressed.connect(func() -> void: stage_select_requested.emit())
	row.add_child(back)
	_start_button = _make_button("START AIMING", true, Vector2(178.0, 52.0))
	_start_button.pressed.connect(func() -> void: begin_aiming_requested.emit())
	row.add_child(_start_button)


func _build_aim_controls() -> void:
	_aim_panel = _make_panel(Vector2(300.0, 112.0))
	_aim_panel.anchor_top = 1.0
	_aim_panel.anchor_bottom = 1.0
	_aim_panel.offset_left = 24.0
	_aim_panel.offset_right = 324.0
	_aim_panel.offset_top = -136.0
	_aim_panel.offset_bottom = -24.0
	_root.add_child(_aim_panel)
	var margin := _add_margin(_aim_panel, 22, 14, 22, 14)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	row.add_child(_metric_column("ANGLE", "38°", true))
	var divider := VSeparator.new()
	divider.custom_minimum_size.x = 1.0
	row.add_child(divider)
	row.add_child(_metric_column("POWER", "68%", false))


func _metric_column(caption: String, value: String, is_angle: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 105.0
	var caption_label := _make_label(caption, 13, MUTED)
	column.add_child(caption_label)
	var value_label := _make_label(value, 29, NAVY if is_angle else BLUE)
	column.add_child(value_label)
	if is_angle:
		_angle_value = value_label
	else:
		_power_value = value_label
	return column


func _build_coverage() -> void:
	_coverage_panel = _make_panel(Vector2(560.0, 82.0))
	_coverage_panel.anchor_left = 0.5
	_coverage_panel.anchor_right = 0.5
	_coverage_panel.anchor_top = 1.0
	_coverage_panel.anchor_bottom = 1.0
	_coverage_panel.offset_left = -280.0
	_coverage_panel.offset_right = 280.0
	_coverage_panel.offset_top = -106.0
	_coverage_panel.offset_bottom = -24.0
	_root.add_child(_coverage_panel)
	var margin := _add_margin(_coverage_panel, 20, 13, 20, 13)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	row.add_child(_make_label("COVERAGE", 14, MUTED))
	_coverage_bar = ProgressBar.new()
	_coverage_bar.custom_minimum_size = Vector2(330.0, 22.0)
	_coverage_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_coverage_bar.max_value = 100.0
	_coverage_bar.show_percentage = false
	_coverage_bar.add_theme_stylebox_override("background", _style(Color(0.72, 0.73, 0.74, 0.65), 7))
	_coverage_bar.add_theme_stylebox_override("fill", _style(BLUE, 7))
	row.add_child(_coverage_bar)
	_coverage_value = _make_label("00.00%", 26, NAVY)
	row.add_child(_coverage_value)


func _build_actions() -> void:
	_action_panel = HBoxContainer.new()
	_action_panel.anchor_left = 1.0
	_action_panel.anchor_right = 1.0
	_action_panel.anchor_top = 1.0
	_action_panel.anchor_bottom = 1.0
	_action_panel.offset_left = -340.0
	_action_panel.offset_right = -24.0
	_action_panel.offset_top = -148.0
	_action_panel.offset_bottom = -24.0
	_action_panel.add_theme_constant_override("separation", 12)
	_root.add_child(_action_panel)
	var restart := _make_button("↻\nRESTART", false, Vector2(124.0, 124.0))
	restart.pressed.connect(func() -> void: restart_requested.emit())
	_action_panel.add_child(restart)
	_fire_button = _make_button("●\nFIRE", true, Vector2(180.0, 124.0))
	_fire_button.add_theme_font_size_override("font_size", 24)
	_fire_button.pressed.connect(func() -> void: fire_requested.emit())
	_action_panel.add_child(_fire_button)


func _build_observation_controls() -> void:
	_observation_panel = HBoxContainer.new()
	_observation_panel.anchor_left = 1.0
	_observation_panel.anchor_right = 1.0
	_observation_panel.offset_left = -560.0
	_observation_panel.offset_right = -24.0
	_observation_panel.offset_top = 92.0
	_observation_panel.offset_bottom = 142.0
	_observation_panel.add_theme_constant_override("separation", 8)
	_root.add_child(_observation_panel)
	for entry in [["FOLLOW", CameraDirector.Mode.FOLLOW], ["WIDE", CameraDirector.Mode.WIDE], ["CANNON", CameraDirector.Mode.CANNON]]:
		var button := _make_button(entry[0], false, Vector2(92.0, 48.0))
		var mode: int = entry[1]
		button.pressed.connect(func() -> void: camera_mode_requested.emit(mode))
		_observation_panel.add_child(button)
	for speed_value in [1.0, 2.0]:
		var speed := _make_button("%d×" % roundi(speed_value), false, Vector2(58.0, 48.0))
		var requested_speed: float = speed_value
		speed.pressed.connect(func() -> void: simulation_speed_requested.emit(requested_speed))
		_observation_panel.add_child(speed)
	var pause := _make_button("PAUSE", false, Vector2(82.0, 48.0))
	pause.pressed.connect(func() -> void: pause_requested.emit())
	_observation_panel.add_child(pause)


func _build_shot_result() -> void:
	_shot_result_panel = _make_panel(Vector2(340.0, 58.0), Color(0.04, 0.08, 0.14, 0.92), 12)
	_shot_result_panel.anchor_left = 0.5
	_shot_result_panel.anchor_right = 0.5
	_shot_result_panel.offset_left = -170.0
	_shot_result_panel.offset_right = 170.0
	_shot_result_panel.offset_top = 92.0
	_shot_result_panel.offset_bottom = 150.0
	_root.add_child(_shot_result_panel)
	_shot_result_value = _make_label("+0.00%  ·  TOTAL 0.00%", 18, Color.WHITE)
	_add_centered(_shot_result_panel, _shot_result_value)


func _build_result_panel() -> void:
	_result_panel = _make_panel(Vector2(440.0, 520.0))
	_result_panel.name = "ResultPanel"
	_result_panel.anchor_left = 1.0
	_result_panel.anchor_right = 1.0
	_result_panel.anchor_top = 0.5
	_result_panel.anchor_bottom = 0.5
	_result_panel.offset_left = -480.0
	_result_panel.offset_right = -40.0
	_result_panel.offset_top = -260.0
	_result_panel.offset_bottom = 260.0
	_root.add_child(_result_panel)
	var margin := _add_margin(_result_panel, 28, 28, 28, 28)
	margin.name = "Margin"
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	_result_title = _make_label("MOUNTAIN PAINTED", 28, BLUE)
	_result_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_result_title)
	_result_stars = _make_label("★★★", 30, BLUE)
	content.add_child(_result_stars)
	_result_details = _make_label("FINAL COVERAGE  0.00%", 18, CHARCOAL)
	_result_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_result_details)
	var retry := _make_button("RETRY", true, Vector2(0.0, 56.0))
	retry.name = "Retry"
	retry.pressed.connect(func() -> void: restart_requested.emit())
	content.add_child(retry)
	var primary_row := HBoxContainer.new()
	primary_row.add_theme_constant_override("separation", 10)
	content.add_child(primary_row)
	_next_button = _make_button("NEXT", false, Vector2(182.0, 52.0))
	_next_button.pressed.connect(func() -> void: next_stage_requested.emit())
	primary_row.add_child(_next_button)
	var select := _make_button("STAGES", false, Vector2(182.0, 52.0))
	select.pressed.connect(func() -> void: stage_select_requested.emit())
	primary_row.add_child(select)
	var replay := _make_button("REPLAY ATTEMPT", false, Vector2(0.0, 52.0))
	replay.pressed.connect(func() -> void: replay_requested.emit())
	content.add_child(replay)


func _build_pause_overlay() -> void:
	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_pause_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.035, 0.06, 0.56)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(dim)
	var panel := _make_panel(Vector2(380.0, 540.0))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -190.0
	panel.offset_right = 190.0
	panel.offset_top = -270.0
	panel.offset_bottom = 270.0
	_pause_overlay.add_child(panel)
	var margin := _add_margin(panel, 28, 28, 28, 28)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	content.add_child(_make_label("PAUSED", 30, NAVY))
	var resume := _make_button("RESUME", true, Vector2(0.0, 56.0))
	resume.pressed.connect(func() -> void: pause_requested.emit())
	content.add_child(resume)
	var restart := _make_button("RESTART", false, Vector2(0.0, 52.0))
	restart.pressed.connect(func() -> void: restart_requested.emit())
	content.add_child(restart)
	var settings := _make_button("SETTINGS", false, Vector2(0.0, 52.0))
	settings.pressed.connect(func() -> void: settings_requested.emit())
	content.add_child(settings)
	var stages := _make_button("STAGE SELECT", false, Vector2(0.0, 52.0))
	stages.pressed.connect(func() -> void: stage_select_requested.emit())
	content.add_child(stages)
	var main_menu := _make_button("QUIT TO MAIN MENU", false, Vector2(0.0, 52.0))
	main_menu.pressed.connect(func() -> void: main_menu_requested.emit())
	content.add_child(main_menu)


func _make_panel(minimum_size: Vector2, color: Color = OFF_WHITE, radius: int = 14) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _style(color, radius, true))
	return panel


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_button(text: String, accent: bool, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE if accent else NAVY)
	button.add_theme_color_override("font_hover_color", Color.WHITE if accent else NAVY)
	button.add_theme_color_override("font_focus_color", Color.WHITE if accent else NAVY)
	button.add_theme_stylebox_override("normal", _style(BLUE if accent else OFF_WHITE, 14, true))
	button.add_theme_stylebox_override("hover", _style(BLUE_HOVER if accent else Color(0.92, 0.95, 1.0, 0.98), 14, true))
	button.add_theme_stylebox_override("pressed", _style(Color(0.02, 0.28, 0.78, 1.0) if accent else Color(0.86, 0.9, 0.96, 1.0), 14, false))
	button.add_theme_stylebox_override("focus", _outline_style(BLUE))
	return button


func _style(color: Color, radius: int, shadow: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if shadow:
		style.shadow_color = Color(0.02, 0.04, 0.08, 0.18)
		style.shadow_size = 10
	return style


func _outline_style(color: Color) -> StyleBoxFlat:
	var style := _style(Color(0, 0, 0, 0), 14)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = color
	style.expand_margin_left = 3.0
	style.expand_margin_top = 3.0
	style.expand_margin_right = 3.0
	style.expand_margin_bottom = 3.0
	return style


func _add_margin(parent: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	parent.add_child(margin)
	return margin


func _add_centered(parent: Control, child: Control) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)
	center.add_child(child)


func _display_state_name(state: StageController.State) -> String:
	match state:
		StageController.State.PROJECTILE_IN_FLIGHT:
			return "IN FLIGHT"
		StageController.State.PAINT_SETTLING:
			return "PAINT SETTLING"
		StageController.State.SHOT_RESULT:
			return "SHOT RESULT"
		StageController.State.STAGE_CLEAR:
			return "STAGE CLEAR"
		StageController.State.STAGE_FAILED:
			return "STAGE FAILED"
		_:
			return StageController.State.keys()[state].replace("_", " ")


func _mechanism_brief(stage: StageData) -> String:
	if stage.mechanism_loadout.is_empty():
		return "NO MECHANISMS  ·  FOLLOW THE NATURAL DESCENT"
	var descriptions: Array[String] = []
	for mechanism_data in stage.mechanism_loadout:
		descriptions.append("%s — %s" % [mechanism_data.display_name, mechanism_data.description])
	return "    ".join(descriptions)
