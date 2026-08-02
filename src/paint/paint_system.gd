class_name PaintSystem
extends Node

signal coverage_changed(coverage_percent: float)
signal paint_deposited(kind: StringName, world_position: Vector3, radius: float)
signal flow_settled

const MASK_SIZE := 512
const PAINTED_THRESHOLD := 0.18
const COVERAGE_PUBLISH_INTERVAL := 0.18

var _stage_index: int = 0
var _world_bounds := Rect2(Vector2(-90.0, -172.0), Vector2(180.0, 120.0))
var _terrain_origin_y: float = -2.0
var _paint_image: Image
var _eligible_image: Image
var _recent_image: Image
var _excluded_image: Image
var _paint_bytes: PackedByteArray
var _eligible_bytes: PackedByteArray
var _recent_bytes: PackedByteArray
var _paint_texture: ImageTexture
var _eligible_texture: ImageTexture
var _recent_texture: ImageTexture
var _excluded_texture: ImageTexture
var _terrain_material: ShaderMaterial
var _pending_stamps: Array[Dictionary] = []
var _painted_eligible_pixels: int = 0
var _total_eligible_pixels: int = 0
var _dirty: bool = false
var _coverage_publish_elapsed: float = 0.0
var flow_simulation_enabled: bool = true


func configure(
		stage_index: int,
		world_bounds: Rect2,
		terrain_origin_y: float,
		terrain_material: ShaderMaterial,
		paint_color: Color = Color(0.03, 0.38, 1.0, 1.0)
) -> void:
	_stage_index = stage_index
	_world_bounds = world_bounds
	_terrain_origin_y = terrain_origin_y
	_terrain_material = terrain_material
	_create_masks()
	if _terrain_material != null:
		_terrain_material.set_shader_parameter(&"paint_mask", _paint_texture)
		_terrain_material.set_shader_parameter(&"paint_color", paint_color)


func _process(delta: float) -> void:
	if not _pending_stamps.is_empty():
		flush_pending()
	_coverage_publish_elapsed += delta
	if _coverage_publish_elapsed >= COVERAGE_PUBLISH_INTERVAL:
		_coverage_publish_elapsed = 0.0
		coverage_changed.emit(coverage_percent())


func queue_stamp(
		kind: StringName,
		world_position: Vector3,
		radius: float,
		amount: float,
		allow_flow: bool = false
) -> void:
	_pending_stamps.append({
		"kind": kind,
		"position": world_position,
		"radius": maxf(radius, 0.05),
		"amount": maxf(amount, 0.0),
		"flow": allow_flow,
	})


func flush_pending() -> void:
	if _paint_image == null:
		return
	var stamps := _pending_stamps
	_pending_stamps = []
	_recent_bytes.fill(0)
	for stamp in stamps:
		if not _is_near_terrain(stamp.position):
			continue
		_apply_circle(stamp.position, stamp.radius, stamp.amount)
		_apply_recent_circle(stamp.position, stamp.radius)
		paint_deposited.emit(stamp.kind, stamp.position, stamp.radius)
		if stamp.flow and flow_simulation_enabled:
			var flow_steps := 28 if stamp.kind == &"burst" else (18 if stamp.kind == &"impact" else 10)
			_apply_downhill_flow(stamp.position, stamp.radius * 0.42, stamp.amount * 0.36, flow_steps)
	if _dirty:
		_paint_image.set_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _paint_bytes)
		_paint_texture.update(_paint_image)
		_dirty = false
		coverage_changed.emit(coverage_percent())
	_recent_image.set_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _recent_bytes)
	_recent_texture.update(_recent_image)
	flow_settled.emit()


func clear() -> void:
	_pending_stamps.clear()
	_paint_bytes.fill(0)
	_recent_bytes.fill(0)
	_paint_image.set_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _paint_bytes)
	_recent_image.set_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _recent_bytes)
	_painted_eligible_pixels = 0
	_dirty = false
	_paint_texture.update(_paint_image)
	_recent_texture.update(_recent_image)
	coverage_changed.emit(0.0)
	flow_settled.emit()


