class_name ContextLegend
extends Control

## One presentation-only input sentence. Device input stays in gameplay owners.

enum Mode {
	AIM,
	MAP,
	FOLLOW,
	BRIEFING,
	PAUSE,
}

@export var context_mode := Mode.AIM:
	set(value):
		context_mode = value
		_refresh()

@onready var _items: Array[Control] = [
	%AngleItem,
	%OrbitItem,
	%PowerItem,
	%FireItem,
	%ModeItem,
	%FinishItem,
	%MenuItem,
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_apply_width_priority)
	_refresh()


func set_context(mode: Mode) -> void:
	context_mode = mode


func refresh_locale() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	%AngleItem.get_node("Action").text = tr("hud.angle")
	%OrbitItem.get_node("Input").text = tr("input.drag")
	%OrbitItem.get_node("Action").text = tr("hud.orbit")
	%PowerItem.get_node("Action").text = tr(
		"hud.zoom" if context_mode in [Mode.MAP, Mode.BRIEFING] else "hud.power"
	)
	%FireItem.get_node("Action").text = tr("ui.fire")
	%FinishItem.get_node("Action").text = tr("ui.finish")
	match context_mode:
		Mode.AIM:
			%ModeItem.get_node("Action").text = tr("hud.map")
		Mode.MAP:
			%ModeItem.get_node("Action").text = tr("hud.aim_lock")
		Mode.FOLLOW:
			%ModeItem.get_node("Action").text = tr("hud.return_to_cannon")
	%MenuItem.get_node("Action").text = tr(
		"ui.resume" if context_mode == Mode.PAUSE else "ui.menu"
	)
	_apply_width_priority()


func _apply_width_priority() -> void:
	if not is_node_ready() or size.x <= 0.0:
		return
	_set_context_visibility()
	# The legend remains a single bounded sentence: when a narrow viewport cannot
	# hold every optional cue, remove the least immediate board actions first.
	for item in [%FinishItem, %ModeItem]:
		if _visible_items_width() <= size.x:
			break
		item.visible = false
	_update_separators()


func _set_context_visibility() -> void:
	%AngleItem.visible = context_mode == Mode.AIM
	%OrbitItem.visible = context_mode in [Mode.MAP, Mode.BRIEFING]
	%PowerItem.visible = context_mode in [Mode.AIM, Mode.MAP, Mode.BRIEFING]
	%FireItem.visible = context_mode == Mode.AIM
	%ModeItem.visible = context_mode in [Mode.AIM, Mode.FOLLOW]
	%FinishItem.visible = context_mode == Mode.AIM
	%MenuItem.visible = context_mode not in [Mode.BRIEFING, Mode.MAP]


func _visible_items_width() -> float:
	var width := 0.0
	var visible_count := 0
	for item in _items:
		if not item.visible:
			continue
		width += item.get_combined_minimum_size().x
		visible_count += 1
	return width + maxf(0.0, float(visible_count - 1) * 12.0)


func _update_separators() -> void:
	var has_visible_item := false
	for item in _items:
		if not item.visible:
			continue
		var separator := item.get_node("Separator") as Label
		separator.visible = has_visible_item
		has_visible_item = true
