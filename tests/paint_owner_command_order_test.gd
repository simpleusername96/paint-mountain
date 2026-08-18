extends SceneTree

var _failed := false


func _initialize() -> void:
	var red := RadialPaintMark.new(12, 3, 0, 0, Vector3.ZERO, Vector3.UP, 1.0, RID(), &"top", &"surface", 0, RadialPaintMark.Kind.IMPACT, 4, PaintChannel.Value.RED)
	var green := RadialPaintMark.new(12, 3, 0, 1, Vector3.ZERO, Vector3.UP, 1.0, RID(), &"top", &"surface", 0, RadialPaintMark.Kind.IMPACT, 4, PaintChannel.Value.GREEN)
	var commands: Array = [green, red]
	commands.sort_custom(func(a, b): return _less(a, b))
	_assert(commands[0].channel == PaintChannel.Value.RED and commands[1].channel == PaintChannel.Value.GREEN, "channel must not replace canonical tick/spawn/sequence ordering")
	_assert(red.with_sequence(7).channel == PaintChannel.Value.RED, "sequence assignment must preserve Red")
	_assert(green.with_sequence(7).channel == PaintChannel.Value.GREEN, "sequence assignment must preserve Green")
	if not _failed:
		print("Paint owner command order passed: canonical order retains channel identity.")
	quit(1 if _failed else 0)


func _less(a, b) -> bool:
	var left: PackedInt64Array = a.drain_sort_key()
	var right: PackedInt64Array = b.drain_sort_key()
	for index in range(left.size()):
		if left[index] != right[index]:
			return left[index] < right[index]
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Paint owner command order failed: %s" % message)
