class_name ActionControl
extends Button

## Shared icon-only action. Screens select semantics and role; this component
## owns the visible asset, target size, accessible copy, and interaction style.

enum IconKind {
	NONE,
	PLAY,
	PREVIOUS,
	NEXT,
	STAGES,
	HOME,
	CLOSE,
	QUIT,
	FIRE,
	FINISH,
	AIM,
	RETURN_TO_CANNON,
	SETTINGS,
	RETRY,
	NEW_DEAL,
	DEFAULTS,
}

enum VisualRole {
	ROUTINE,
	PRIMARY,
	SELECTED,
	DESTRUCTIVE,
	WORLD,
}

const ICONS := {
	IconKind.PLAY: preload("res://assets/ui/icons/actions/play.png"),
	IconKind.PREVIOUS: preload("res://assets/ui/icons/actions/previous.png"),
	IconKind.NEXT: preload("res://assets/ui/icons/actions/next.png"),
	IconKind.STAGES: preload("res://assets/ui/icons/actions/stages.png"),
	IconKind.HOME: preload("res://assets/ui/icons/actions/home.png"),
	IconKind.CLOSE: preload("res://assets/ui/icons/actions/close.png"),
	IconKind.QUIT: preload("res://assets/ui/icons/actions/quit.png"),
	IconKind.FIRE: preload("res://assets/ui/icons/paint_splash.svg"),
	IconKind.FINISH: preload("res://assets/ui/icons/actions/finish.png"),
	IconKind.AIM: preload("res://assets/ui/icons/target.png"),
	IconKind.RETURN_TO_CANNON: preload("res://assets/ui/icons/actions/return_to_cannon.png"),
	IconKind.SETTINGS: preload("res://assets/ui/icons/actions/settings.png"),
	IconKind.RETRY: preload("res://assets/ui/icons/actions/retry.png"),
	IconKind.NEW_DEAL: preload("res://assets/ui/icons/actions/new_deal.png"),
	IconKind.DEFAULTS: preload("res://assets/ui/icons/actions/defaults.png"),
}
const CENTERED_ICON_TEXTURE := preload("res://src/ui/components/centered_icon_texture.gd")

const ROLE_THEMES := {
	VisualRole.ROUTINE: &"ActionRoutine",
	VisualRole.PRIMARY: &"ActionPrimary",
	VisualRole.SELECTED: &"ActionSelected",
	VisualRole.DESTRUCTIVE: &"ActionDestructive",
	VisualRole.WORLD: &"ActionWorld",
}

@export var action_kind: IconKind = IconKind.FIRE
@export var visual_role: VisualRole = VisualRole.ROUTINE
@export var label_key := "ui.fire"

var _compact := false
var _density := 1.0
var _readiness_reason := ""
var _icon_width_override := 0.0


func _ready() -> void:
	clip_text = true
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_ALL
	_apply_visual_contract()
	refresh_locale()


func configure(
		localized_label_key: String,
		icon_kind: IconKind = action_kind,
		role: VisualRole = visual_role
) -> void:
	label_key = localized_label_key
	action_kind = icon_kind
	visual_role = role
	_apply_visual_contract()
	refresh_locale()


func set_visual_role(role: VisualRole) -> void:
	visual_role = role
	_apply_visual_contract()


func set_compact(compact: bool, density: float = 1.0) -> void:
	_compact = compact
	_density = maxf(density, 1.0)
	_apply_visual_contract()


func set_icon_width(width: float) -> void:
	_icon_width_override = maxf(width, 0.0)
	_apply_visual_contract()


func preferred_edge() -> float:
	return _base_edge() * _density


func refresh_locale() -> void:
	var localized := tr(label_key)
	text = ""
	accessibility_name = localized
	tooltip_text = _readiness_reason if disabled and not _readiness_reason.is_empty() else localized
	accessibility_description = tooltip_text


func set_readiness(enabled: bool, reason: String = "") -> void:
	disabled = not enabled
	_readiness_reason = reason if not enabled else ""
	refresh_locale()


func _apply_visual_contract() -> void:
	text = ""
	icon = CENTERED_ICON_TEXTURE.from_source(ICONS.get(action_kind) as Texture2D)
	theme_type_variation = ROLE_THEMES.get(visual_role, &"ActionRoutine")
	var edge := preferred_edge()
	custom_minimum_size = Vector2(edge, edge)
	var icon_width := _icon_width_override if _icon_width_override > 0.0 \
			else (22.0 if _compact else 24.0)
	add_theme_constant_override(&"icon_max_width", roundi(icon_width * _density))


func _base_edge() -> float:
	if visual_role == VisualRole.PRIMARY:
		return 48.0 if _compact else 56.0
	return 40.0 if _compact else 44.0
