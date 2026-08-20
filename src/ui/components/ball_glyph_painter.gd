class_name BallGlyphPainter
extends RefCounted

## Shared vector glyphs keep ball kinds readable without platform font symbols.


static func draw(
		canvas: CanvasItem,
		center: Vector2,
		radius: float,
		kind: int,
		fill: Color,
		outline: Color,
		line_width: float = 2.0
) -> void:
	match kind:
		BallKind.Value.IMPACT_BURST:
			for spoke in range(8):
				var direction := Vector2.from_angle(float(spoke) * TAU / 8.0)
				canvas.draw_line(
					center + direction * radius * 0.5,
					center + direction * radius * 1.35,
					outline,
					line_width
				)
			canvas.draw_circle(center, radius * 0.72, outline)
			canvas.draw_circle(center, radius * 0.54, fill)
		BallKind.Value.APEX_SPLIT:
			for angle in [-PI * 0.5, PI / 6.0, PI * 5.0 / 6.0]:
				var lobe_center := center + Vector2.from_angle(angle) * radius * 0.62
				canvas.draw_circle(lobe_center, radius * 0.55, outline)
				canvas.draw_circle(lobe_center, radius * 0.40, fill)
		_:
			canvas.draw_circle(center, radius, outline)
			canvas.draw_circle(center, radius * 0.76, fill)
