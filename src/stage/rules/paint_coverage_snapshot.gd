class_name PaintCoverageSnapshot
extends RefCounted

var red_percent: float
var green_percent: float
var total_percent: float
var checksum: int


func _init(red: float = 0.0, green: float = 0.0, total: float = 0.0, paint_checksum: int = 0) -> void:
	red_percent = red
	green_percent = green
	total_percent = total
	checksum = paint_checksum


func is_valid() -> bool:
	return red_percent >= 0.0 and green_percent >= 0.0 and total_percent >= 0.0 \
		and total_percent <= 100.0 and is_equal_approx(total_percent, red_percent + green_percent)
