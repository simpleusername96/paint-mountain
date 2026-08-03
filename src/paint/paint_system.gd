class_name PaintSystem
extends Node

signal coverage_changed(coverage_percent: float)
signal deposit_applied(
	request: PaintDepositRequest,
	accepted_amount: float,
	written_pixel_count: int,
	newly_painted_pixel_count: int
)
signal deposit_rejected(request: PaintDepositRequest)
signal flow_settled

const MASK_SIZE := 512
const COVERAGE_PUBLISH_INTERVAL := 0.20
const NORMAL_FACING_THRESHOLD := 0.2588190451 # cos(75 degrees)
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

var _generated_layout: GeneratedStageLayout
var _world_bounds: Rect2
var _terrain_origin_y: float = 0.0
var _tuning: PaintDepositTuning
var _paint_bytes := PackedByteArray()
var _eligible_bytes := PackedByteArray()
var _recent_bytes := PackedByteArray()
var _paint_image: Image
var _eligible_image: Image
var _recent_image: Image
var _excluded_image: Image
var _paint_texture: ImageTexture
var _eligible_texture: ImageTexture
var _recent_texture: ImageTexture
var _excluded_texture: ImageTexture
var _terrain_material: ShaderMaterial
var _painted_eligible_pixels: int = 0
var _total_eligible_pixels: int = 0
var _dirty: bool = false
var _coverage_publish_elapsed: float = 0.0
var _coverage_changed_since_publish: bool = false
var flow_simulation_enabled: bool = true


func configure(
		world_bounds: Rect2,
		terrain_origin_y: float,
		terrain_material: ShaderMaterial,
		paint_color: Color,
		generated_layout: GeneratedStageLayout,
		deposit_tuning: PaintDepositTuning
) -> void:
	assert(generated_layout != null and generated_layout.is_valid(), "PaintSystem requires the accepted generated layout.")
	assert(deposit_tuning != null, "PaintSystem requires typed deposit tuning.")
	_generated_layout = generated_layout
	_world_bounds = world_bounds
	_terrain_origin_y = terrain_origin_y
	_terrain_material = terrain_material
	_tuning = deposit_tuning
	_create_masks()
	if _terrain_material != null:
		_terrain_material.set_shader_parameter(&"paint_mask", _paint_texture)
		_terrain_material.set_shader_parameter(&"eligible_mask", _eligible_texture)
		_terrain_material.set_shader_parameter(&"paint_color", paint_color)


func _process(delta: float) -> void:
	_coverage_publish_elapsed += delta
	if _coverage_publish_elapsed < COVERAGE_PUBLISH_INTERVAL:
		return
	_coverage_publish_elapsed = 0.0
	if _coverage_changed_since_publish:
		_coverage_changed_since_publish = false
		coverage_changed.emit(coverage_percent())


func apply_deposit(request: PaintDepositRequest) -> Dictionary:
	var rejected := {
		"accepted_amount": 0.0,
		"written_pixel_count": 0,
		"newly_painted_pixel_count": 0,
	}
	if request == null or not request.is_valid() or _paint_image == null:
		if request != null:
			deposit_rejected.emit(request)
		return rejected
	var component := _connected_component(request)
	if component.is_empty():
		deposit_rejected.emit(request)
		return rejected

	_recent_bytes.fill(0)
	var counts := _write_component(request, component)
	if request.allow_flow and flow_simulation_enabled and request.maximum_flow_steps > 0:
		var flow_counts := _apply_steepest_descent_flow(request)
		counts.written += int(flow_counts.written)
		counts.newly_painted += int(flow_counts.newly_painted)
	_upload_dirty_images()
	_coverage_changed_since_publish = _coverage_changed_since_publish or int(counts.newly_painted) > 0
	deposit_applied.emit(request, request.amount, int(counts.written), int(counts.newly_painted))
	flow_settled.emit()
	return {
		"accepted_amount": request.amount,
		"written_pixel_count": int(counts.written),
		"newly_painted_pixel_count": int(counts.newly_painted),
	}


func flush_pending() -> void:
	_upload_dirty_images()
	_coverage_changed_since_publish = false
	coverage_changed.emit(coverage_percent())
	flow_settled.emit()


func clear() -> void:
	if _paint_image == null:
		return
	_paint_bytes.fill(0)
	_recent_bytes.fill(0)
	_painted_eligible_pixels = 0
	_dirty = true
	_upload_dirty_images()
	_coverage_changed_since_publish = false
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
	return 0


func total_eligible_pixels() -> int:
	return _total_eligible_pixels


func painted_eligible_pixels() -> int:
	return _painted_eligible_pixels


func persistent_noneligible_pixel_count() -> int:
	var count := 0
	for index in range(_paint_bytes.size()):
		if _paint_bytes[index] > 0 and _eligible_bytes[index] < 128:
			count += 1
	return count


func paint_bytes_read_only() -> PackedByteArray:
	return _paint_bytes


func generated_layout_read_only() -> GeneratedStageLayout:
	return _generated_layout


