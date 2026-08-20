class_name WorldGradientScrim
extends Control

## Shared edge readability gradient. The canonical Theme owns its tint.

enum Direction {
	LEFT_TO_RIGHT,
	TOP_TO_BOTTOM,
}

@export var direction := Direction.LEFT_TO_RIGHT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var tint := get_theme_color(&"tint", &"WorldGradientScrim")
	var transparent := tint
	transparent.a = 0.0
	var points := PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y),
	])
	var colors := PackedColorArray()
	if direction == Direction.LEFT_TO_RIGHT:
		colors = PackedColorArray([transparent, tint, tint, transparent])
	else:
		colors = PackedColorArray([transparent, transparent, tint, tint])
	draw_polygon(points, colors)
