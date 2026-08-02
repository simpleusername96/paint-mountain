class_name MainMenuScreen
extends CanvasLayer

signal play_requested
signal stage_select_requested
signal settings_requested
signal quit_requested

var _play_button: Button


func _ready() -> void:
	layer = 20
	_build()


func focus_primary() -> void:
	if _play_button != null:
		_play_button.grab_focus()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.045, 0.075, 0.2)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var brand_panel := UIFactory.panel(Vector2(620.0, 650.0), Color(0.98, 0.97, 0.94, 0.92), 26)
	brand_panel.anchor_left = 0.0
	brand_panel.anchor_top = 0.5
	brand_panel.anchor_bottom = 0.5
	brand_panel.offset_left = 88.0
	brand_panel.offset_right = 708.0
	brand_panel.offset_top = -325.0
	brand_panel.offset_bottom = 325.0
	root.add_child(brand_panel)
	var margin := UIFactory.margin(brand_panel, Vector4(52, 48, 52, 48))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

	var eyebrow := UIFactory.label("A PHYSICS PAINT PUZZLE", 17, UIFactory.BLUE)
	content.add_child(eyebrow)
	var title := UIFactory.label("PAINT\nMOUNTAIN", 70, UIFactory.NAVY)
	title.add_theme_constant_override("line_spacing", -10)
	content.add_child(title)
	var subtitle := UIFactory.label("Aim once. Trust gravity.\nPaint the impossible route.", 22, UIFactory.CHARCOAL)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(subtitle)

	_play_button = UIFactory.button("PLAY", true, Vector2(0.0, 72.0))
	_play_button.pressed.connect(func() -> void: play_requested.emit())
	content.add_child(_play_button)
	var stage_select := UIFactory.button("STAGE SELECT", false, Vector2(0.0, 64.0))
	stage_select.pressed.connect(func() -> void: stage_select_requested.emit())
	content.add_child(stage_select)
	var settings := UIFactory.button("SETTINGS", false, Vector2(0.0, 64.0))
	settings.pressed.connect(func() -> void: settings_requested.emit())
	content.add_child(settings)
	var quit := UIFactory.button("QUIT", false, Vector2(0.0, 54.0))
	quit.pressed.connect(func() -> void: quit_requested.emit())
	content.add_child(quit)

	var version := UIFactory.label("VERTICAL SLICE  ·  GODOT 4", 14, Color(0.95, 0.97, 1.0, 0.92))
	version.anchor_left = 1.0
	version.anchor_right = 1.0
	version.anchor_top = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = -310.0
	version.offset_right = -54.0
	version.offset_top = -74.0
	version.offset_bottom = -44.0
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(version)

