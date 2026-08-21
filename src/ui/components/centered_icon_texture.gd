class_name CenteredIconTexture
extends RefCounted

## Presents approved icon pixels from a symmetric square region so transparent
## source padding cannot shift or shrink the visible mark inside a control.

const CONTENT_FRACTION := 0.82

static var _cache: Dictionary = {}


static func from_source(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	var key := source.get_instance_id()
	if _cache.has(key):
		return _cache[key] as Texture2D
	var image := source.get_image()
	if image == null or image.is_empty():
		_cache[key] = source
		return source
	var used := image.get_used_rect()
	if not used.has_area():
		_cache[key] = source
		return source
	var source_size := Vector2i(image.get_width(), image.get_height())
	var region_edge := mini(
		ceili(float(maxi(used.size.x, used.size.y)) / CONTENT_FRACTION),
		mini(source_size.x, source_size.y)
	)
	var used_center := Vector2(used.position) + Vector2(used.size) * 0.5
	var region_position := Vector2i(
		clampi(roundi(used_center.x - float(region_edge) * 0.5), 0, source_size.x - region_edge),
		clampi(roundi(used_center.y - float(region_edge) * 0.5), 0, source_size.y - region_edge)
	)
	var centered := AtlasTexture.new()
	centered.atlas = source
	centered.region = Rect2(Vector2(region_position), Vector2(region_edge, region_edge))
	centered.filter_clip = true
	_cache[key] = centered
	return centered


static func visible_center_error(source: Texture2D) -> Vector2:
	if source == null:
		return Vector2(INF, INF)
	var image := source.get_image()
	if image == null or image.is_empty():
		return Vector2(INF, INF)
	var used := image.get_used_rect()
	var centered := from_source(source) as AtlasTexture
	if not used.has_area() or centered == null:
		return Vector2(INF, INF)
	var used_center := Vector2(used.position) + Vector2(used.size) * 0.5
	return (used_center - centered.region.get_center()).abs()
