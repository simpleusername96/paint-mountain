extends SceneTree

const SCORE_SCALE_SCENE := preload("res://scenes/ui/components/score_scale.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scale := SCORE_SCALE_SCENE.instantiate() as ScoreScale
	root.add_child(scale)
	scale.show()
	await process_frame

	var band := TargetBandData.new()
	band.target_min = 30.0
	band.target_max = 45.0
	var rule := ColorScoreRuleData.new()
	rule.red_weight = -1
	rule.green_weight = 1
	scale.set_preset(ScoreScale.Preset.VERTICAL_LIVE)
	scale.size = Vector2(132.0, 410.0)
	scale.configure_target_band(band, rule)
	scale.update_target_band(PaintCoverageSnapshot.new(12.0, 18.0, 30.0), 36.0, -1, 1)
	await process_frame
	_assert(scale.target_range().is_equal_approx(Vector2(30.0, 45.0)), "target-band range must remain authoritative")
	_assert(_encloses(scale.track_rect_for_test(), scale.target_rect_for_test()), "vertical target band must stay inside the full track")
	_assert(_point_inside(scale.track_rect_for_test(), scale.marker_position_for_test()), "vertical marker must stay inside the full track")
	_assert((scale.get_node("Contributions") as Control).visible, "target-band presentation must expose Red and Green contributions")
	_assert((scale.get_node("Contributions/Red") as Label).text == "R − 12.0", "Red contribution must include its score role")
	_assert((scale.get_node("Contributions/Green") as Label).text == "G + 18.0", "Green contribution must include its score role")
	_assert(scale.track_rect_for_test().size.y >= 300.0, "standard vertical rail must use the available height")
	_assert(not (scale.get_node("MetricIcon") as TextureRect).visible, "vertical rail must omit the redundant metric icon")

	scale.set_value(-10.0)
	_assert(is_equal_approx(scale.value(), 0.0), "score values below zero must clamp to zero")
	var zero := scale.marker_position_for_test()
	scale.set_value(110.0)
	_assert(is_equal_approx(scale.value(), 100.0), "score values above 100 must clamp to 100")
	var hundred := scale.marker_position_for_test()
	_assert(hundred.y < zero.y, "vertical scale must map 100 above 0")

	scale.set_preset(ScoreScale.Preset.HORIZONTAL_SUMMARY)
	scale.size = Vector2(440.0, 118.0)
	scale.configure_coverage(62.0)
	scale.update_coverage(75.0)
	await process_frame
	_assert(scale.target_range().is_equal_approx(Vector2(62.0, 100.0)), "coverage threshold must extend from target to 100")
	_assert(_encloses(scale.track_rect_for_test(), scale.target_rect_for_test()), "horizontal target region must stay inside the full track")
	_assert((scale.get_node("MetricIcon") as TextureRect).visible, "horizontal summary may retain the compact metric icon")
	scale.set_value(0.0)
	zero = scale.marker_position_for_test()
	scale.set_value(100.0)
	hundred = scale.marker_position_for_test()
	_assert(hundred.x > zero.x, "horizontal scale must map 100 right of 0")
	for tick in ["Tick0", "Tick25", "Tick50", "Tick75", "Tick100"]:
		var label := scale.get_node(tick) as Label
		_assert(label.visible and label.text == tick.trim_prefix("Tick"), "%s must stay visible and exact" % tick)

	scale.queue_free()
	await process_frame
	if not _failed:
		print("score_scale_contract_test passed: fixed 0-100 vertical/horizontal score geometry")
	quit(1 if _failed else 0)


func _encloses(outer: Rect2, inner: Rect2) -> bool:
	return outer.grow(0.01).encloses(inner)


func _point_inside(rect: Rect2, point: Vector2) -> bool:
	return rect.grow(0.01).has_point(point)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Score scale contract failed: %s" % message)