func terrain_surface_position(world_xz: Vector2) -> Vector3:
	var local := _world_to_local(world_xz)
	return Vector3(
		world_xz.x,
		_terrain_origin_y + _generated_layout.height_at_local(local.x, local.y),
		world_xz.y
	)


func terrain_surface_normal(world_xz: Vector2) -> Vector3:
	var local := _world_to_local(world_xz)
	return _generated_layout.normal_at_local(local.x, local.y)


func _create_masks() -> void:
	_paint_bytes.resize(MASK_SIZE * MASK_SIZE)
	_paint_bytes.fill(0)
	_recent_bytes = _paint_bytes.duplicate()
	assert(_generated_layout.eligible_mask.size() == MASK_SIZE * MASK_SIZE, "Generated layout must provide the authoritative eligible mask.")
	_eligible_bytes = _generated_layout.eligible_mask.duplicate()
	_total_eligible_pixels = 0
	for byte in _eligible_bytes:
		if byte >= 128:
			_total_eligible_pixels += 1
	_paint_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _paint_bytes)
	_recent_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _recent_bytes)
	_eligible_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _eligible_bytes)
	var excluded_bytes := PackedByteArray()
	excluded_bytes.resize(MASK_SIZE * MASK_SIZE)
	for index in range(_eligible_bytes.size()):
		excluded_bytes[index] = 0 if _eligible_bytes[index] >= 128 else 255
	_excluded_image = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, excluded_bytes)
	_paint_texture = ImageTexture.create_from_image(_paint_image)
	_recent_texture = ImageTexture.create_from_image(_recent_image)
	_eligible_texture = ImageTexture.create_from_image(_eligible_image)
	_excluded_texture = ImageTexture.create_from_image(_excluded_image)
	_painted_eligible_pixels = 0
	_dirty = false


func _connected_component(request: PaintDepositRequest) -> PackedInt32Array:
	var center_xz := Vector2(request.world_position.x, request.world_position.z)
	if not _world_bounds.has_point(center_xz):
		return PackedInt32Array()
	var seed := _world_to_pixel_index(center_xz)
	if seed < 0 or _eligible_bytes[seed] < 128:
		return PackedInt32Array()
	var minimum := _world_to_pixel_coordinates(center_xz - Vector2.ONE * request.radius)
	var maximum := _world_to_pixel_coordinates(center_xz + Vector2.ONE * request.radius)
	minimum.x = clampi(minimum.x - 1, 0, MASK_SIZE - 1)
	minimum.y = clampi(minimum.y - 1, 0, MASK_SIZE - 1)
	maximum.x = clampi(maximum.x + 1, 0, MASK_SIZE - 1)
	maximum.y = clampi(maximum.y + 1, 0, MASK_SIZE - 1)
	var candidates := PackedByteArray()
	candidates.resize(MASK_SIZE * MASK_SIZE)
	candidates.fill(0)
	var radius_squared := request.radius * request.radius
	var needs_facing := request.source_kind in [PaintDepositRequest.SourceKind.IMPACT, PaintDepositRequest.SourceKind.BURST]
	for pixel_y in range(minimum.y, maximum.y + 1):
		for pixel_x in range(minimum.x, maximum.x + 1):
			var index := pixel_y * MASK_SIZE + pixel_x
			if _eligible_bytes[index] < 128:
				continue
			var surface_position := _surface_position_at_pixel(pixel_x, pixel_y)
			if surface_position.distance_squared_to(request.world_position) > radius_squared:
				continue
			if needs_facing and _surface_normal_at_pixel(pixel_x, pixel_y).dot(request.world_normal) < NORMAL_FACING_THRESHOLD:
				continue
			candidates[index] = 1
	if candidates[seed] == 0:
		return PackedInt32Array()
	var component := PackedInt32Array()
	var queue := PackedInt32Array([seed])
	candidates[seed] = 0
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		component.append(current)
		var point := Vector2i(current % MASK_SIZE, current / MASK_SIZE)
		for offset in NEIGHBOR_OFFSETS:
			var neighbor := point + offset
			if neighbor.x < minimum.x or neighbor.x > maximum.x or neighbor.y < minimum.y or neighbor.y > maximum.y:
				continue
			var neighbor_index := neighbor.y * MASK_SIZE + neighbor.x
			if candidates[neighbor_index] != 0:
				candidates[neighbor_index] = 0
				queue.append(neighbor_index)
	return component


