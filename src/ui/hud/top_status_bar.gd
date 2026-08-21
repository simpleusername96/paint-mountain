class_name TopStatusBar
extends Control

const CENTERED_ICON_TEXTURE := preload("res://src/ui/components/centered_icon_texture.gd")

signal settings_requested

@onready var stage_value: Label = %StageValue
@onready var stage_name: Label = %StageName
@onready var mode_value: Label = %ModeValue
@onready var settings_button: Button = %SettingsButton

var _compact := false
var _density := 1.0
var _current_state := StageController.State.LOADING


func _ready() -> void:
	settings_button.icon = CENTERED_ICON_TEXTURE.from_source(settings_button.icon)
	settings_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	%SettingsButton.pressed.connect(func() -> void: settings_requested.emit())


func configure(stage: StageData) -> void:
	stage_value.text = "▲ %s %02d" % [tr("hud.stage"), stage.stage_number]
	stage_name.text = tr(String(stage.display_name_key))


func update_mode(state: StageController.State) -> void:
	_current_state = state
	stage_name.visible = state == StageController.State.BRIEFING and not _compact
	var key: String = String({
		StageController.State.BRIEFING: "hud.briefing",
		StageController.State.AIMING: "hud.aiming",
		StageController.State.PROJECTILE_IN_FLIGHT: "hud.in_flight",
		StageController.State.PAINT_SETTLING: "hud.paint_settling",
		StageController.State.SHOT_RESULT: "hud.shot_result",
		StageController.State.FINISHING: "hud.finishing",
		StageController.State.RESULT: "hud.result",
	}.get(state, "hud.aiming"))
	mode_value.text = tr(key)
	mode_value.get_parent().visible = state == StageController.State.BRIEFING and not _compact


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0)
	var safe := 12.0 * _density if compact else 24.0
	stage_value.position = Vector2(safe, safe)
	stage_value.size = Vector2(180.0 * _density, 44.0 * _density)
	stage_name.position = Vector2(safe, safe + 38.0 * _density)
	stage_name.size = Vector2(300.0 * _density, 34.0 * _density)
	stage_value.add_theme_font_size_override(&"font_size", roundi(16.0 * _density) if compact else 20)
	stage_name.add_theme_font_size_override(&"font_size", roundi(14.0 * _density) if compact else 22)
	var button_size := 44.0 * _density if compact else 48.0
	settings_button.position = Vector2(size.x - safe - button_size, safe)
	settings_button.size = Vector2(button_size, button_size)
	settings_button.add_theme_constant_override(
		&"icon_max_width", roundi(20.0 * _density) if compact else 22
	)
	update_mode(_current_state)


func set_settings_visible(visible: bool) -> void:
	settings_button.visible = visible
