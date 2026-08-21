extends SceneTree

const BAND_SCENE := preload("res://scenes/ui/components/aim_score_status.tscn")
const QUEUE_SCENE := preload("res://scenes/ui/components/ball_queue.tscn")

var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var meter = BAND_SCENE.instantiate()
	root.add_child(meter)
	var rail = QUEUE_SCENE.instantiate()
	root.add_child(rail)
	await process_frame
	var band := TargetBandData.new()
	band.target_min = 7.0
	band.target_max = 11.0
	meter.configure_target_band(band, ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.GREEN_ADD_RED_SUBTRACT))
	meter.update_target_band(PaintCoverageSnapshot.new(3.0, 4.0, 7.0, 9), 1.0, -1, 1)
	_assert(meter.color_role_weights_for_test() == Vector2i(-1, 1)
			and "R −1" in meter.accessibility_name and "G +1" in meter.accessibility_name,
		"meter must disclose signed channel roles with visual and accessible marks")
	meter.update_target_band(PaintCoverageSnapshot.new(4.0, 1.0, 5.0, 10), -3.0, -1, 1)
	_assert("-3" in meter.accessibility_name, "meter must preserve the authoritative negative score")
	_assert(meter.overflow_direction_for_test() == -1
			and is_equal_approx(meter.marker_normalized_for_test(), 0.0),
		"negative score must use an explicit underflow shape on the success-range endpoint")
	var tokens: Array[BallToken] = [BallToken.new(BallKind.Value.IMPACT_BURST, PaintChannel.Value.RED)]
	rail.configure(tokens)
	var views: Array[BallQueueTokenView] = rail.token_views()
	_assert(views[0].visible, "current token must show")
	_assert(not views[1].visible and not views[2].visible, "empty tail slots must be omitted")
	_assert(views[0].channel_label() == "R", "token must draw a non-color channel letter")
	meter.free()
	rail.free()
	if not _failed:
		print("Target-band HUD truth passed: signed score roles and quiet queue horizon.")
	quit(1 if _failed else 0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Target-band HUD test failed: %s" % message)
