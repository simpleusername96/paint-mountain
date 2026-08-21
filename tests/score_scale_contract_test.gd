extends SceneTree

const AIM_SCORE_SCENE := preload("res://scenes/ui/components/aim_score_status.tscn")
const RESULT_SCALE_SCENE := preload("res://scenes/ui/components/score_scale.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var status := AIM_SCORE_SCENE.instantiate() as AimScoreStatus
	root.add_child(status)
	status.size = Vector2(520.0, 176.0)
	var band := TargetBandData.new()
	band.target_min = 30.0
	band.target_max = 45.0
	var rule := ColorScoreRuleData.new()
	rule.red_weight = -1
	rule.green_weight = 1
	status.configure_target_band(band, rule)
	status.update_target_band(PaintCoverageSnapshot.new(12.0, 18.0, 30.0), 36.0, -1, 1)
	await process_frame
	_assert(status.target_range().is_equal_approx(Vector2(30.0, 45.0)),
			"Aim range must use only the authoritative success domain")
	_assert(is_equal_approx(status.marker_normalized_for_test(), 0.4),
			"in-range score must map within the success domain")
	_assert(status.overflow_direction_for_test() == 0,
			"in-range score must not expose an overflow arrow")
	_assert(is_equal_approx(status.paint_percent_for_test(), 30.0),
			"total painted area must remain an independent numeric value")
	_assert(status.color_role_weights_for_test() == Vector2i(-1, 1),
			"red and green score roles must remain authoritative")
	var layout := status.layout_rects_for_test()
	_assert(not (layout.paint_icon as Rect2).intersects(layout.red_icon as Rect2),
			"paint total and color-role rows must keep a distinct vertical rhythm")
	_assert(is_equal_approx((layout.red_icon as Rect2).get_center().y,
			(layout.green_icon as Rect2).get_center().y),
			"red and green role icons must share one row center")
	_assert("R −1 12.0" in status.accessibility_name
			and "G +1 18.0" in status.accessibility_name,
			"icon-led color roles must retain an exact accessible alternative")
	status.update_target_band(PaintCoverageSnapshot.new(), -3.0, -1, 1)
	_assert(status.overflow_direction_for_test() == -1
			and is_equal_approx(status.marker_normalized_for_test(), 0.0),
			"below-range score must stay signed and clamp only its marker")
	status.update_target_band(PaintCoverageSnapshot.new(), 48.0, -1, 1)
	_assert(status.overflow_direction_for_test() == 1
			and is_equal_approx(status.marker_normalized_for_test(), 1.0),
			"above-range score must stay signed and clamp only its marker")
	status.set_presentation(AimScoreStatus.Presentation.COMPACT_VALUE)
	_assert(status.custom_minimum_size == Vector2(210.0, 136.0),
			"Map and Follow must use the compact numeric instrument")

	var summary := RESULT_SCALE_SCENE.instantiate() as ScoreScale
	root.add_child(summary)
	summary.set_preset(ScoreScale.Preset.HORIZONTAL_SUMMARY)
	summary.size = Vector2(440.0, 118.0)
	summary.configure_coverage(62.0)
	summary.update_coverage(75.0)
	await process_frame
	_assert(summary.target_range().is_equal_approx(Vector2(62.0, 100.0)),
			"Result summary must retain the full horizontal 0–100 result domain")
	_assert((summary.get_node("MetricIcon") as TextureRect).visible,
			"Result summary may retain its compact metric icon")

	status.queue_free()
	summary.queue_free()
	await process_frame
	if not _failed:
		print("score_scale_contract_test passed: Aim success range and compact values are distinct from Result summary")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Score presentation contract failed: %s" % message)
