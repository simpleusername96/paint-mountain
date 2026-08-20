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
	var queue := hud_root.get_node("QueueRail") as QueueRail
	var target_band := hud_root.get_node("TargetBandMeter") as TargetBandMeter
	queue.show()
	target_band.show()
	await process_frame
	var safe_rect := Rect2(Vector2(SAFE_MARGIN, SAFE_MARGIN), Vector2(viewport_size) - Vector2(SAFE_MARGIN * 2.0, SAFE_MARGIN * 2.0))
	for path in [
		"TopStatusBar/StageValue",
		"TopStatusBar/SettingsButton",
		"RunStatusCard",
		"QueueRail",
		"ActionButtons",
		"TargetBandMeter",
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
	if viewport_size.x >= 900 and viewport_size.y >= 500:
		_assert_inside(aim, safe_rect, "AimControls at %s (%s)" % [viewport_size, locale])
		_assert_true(
			aim.get_global_rect().encloses((aim.get_node("Backdrop") as Control).get_global_rect()),
			"AimControls must contain its backdrop at %s" % viewport_size
		)
		_assert_true(
			aim.get_global_rect().encloses((aim.get_node("Content") as Control).get_global_rect()),
			"AimControls must contain its content at %s" % viewport_size
		)
		_assert_inside(legend, safe_rect, "ContextLegend at %s (%s)" % [viewport_size, locale])
	else:
		_assert_true(not aim.visible and not legend.visible, "compact layout must prioritize status and Fire at %s" % viewport_size)
		_assert_pairwise_non_overlap([
			hud_root.get_node("TargetBandMeter") as Control,
			queue,
			actions,
		], "compact groups at %s" % viewport_size)
		_assert_true(queue.size.y >= queue.get_combined_minimum_size().y, "compact queue must honor its minimum height at %s" % viewport_size)
		hud.queue_free()
		await process_frame
		return
	var angle_decrease := aim.get_node("Content/AngleDecrease") as Button
	var elevation := aim.get_node("Content/ElevationValue") as Label
	var angle_increase := aim.get_node("Content/AngleIncrease") as Button
	var power_decrease := aim.get_node("Content/PowerDecrease") as Button
	var power := aim.get_node("Content/PowerValue") as Label
	var power_increase := aim.get_node("Content/PowerIncrease") as Button
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
	if viewport_size.x >= 1024:
		_assert_true(
			not actions.get_global_rect().intersects(aim.get_global_rect()),
			"ActionButtons and AimControls must not overlap at %s" % viewport_size
		)

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
		"queue rail must honor its component minimum height at %s" % viewport_size
	)
	_assert_true(
		target_band.size.x >= target_band.get_combined_minimum_size().x
				and target_band.size.y >= target_band.get_combined_minimum_size().y,
		"target band must honor its component minimum geometry at %s" % viewport_size
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
