extends SceneTree

const METER_SCENE := preload("res://scenes/ui/components/score_scale.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var meter := METER_SCENE.instantiate() as ScoreScale
	meter.size = Vector2(132.0, 410.0)
	root.add_child(meter)
	await process_frame
	var band := TargetBandData.new()
	band.target_min = 7.0
	band.target_max = 11.0
	meter.configure_target_band(band, ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.BOTH_ADD))
	await process_frame
	await process_frame
	var track := meter.track_rect_for_test()
	var target := meter.target_rect_for_test()
	var marker := meter.marker_position_for_test()
	var failed := false
	if not track.grow(0.01).encloses(target):
		push_error("Target band must remain inside the complete 0-100 rail.")
		failed = true
	if not is_equal_approx(marker.y, track.end.y):
		push_error("Zero score marker must map to the bottom endpoint of the vertical range.")
		failed = true
	meter.queue_free()
	await process_frame
	if not failed:
		print("Target-band layout passed: complete scale, target band, and marker survive container layout.")
	quit(1 if failed else 0)
