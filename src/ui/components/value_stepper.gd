class_name ValueStepper
extends HBoxContainer

signal step_requested(direction: float)

const HOLD_DELAY := 0.30
const HOLD_REPEAT := 0.08

@onready var caption: Label = %Caption
@onready var decrease_button: Button = %Decrease
@onready var value_label: Label = %Value
@onready var increase_button: Button = %Increase

var _caption_key := ""
var _decrease_key := ""
var _increase_key := ""
var _suffix := ""
var _decrease_step := -1.0
var _increase_step := 1.0
var _hold_direction := 0.0
var _hold_elapsed := 0.0
var _next_repeat := HOLD_DELAY


func _ready() -> void:
	decrease_button.button_down.connect(_begin_hold.bind(_decrease_step))
	increase_button.button_down.connect(_begin_hold.bind(_increase_step))
	decrease_button.button_up.connect(_end_hold)
	increase_button.button_up.connect(_end_hold)
	refresh_locale()


func configure(
		caption_key: String,
		decrease_key: String,
		increase_key: String,
		suffix: String,
		decrease_step: float,
		increase_step: float
) -> void:
	_caption_key = caption_key
	_decrease_key = decrease_key
	_increase_key = increase_key
	_suffix = suffix
	_decrease_step = decrease_step
	_increase_step = increase_step
	if is_node_ready():
		refresh_locale()


func refresh_locale() -> void:
	if not is_node_ready():
		return
	caption.text = tr(_caption_key) if not _caption_key.is_empty() else ""
	decrease_button.tooltip_text = tr(_decrease_key) if not _decrease_key.is_empty() else ""
	increase_button.tooltip_text = tr(_increase_key) if not _increase_key.is_empty() else ""
	decrease_button.accessibility_name = decrease_button.tooltip_text
	increase_button.accessibility_name = increase_button.tooltip_text
	accessibility_name = caption.text


func set_value(value: float, minimum: float, maximum: float) -> void:
	value_label.text = "%.1f%s" % [value, _suffix]
	decrease_button.disabled = value <= minimum
	increase_button.disabled = value >= maximum


func set_compact(compact: bool, density: float = 1.0) -> void:
	var scale := maxf(density, 1.0) if compact else 1.0
	custom_minimum_size = Vector2(166.0, 52.0) * scale
	add_theme_constant_override(&"separation", roundi(4.0 * scale))
	caption.custom_minimum_size = Vector2(48.0, 48.0) * scale
	for button in [decrease_button, increase_button]:
		button.custom_minimum_size = Vector2(42.0, 48.0) * scale
		button.add_theme_constant_override(&"icon_max_width", roundi(24.0 * scale))
	value_label.custom_minimum_size = Vector2(70.0, 48.0) * scale
	value_label.add_theme_font_size_override(
		&"font_size", roundi(22.0 * scale) if compact else 22
	)


func _process(delta: float) -> void:
	if is_zero_approx(_hold_direction):
		return
	_hold_elapsed += delta
	while _hold_elapsed >= _next_repeat:
		step_requested.emit(_hold_direction)
		_next_repeat += HOLD_REPEAT


func _begin_hold(direction: float) -> void:
	# Read the configured step at interaction time so scene startup order cannot
	# retain the default value after AimControls configures the component.
	var resolved := _decrease_step if direction < 0.0 else _increase_step
	step_requested.emit(resolved)
	_hold_direction = resolved
	_hold_elapsed = 0.0
	_next_repeat = HOLD_DELAY


func _end_hold() -> void:
	_hold_direction = 0.0
