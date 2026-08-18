extends SceneTree

const BAND_SCENE := preload("res://scenes/ui/hud/target_band_meter.tscn")
const QUEUE_SCENE := preload("res://scenes/ui/hud/queue_rail.tscn")

var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var meter = BAND_SCENE.instantiate()
	root.add_child(meter)
	var band := TargetBandData.new()
	band.target_min = 7.0
	band.target_max = 11.0
	meter.configure(band, ColorScoreRuleData.from_pattern(ColorScoreRuleData.Pattern.GREEN_ADD_RED_SUBTRACT))
	meter.update_score(PaintCoverageSnapshot.new(3.0, 4.0, 7.0, 9), 1.0)
	_assert("R −" in meter.get_node("%Red").text and "G +" in meter.get_node("%Green").text, "meter must disclose signed channel roles")
	var rail = QUEUE_SCENE.instantiate()
	root.add_child(rail)
	var tokens: Array[BallToken] = [BallToken.new(BallKind.Value.IMPACT_BURST, PaintChannel.Value.RED)]
	rail.configure(tokens)
	_assert(rail.get_node("NowToken").visible, "current token must show")
	_assert(not rail.get_node("NextOne").visible and not rail.get_node("NextTwo").visible, "empty tail slots must be omitted")
	_assert(rail.get_node("NowToken/TokenLabel").text.contains("R"), "token must contain a non-color channel letter")
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