func coverage_percent() -> float:
	if _total_eligible_pixels <= 0:
		return 0.0
	return 100.0 * float(_painted_eligible_pixels) / float(_total_eligible_pixels)


func paint_texture() -> ImageTexture:
	return _paint_texture


func eligible_texture() -> ImageTexture:
	return _eligible_texture


func recent_texture() -> ImageTexture:
	return _recent_texture


func excluded_texture() -> ImageTexture:
	return _excluded_texture


func pending_work_count() -> int:
	return _pending_stamps.size()


func total_eligible_pixels() -> int:
	return _total_eligible_pixels


func _create_masks() -> void:
	_paint_bytes = PackedByteArray()
	_paint_bytes.resize(MASK_SIZE * MASK_SIZE)
	_paint_bytes.fill(0)
	_recent_bytes = _paint_bytes.duplicate()
	_paint_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _paint_bytes)
	_recent_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _recent_bytes)

	# The terrain owns the full X/Z rectangle; a narrow inset excludes stage bounds.
	const INSET := 14
	_eligible_bytes = PackedByteArray()
	_eligible_bytes.resize(MASK_SIZE * MASK_SIZE)
	_eligible_bytes.fill(0)
	_total_eligible_pixels = 0
	for y in range(MASK_SIZE):
		if y < INSET or y >= MASK_SIZE - INSET:
			continue
		var row_start := y * MASK_SIZE
		var normalized_y := (float(y) / float(MASK_SIZE - 1) - 0.5) * 2.0
		for x in range(INSET, MASK_SIZE - INSET):
			var normalized_x := (float(x) / float(MASK_SIZE - 1) - 0.5) * 2.0
			var eligible := false
			match _stage_index:
				2:
					var in_channel := absf(normalized_x + 0.267) <= 0.025 \
							or absf(normalized_x - 0.033) <= 0.025 \
							or absf(normalized_x - 0.289) <= 0.025
					eligible = in_channel and normalized_y >= -0.78 and normalized_y <= 0.72
				1:
					eligible = pow(normalized_x / 0.82, 2.0) + pow(normalized_y / 0.9, 2.0) <= 1.0
				_:
					eligible = pow(normalized_x / 0.86, 2.0) + pow(normalized_y / 0.92, 2.0) <= 1.0
			if eligible:
				_eligible_bytes[row_start + x] = 255
				_total_eligible_pixels += 1
	_eligible_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _eligible_bytes)
	var excluded_bytes := PackedByteArray()
	excluded_bytes.resize(MASK_SIZE * MASK_SIZE)
	for index in range(_eligible_bytes.size()):
		excluded_bytes[index] = 0 if _eligible_bytes[index] >= 128 else 255
	_excluded_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, excluded_bytes)
	_paint_texture = ImageTexture.create_from_image(_paint_image)
	_eligible_texture = ImageTexture.create_from_image(_eligible_image)
	_recent_texture = ImageTexture.create_from_image(_recent_image)
	_excluded_texture = ImageTexture.create_from_image(_excluded_image)
	_painted_eligible_pixels = 0


func _apply_circle(world_position: Vector3, world_radius: float, amount: float) -> void:
	var center := _world_to_pixel(Vector2(world_position.x, world_position.z))
	var radius_x := maxf(1.0, world_radius / _world_bounds.size.x * float(MASK_SIZE))
	var radius_y := maxf(1.0, world_radius / _world_bounds.size.y * float(MASK_SIZE))
	var minimum_x := maxi(0, floori(center.x - radius_x))
	var maximum_x := mini(MASK_SIZE - 1, ceili(center.x + radius_x))
	var minimum_y := maxi(0, floori(center.y - radius_y))
	var maximum_y := mini(MASK_SIZE - 1, ceili(center.y + radius_y))
	var normalized_amount := clampf(amount / 22.0, PAINTED_THRESHOLD + 0.08, 1.0)
	for pixel_y in range(minimum_y, maximum_y + 1):
		for pixel_x in range(minimum_x, maximum_x + 1):
			var dx := (float(pixel_x) + 0.5 - center.x) / radius_x
			var dy := (float(pixel_y) + 0.5 - center.y) / radius_y
			var squared_distance := dx * dx + dy * dy
			if squared_distance > 1.0:
				continue
			var pixel_index := pixel_y * MASK_SIZE + pixel_x
			var existing := float(_paint_bytes[pixel_index]) / 255.0
			var deposited := normalized_amount * (1.0 - squared_distance * 0.7)
			var updated := maxf(existing, deposited)
			var is_eligible := _eligible_bytes[pixel_index] >= 128
			if is_eligible and existing < PAINTED_THRESHOLD and updated >= PAINTED_THRESHOLD:
				_painted_eligible_pixels += 1
			if updated > existing + 0.001:
				_paint_bytes[pixel_index] = roundi(updated * 255.0)
				_dirty = true


