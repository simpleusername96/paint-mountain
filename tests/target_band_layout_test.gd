extends SceneTree

const METER_SCENE := preload("res://scenes/ui/hud/target_band_meter.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var meter := METER_SCENE.instantiate() as TargetBandMeter
	meter.size = Vector2(204.0, 128.0)
	root.add_child(meter)
	await process_frame
	var band := TargetBandData.new()
	band.target_min = 7.0
	band.target_max = 11.0
	meter.configure(band, ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.BOTH_ADD))
	await process_frame
	await process_frame
	var track := meter.get_node("%BandTrack") as ColorRect
	var target := meter.get_node("%Band") as ColorRect
	var marker := meter.get_node("%Marker") as ColorRect
	var failed := false
	if not is_equal_approx(target.size.x, track.size.x * 0.5):
		push_error("Target band must occupy the authored middle half of its rail.")
		failed = true
	if not is_equal_approx(marker.position.x + marker.size.x * 0.5, track.position.x):
		push_error("Zero score marker must clamp to the left end of the displayed range.")
		failed = true
	meter.queue_free()
	await process_frame
	if not failed:
		print("Target-band layout passed: fixed band and current marker survive container layout.")
	quit(1 if failed else 0)
