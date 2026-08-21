extends SceneTree

const METER_SCENE := preload("res://scenes/ui/components/aim_score_status.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var meter := METER_SCENE.instantiate() as AimScoreStatus
	meter.size = Vector2(600.0, 164.0)
	root.add_child(meter)
	await process_frame
	var band := TargetBandData.new()
	band.target_min = 7.0
	band.target_max = 11.0
	meter.configure_target_band(band, ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.BOTH_ADD))
	await process_frame
	await process_frame
	var failed := false
	if not meter.target_range().is_equal_approx(Vector2(7.0, 11.0)):
		push_error("Aim must use exactly the success range, not a complete 0-100 rail.")
		failed = true
	if meter.overflow_direction_for_test() != -1 \
			or not is_equal_approx(meter.marker_normalized_for_test(), 0.0):
		push_error("A below-range score must map to the left success-range endpoint.")
		failed = true
	meter.queue_free()
	await process_frame
	if not failed:
		print("Target-band layout passed: exact success range and signed endpoint survive layout.")
	quit(1 if failed else 0)