func _apply_recent_circle(world_position: Vector3, world_radius: float) -> void:
	var center := _world_to_pixel(Vector2(world_position.x, world_position.z))
	var radius_x := maxf(1.0, world_radius / _world_bounds.size.x * float(MASK_SIZE))
	var radius_y := maxf(1.0, world_radius / _world_bounds.size.y * float(MASK_SIZE))
	var minimum_x := maxi(0, floori(center.x - radius_x))
	var maximum_x := mini(MASK_SIZE - 1, ceili(center.x + radius_x))
	var minimum_y := maxi(0, floori(center.y - radius_y))
	var maximum_y := mini(MASK_SIZE - 1, ceili(center.y + radius_y))
	for pixel_y in range(minimum_y, maximum_y + 1):
		for pixel_x in range(minimum_x, maximum_x + 1):
			var dx := (float(pixel_x) + 0.5 - center.x) / radius_x
			var dy := (float(pixel_y) + 0.5 - center.y) / radius_y
			if dx * dx + dy * dy <= 1.0:
				_recent_bytes[pixel_y * MASK_SIZE + pixel_x] = 255


func _apply_downhill_flow(world_position: Vector3, radius: float, amount: float, maximum_steps: int) -> void:
	var current := Vector2(world_position.x, world_position.z)
	var flow_amount := amount
	var step_world := maxf(radius * 0.85, 0.55)
	var neighbor_offsets: Array[Vector2] = [
		Vector2(0.0, -1.0), Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0),
		Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0),
	]
	for _step in range(maximum_steps):
		var local_current := _world_to_local(current)
		var current_height := TerrainMeshFactory.height_at(_stage_index, local_current.x, local_current.y)
		var best := current
		var best_height := current_height
		for offset: Vector2 in neighbor_offsets:
			var candidate: Vector2 = current + offset.normalized() * step_world
			if not _world_bounds.has_point(candidate):
				continue
			var local_candidate := _world_to_local(candidate)
			var candidate_height := TerrainMeshFactory.height_at(_stage_index, local_candidate.x, local_candidate.y)
			if candidate_height < best_height - 0.02:
				best = candidate
				best_height = candidate_height
		if best == current:
			break
		current = best
		flow_amount *= 0.9
		if flow_amount < 0.45:
			break
		var flow_world_position := Vector3(current.x, _terrain_origin_y + best_height, current.y)
		_apply_circle(flow_world_position, maxf(radius, 0.65), flow_amount)


func _is_near_terrain(world_position: Vector3) -> bool:
	var xz := Vector2(world_position.x, world_position.z)
	if not _world_bounds.has_point(xz):
		return false
	var local := _world_to_local(xz)
	var surface_y := _terrain_origin_y + TerrainMeshFactory.height_at(_stage_index, local.x, local.y)
	return absf(world_position.y - surface_y) <= 4.5


func _world_to_pixel(world_xz: Vector2) -> Vector2:
	var normalized := (world_xz - _world_bounds.position) / _world_bounds.size
	return Vector2(normalized.x, normalized.y) * float(MASK_SIZE - 1)


func _world_to_local(world_xz: Vector2) -> Vector2:
	return world_xz - (_world_bounds.position + _world_bounds.size * 0.5)