func _write_component(request: PaintDepositRequest, component: PackedInt32Array) -> Dictionary:
	var written := 0
	var newly_painted := 0
	var amount_alpha := request.amount / _tuning.paint_units_per_full_alpha * _tuning.intensity_multiplier(request.source_kind)
	var radius_squared := request.radius * request.radius
	for index in component:
		var pixel_x := index % MASK_SIZE
		var pixel_y := index / MASK_SIZE
		var surface_position := _surface_position_at_pixel(pixel_x, pixel_y)
		var q: float = surface_position.distance_squared_to(request.world_position) / maxf(radius_squared, 0.000001)
		var radial_weight := maxf(0.0, 1.0 - 0.7 * q)
		var delta_alpha := clampf(amount_alpha * radial_weight, 0.0, 1.0)
		var existing := float(_paint_bytes[index]) / 255.0
		var updated := minf(1.0, existing + delta_alpha)
		if updated <= existing + 0.000001:
			continue
		if existing < _tuning.painted_threshold and updated >= _tuning.painted_threshold:
			_painted_eligible_pixels += 1
			newly_painted += 1
		_paint_bytes[index] = roundi(updated * 255.0)
		_recent_bytes[index] = 255
		written += 1
		_dirty = true
	return {"written": written, "newly_painted": newly_painted}


func _apply_steepest_descent_flow(request: PaintDepositRequest) -> Dictionary:
	var written := 0
	var newly_painted := 0
	var current := _world_to_pixel_index(Vector2(request.world_position.x, request.world_position.z))
	var amount := request.amount * _tuning.flow_amount_ratio
	var radius := maxf(0.8, request.radius * _tuning.flow_radius_ratio)
	for step_index in range(mini(request.maximum_flow_steps, 12)):
		var current_point := Vector2i(current % MASK_SIZE, current / MASK_SIZE)
		var best := -1
		var current_position := _surface_position_at_pixel(current_point.x, current_point.y)
		var best_height: float = current_position.y
		for offset in NEIGHBOR_OFFSETS:
			var candidate := current_point + offset
			if candidate.x < 0 or candidate.x >= MASK_SIZE or candidate.y < 0 or candidate.y >= MASK_SIZE:
				continue
			var candidate_index := candidate.y * MASK_SIZE + candidate.x
			if _eligible_bytes[candidate_index] < 128:
				continue
			var candidate_position := _surface_position_at_pixel(candidate.x, candidate.y)
			var candidate_height: float = candidate_position.y
			if candidate_height < best_height - 0.0001:
				best_height = candidate_height
				best = candidate_index
		if best < 0:
			break
		current = best
		var best_point := Vector2i(current % MASK_SIZE, current / MASK_SIZE)
		var best_position := _surface_position_at_pixel(best_point.x, best_point.y)
		var best_normal := _surface_normal_at_pixel(best_point.x, best_point.y)
		var center_alpha := amount / _tuning.paint_units_per_full_alpha * _tuning.intensity_multiplier(request.source_kind)
		if center_alpha < _tuning.minimum_flow_alpha:
			break
		var flow_request := PaintDepositRequest.new(
			request.source_kind, best_position, best_normal, radius, amount,
			false, 0, request.source_instance_id, request.physics_tick,
			request.sequence_number * 16 + step_index + 1
		)
		var component := _connected_component(flow_request)
		if component.is_empty():
			break
		var counts := _write_component(flow_request, component)
		written += int(counts.written)
		newly_painted += int(counts.newly_painted)
		amount *= _tuning.flow_decay
	return {"written": written, "newly_painted": newly_painted}


func _surface_position_at_pixel(pixel_x: int, pixel_y: int) -> Vector3:
	var normalized := Vector2(
		(float(pixel_x) + 0.5) / float(MASK_SIZE),
		(float(pixel_y) + 0.5) / float(MASK_SIZE)
	)
	var world_xz := _world_bounds.position + normalized * _world_bounds.size
	var local := _world_to_local(world_xz)
	return Vector3(
		world_xz.x,
		_terrain_origin_y + _generated_layout.height_at_local(local.x, local.y),
		world_xz.y
	)


func _surface_normal_at_pixel(pixel_x: int, pixel_y: int) -> Vector3:
	var normalized := Vector2(
		(float(pixel_x) + 0.5) / float(MASK_SIZE),
		(float(pixel_y) + 0.5) / float(MASK_SIZE)
	)
	var world_xz := _world_bounds.position + normalized * _world_bounds.size
	var local := _world_to_local(world_xz)
	return _generated_layout.normal_at_local(local.x, local.y)


func _world_to_pixel_coordinates(world_xz: Vector2) -> Vector2i:
	var normalized := (world_xz - _world_bounds.position) / _world_bounds.size
	return Vector2i(floori(normalized.x * MASK_SIZE), floori(normalized.y * MASK_SIZE))


func _world_to_pixel_index(world_xz: Vector2) -> int:
	var point := _world_to_pixel_coordinates(world_xz)
	if point.x < 0 or point.x >= MASK_SIZE or point.y < 0 or point.y >= MASK_SIZE:
		return -1
	return point.y * MASK_SIZE + point.x


func _world_to_local(world_xz: Vector2) -> Vector2:
	return world_xz - (_world_bounds.position + _world_bounds.size * 0.5)


func _upload_dirty_images() -> void:
	if not _dirty:
		return
	_paint_image.set_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _paint_bytes)
	_recent_image.set_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8, _recent_bytes)
	_paint_texture.update(_paint_image)
	_recent_texture.update(_recent_image)
	_dirty = false
