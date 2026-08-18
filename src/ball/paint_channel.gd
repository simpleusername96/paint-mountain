class_name PaintChannel
extends RefCounted

enum Value {
	RED,
	GREEN,
}

const RED_COLOR := Color("D84C4C")
const GREEN_COLOR := Color("38A86B")


static func is_valid(value: int) -> bool:
	return value == Value.RED or value == Value.GREEN


static func stable_id(value: int) -> StringName:
	return &"red" if value == Value.RED else &"green" if value == Value.GREEN else &""


static func short_label(value: int) -> String:
	return "R" if value == Value.RED else "G" if value == Value.GREEN else "?"


static func visual_color(value: int) -> Color:
	return RED_COLOR if value == Value.RED else GREEN_COLOR if value == Value.GREEN else Color.WHITE
