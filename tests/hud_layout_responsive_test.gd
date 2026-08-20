extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")
const SAFE_MARGIN := 24.0
const VIEWPORTS := [
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(1024, 576),
	Vector2i(1024, 768),
	Vector2i(640, 360),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var previous_locale := TranslationServer.get_locale()
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for viewport_size in VIEWPORTS:
			await _assert_layout(locale, viewport_size)
	TranslationServer.set_locale(previous_locale)
	if not _failed:
		print("HUD layout passed: safe composition, component interiors, contrast roles, and bounded legend.")
	quit(1 if _failed else 0)


func _assert_layout(locale: String, viewport_size: Vector2i) -> void:
	root.size = viewport_size
	var hud := HUD_SCENE.instantiate() as HUDController
	root.add_child(hud)
	await process_frame
	var hud_root := hud.get_node("HUDRoot") as Control
	# CanvasLayer keeps the project logical viewport in headless mode, so drive
	# the composition root directly for this deterministic layout contract.
	hud_root.size = Vector2(viewport_size)
	await process_frame
	hud.show_state(StageController.State.AIMING)
	hud.set_camera_mode(CameraDirector.Mode.AIMING)
	await process_frame
	var queue := hud_root.get_node("BallQueue") as BallQueue
	var score_scale := hud_root.get_node("ScoreScale") as ScoreScale
	queue.show()
	score_scale.show()
	await process_frame
	var safe_margin := 12.0 if viewport_size.x < 960 or viewport_size.y < 620 else SAFE_MARGIN
	var safe_rect := Rect2(Vector2(safe_margin, safe_margin), Vector2(viewport_size) - Vector2(safe_margin * 2.0, safe_margin * 2.0))
	for path in [
		"TopStatusBar/StageValue",
		"TopStatusBar/SettingsButton",
		"RunStatusCard",
		"BallQueue",
		"ActionButtons",
		"ScoreScale",
	]:
		_assert_inside(hud_root.get_node(path) as Control, safe_rect, "%s at %s (%s)" % [path, viewport_size, locale])

	var actions := hud_root.get_node("ActionButtons") as ActionButtons
	var readiness := actions.get_node("ReadinessLabel") as Label
	for reason in [
		tr("fire.not_editable"),
		tr("fire.invalid_aim"),
		tr("fire.capacity") % [2, 2],
		tr("fire.empty"),
		tr("fire.terminal"),
	]:
		actions.set_fire_readiness({"fireable": false, "reason": reason})
		_assert_true(
			actions.get_global_rect().encloses(readiness.get_global_rect()),
			"readiness copy must remain inside ActionButtons at %s (%s)" % [viewport_size, locale]
		)
		var rendered_width := readiness.get_theme_font("font").get_string_size(
			reason,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			readiness.get_theme_font_size("font")
		).x
		_assert_true(
			rendered_width <= readiness.size.x,
			"readiness copy must fit without trimming at %s (%s): %s" % [viewport_size, locale, reason]
		)
	var fire := actions.get_node("FireButton") as Button
	_assert_true(fire.size.y >= 44.0, "Fire must keep a 44px target at %s" % viewport_size)
	fire.grab_focus()
	await process_frame
	_assert_true(fire.has_focus(), "Fire must remain keyboard focusable at %s" % viewport_size)

	var aim := hud_root.get_node("AimControls") as AimControls
	var legend := hud_root.get_node("ContextLegend") as ContextLegend
	_assert_inside(aim, safe_rect, "AimControls at %s (%s)" % [viewport_size, locale])
	_assert_true(
		aim.get_global_rect().encloses((aim.get_node("Content") as Control).get_global_rect()),
		"AimControls must contain its content at %s" % viewport_size
	)
	if viewport_size.x >= 960 and viewport_size.y >= 620:
		_assert_inside(legend, safe_rect, "ContextLegend at %s (%s)" % [viewport_size, locale])
	else:
		_assert_true(aim.visible and not legend.visible, "compact layout must retain aim controls and suppress only hints at %s" % viewport_size)
		_assert_pairwise_non_overlap([
			score_scale,
			queue,
			actions,
			aim.get_node("Content/AngleStepper") as Control,
			aim.get_node("Content/PowerStepper") as Control,
		], "compact groups at %s" % viewport_size)
		_assert_true(queue.size.y >= queue.get_combined_minimum_size().y, "compact queue must honor its minimum height at %s" % viewport_size)
	var angle_decrease := aim.get_node("Content/AngleStepper/Decrease") as Button
	var elevation := aim.get_node("Content/AngleStepper/Value") as Label
	var angle_increase := aim.get_node("Content/AngleStepper/Increase") as Button
	var power_decrease := aim.get_node("Content/PowerStepper/Decrease") as Button
	var power := aim.get_node("Content/PowerStepper/Value") as Label
	var power_increase := aim.get_node("Content/PowerStepper/Increase") as Button
	_assert_true(
		angle_decrease.get_global_rect().end.x <= elevation.get_global_rect().position.x
				and elevation.get_global_rect().end.x <= angle_increase.get_global_rect().position.x,
		"angle row must order decrement, value, increment at %s" % viewport_size
	)
	_assert_true(
		power_decrease.get_global_rect().end.x <= power.get_global_rect().position.x
				and power.get_global_rect().end.x <= power_increase.get_global_rect().position.x,
		"power row must order decrement, value, increment at %s" % viewport_size
	)
	_assert_true(
		angle_decrease.size.y >= 40.0 and power_increase.size.y >= 40.0,
		"Aim steppers must keep 40px keyboard targets at %s" % viewport_size
	)
	angle_decrease.grab_focus()
	await process_frame
	_assert_true(angle_decrease.has_focus(), "Aim decrement must remain keyboard focusable at %s" % viewport_size)
	_assert_true(
		not fire.get_global_rect().intersects((aim.get_node("Content/AngleStepper") as Control).get_global_rect())
				and not fire.get_global_rect().intersects((aim.get_node("Content/PowerStepper") as Control).get_global_rect()),
		"Fire must occupy the Cannon Focus gap between angle and power at %s" % viewport_size
	)

	if legend.visible:
		var items := legend.get_node("Center/Items") as HFlowContainer
		_assert_true(items.clip_contents == false and legend.clip_contents, "legend must wrap within its bounded root")
		_assert_inside(items, legend.get_global_rect(), "legend contents at %s (%s)" % [viewport_size, locale])
		for path in ["AngleItem", "PowerItem", "FireItem", "MenuItem"]:
			_assert_true(
				(legend.get_node("Center/Items/%s" % path) as Control).is_visible_in_tree(),
				"primary legend cue %s must survive at %s (%s)" % [path, viewport_size, locale]
			)

	_assert_true(
		queue.size.y >= queue.get_combined_minimum_size().y,
		"ball queue must honor its component minimum height at %s" % viewport_size
	)
	_assert_true(
		score_scale.size.x >= score_scale.get_combined_minimum_size().x
				and score_scale.size.y >= score_scale.get_combined_minimum_size().y,
		"score scale must honor its component minimum geometry at %s" % viewport_size
	)
	hud.queue_free()
	await process_frame


func _assert_inside(control: Control, bounds: Rect2, label: String) -> void:
	_assert_true(bounds.encloses(control.get_global_rect()), "%s must stay in the safe area: %s" % [label, control.get_global_rect()])


func _assert_pairwise_non_overlap(controls: Array[Control], label: String) -> void:
	for first_index in controls.size():
		for second_index in range(first_index + 1, controls.size()):
			var first := controls[first_index]
			var second := controls[second_index]
			if not first.is_visible_in_tree() or not second.is_visible_in_tree():
				continue
			_assert_true(
				not first.get_global_rect().intersects(second.get_global_rect()),
				"%s must not overlap: %s and %s" % [label, first.name, second.name]
			)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("HUD responsive layout test failed: %s" % message)
