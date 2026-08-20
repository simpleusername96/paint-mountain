extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var theme: Theme = load("res://resources/ui/paint_mountain_theme.tres")
	for variation in [
		&"ScoreScale", &"BallQueue", &"ValueStepper", &"StageRail", &"ResultSummary",
		&"WorldGradientScrim", &"ContextLegend",
	]:
		_assert(theme.is_type_variation(variation, &"Control")
				or theme.is_type_variation(variation, &"HBoxContainer")
				or theme.is_type_variation(variation, &"VBoxContainer"),
				"%s must inherit the canonical Theme" % variation)
	for variation in [&"BallQueueToken", &"ActionControl", &"StageRailButton"]:
		_assert(theme.is_type_variation(variation, &"Button"), "%s must be a shared button role" % variation)
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
	_assert(hud_root.get_node("ScoreScale") is ScoreScale, "HUD must compose the sole shared ScoreScale")
	_assert(hud_root.get_node("BallQueue") is BallQueue, "HUD must compose the sole shared BallQueue")
	_assert(hud_root.get_node_or_null("CoverageMeter") == null, "legacy coverage component must not remain in production HUD")
	_assert(hud_root.get_node_or_null("TargetBandMeter") == null, "cropped target-band component must not remain in production HUD")
	_assert(hud_root.get_node_or_null("QueueRail") == null, "legacy vertical queue must not remain in production HUD")
	var aim := hud_root.get_node("AimControls") as AimControls
	_assert(aim.get_node("Content/AngleStepper") is ValueStepper, "Aim angle must use ValueStepper")
	_assert(aim.get_node("Content/PowerStepper") is ValueStepper, "Aim power must use ValueStepper")
	var fire := hud_root.get_node("ActionButtons/FireButton")
	_assert(fire is ActionControl and fire.custom_minimum_size.y >= 44.0, "Fire must use the shared routine-sized ActionControl")
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
