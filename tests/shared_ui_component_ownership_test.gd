extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var theme: Theme = load("res://resources/ui/paint_mountain_theme.tres")
	for variation in [
		&"ScoreScale", &"AimScoreStatus", &"BallQueue", &"ValueStepper", &"StageRail", &"ResultSummary",
		&"WorldGradientScrim", &"ContextLegend",
	]:
		_assert(theme.is_type_variation(variation, &"Control")
				or theme.is_type_variation(variation, &"HBoxContainer")
				or theme.is_type_variation(variation, &"VBoxContainer"),
				"%s must inherit the canonical Theme" % variation)
	for variation in [
		&"BallQueueToken", &"ActionControl", &"ActionRoutine", &"ActionPrimary",
		&"ActionSelected", &"ActionDestructive", &"ActionWorld", &"StageRailButton",
	]:
		_assert(theme.is_type_variation(variation, &"Button"), "%s must be a shared button role" % variation)
	_assert(theme.get_stylebox(&"normal", &"ActionRoutine") is StyleBoxEmpty,
		"routine icon actions must have no normal background surface")
	var primary_style := theme.get_stylebox(&"normal", &"ActionPrimary") as StyleBoxFlat
	_assert(primary_style != null and primary_style.bg_color.is_equal_approx(Color("2584ff")),
		"primary icon actions must use the single filled blue role")
	var action := (load("res://scenes/ui/components/action_control.tscn") as PackedScene).instantiate() as ActionControl
	root.add_child(action)
	action.configure("ui.play", ActionControl.IconKind.PLAY, ActionControl.VisualRole.ROUTINE)
	_assert(action.text.is_empty() and action.icon != null,
		"ActionControl must show a semantic asset and no visible verb text")
	_assert(action.accessibility_name == tr("ui.play") and not action.tooltip_text.is_empty(),
		"icon-only actions must retain localized accessibility and tooltip copy")
	_assert(action.custom_minimum_size == Vector2(44.0, 44.0),
		"standard routine actions must use the shared 44px target")
	action.set_compact(true)
	_assert(action.custom_minimum_size == Vector2(40.0, 40.0),
		"compact routine actions must use the shared 40px target")
	action.configure("ui.fire", ActionControl.IconKind.FIRE, ActionControl.VisualRole.PRIMARY)
	_assert(action.custom_minimum_size == Vector2(48.0, 48.0)
			and action.theme_type_variation == &"ActionPrimary",
		"compact primary actions must use the shared 48px blue role")
	action.queue_free()
	_assert(theme.is_type_variation(&"BallQueueDescription", &"Label"),
		"BallQueueDescription must be a shared direct-label role")
	_assert(theme.has_color(&"world_outline", &"ScoreScale")
			and theme.has_constant(&"world_outline_size", &"ScoreScale"),
		"ScoreScale world contrast must remain Theme-owned")
	_assert(theme.has_color(&"icon_color", &"ContextLegend"),
		"ContextLegend icon tint must remain Theme-owned")
	for variation in [&"ContrastScrim", &"InterruptionSurface", &"DirectOverlay"]:
		_assert(theme.is_type_variation(variation, &"PanelContainer"), "%s must be a shared surface role" % variation)

	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	var hud_root := hud.get_node("HUDRoot")
	_assert(hud_root.get_node("AimScoreStatus") is AimScoreStatus,
		"HUD must compose the sole shared live AimScoreStatus")
	_assert(hud_root.get_node("BallQueue") is BallQueue, "HUD must compose the sole shared BallQueue")
	_assert((hud_root.get_node("BallQueue") as BallQueue).find_children("*", "Panel", true, false).size() == 1,
		"BallQueue must own exactly one white detail card")
	_assert(hud_root.get_node_or_null("CoverageMeter") == null, "legacy coverage component must not remain in production HUD")
	_assert(hud_root.get_node_or_null("TargetBandMeter") == null, "cropped target-band component must not remain in production HUD")
	_assert(hud_root.get_node_or_null("QueueRail") == null, "legacy vertical queue must not remain in production HUD")
	var aim := hud_root.get_node("AimControls") as AimControls
	_assert(aim.get_node("Content/AngleStepper") is ValueStepper, "Aim angle must use ValueStepper")
	_assert(aim.get_node("Content/PowerStepper") is ValueStepper, "Aim power must use ValueStepper")
	var fire := hud_root.get_node("ActionButtons/FireButton")
	_assert(fire is ActionControl and fire.visual_role == ActionControl.VisualRole.PRIMARY
			and fire.text.is_empty() and fire.icon != null,
		"Fire must use the icon-only shared primary ActionControl")
	for stepper_path in ["Content/AngleStepper", "Content/PowerStepper"]:
		var stepper := aim.get_node(stepper_path) as ValueStepper
		_assert(stepper.decrease_button.custom_minimum_size.y >= 40.0, "%s decrease target must be routine-sized" % stepper_path)
		_assert(stepper.increase_button.custom_minimum_size.y >= 40.0, "%s increase target must be routine-sized" % stepper_path)
		_assert(not stepper.decrease_button.accessibility_name.is_empty(), "%s must expose an accessible decrease name" % stepper_path)
		_assert(not stepper.increase_button.accessibility_name.is_empty(), "%s must expose an accessible increase name" % stepper_path)

	for scene_path in [
		"res://scenes/ui/components/stage_rail.tscn",
		"res://scenes/ui/components/result_summary.tscn",
		"res://scenes/ui/components/contrast_scrim.tscn",
		"res://scenes/ui/components/world_gradient_scrim.tscn",
	]:
		var instance := (load(scene_path) as PackedScene).instantiate()
		root.add_child(instance)
		_assert(instance.scene_file_path == scene_path, "%s must have one production scene owner" % scene_path)
		instance.queue_free()

	hud.queue_free()
	await process_frame
	if not _failed:
		print("shared_ui_component_ownership_test passed: canonical roles and single HUD owners")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Shared UI ownership contract failed: %s" % message)
