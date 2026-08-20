extends RefCounted

## Incremental scan/connect/write state for one canonical paint command.
## PaintSystem owns scheduling and authority; this cursor only retains the
## deterministic raster position needed to stop at a frame-safe boundary.

enum Phase {
	RADIAL_SCAN,
	RADIAL_CONNECT,
	RADIAL_WRITE,
	SWEEP_SCAN,
	SWEEP_CONNECT,
	SWEEP_WRITE,
	FALLBACK_SCAN,
	FALLBACK_CONNECT,
	FALLBACK_WRITE,
	COMPLETE,
}

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

var command
var written_pixel_count: int = 0
var newly_painted_pixel_count: int = 0

var _phase: Phase = Phase.COMPLETE
var _pixel_bounds := Rect2i()
var _candidate_generation: int = 0
var _scan_offset: int = 0
var _visit_generation: int = 0
var _component_queue := PackedInt32Array()
var _component_pixels := PackedInt32Array()
var _component_cursor: int = 0
var _write_cursor: int = 0
var _scan_candidates := PackedInt32Array()
var _scan_single_component: bool = true
var _scan_row_y: int = -1
var _scan_row_first_x: int = -1
var _scan_row_last_x: int = -1
var _previous_row_y: int = -1
var _previous_row_first_x: int = -1
var _previous_row_last_x: int = -1
var _from_seed: int = -1
var _to_seed: int = -1
var _fallback_endpoint: int = -1


func _init(owner, paint_command) -> void:
	command = paint_command
	if command is RadialPaintMark:
		_begin_radial(owner)
	elif command is SurfacePaintSweep:
		_begin_sweep(owner)


func is_complete() -> bool:
	return _phase == Phase.COMPLETE


func advance(owner, work_budget: int) -> int:
	var remaining: int = maxi(work_budget, 1)
	var initial: int = remaining
	while remaining > 0 and _phase != Phase.COMPLETE:
		match _phase:
			Phase.RADIAL_SCAN:
				if _scan_offset >= _pixel_bounds.size.x * _pixel_bounds.size.y:
					_finish_scan_row()
					var seed: int = owner._snap_candidate(command.center, _candidate_generation)
					if seed < 0:
						_phase = Phase.COMPLETE
					elif _scan_single_component:
						_component_pixels = _scan_candidates
						_write_cursor = 0
						_phase = Phase.RADIAL_WRITE
					else:
						_begin_component(owner, seed, Phase.RADIAL_CONNECT)
					continue
				_scan_radial_candidate(owner, command.center, command.normal, command.radius)
				remaining -= 1
			Phase.RADIAL_CONNECT:
				if not _advance_component(owner):
					_phase = Phase.RADIAL_WRITE
					_write_cursor = 0
					continue
				remaining -= 1
			Phase.RADIAL_WRITE:
				if _write_cursor >= _component_pixels.size():
					_phase = Phase.COMPLETE
					continue
				_write_radial_pixel(owner, _component_pixels[_write_cursor], command.center, command.radius)
				_write_cursor += 1
				remaining -= 1
			Phase.SWEEP_SCAN:
				if _scan_offset >= _pixel_bounds.size.x * _pixel_bounds.size.y:
					_finish_scan_row()
					_from_seed = owner._snap_candidate(command.from_point, _candidate_generation)
					_to_seed = owner._snap_candidate(command.to_point, _candidate_generation)
					if _from_seed >= 0 and _to_seed >= 0 and _scan_single_component:
						_component_pixels = _scan_candidates
						_write_cursor = 0
						_phase = Phase.SWEEP_WRITE
					elif _from_seed >= 0 and _to_seed >= 0:
						_begin_component(owner, _from_seed, Phase.SWEEP_CONNECT)
					else:
						_begin_next_fallback(owner)
					continue
				_scan_sweep_candidate(owner)
				remaining -= 1
			Phase.SWEEP_CONNECT:
				if not _advance_component(owner):
					if owner._visited_generation[_to_seed] == _visit_generation:
						_phase = Phase.SWEEP_WRITE
						_write_cursor = 0
					else:
						_begin_next_fallback(owner)
					continue
				remaining -= 1
			Phase.SWEEP_WRITE:
				if _write_cursor >= _component_pixels.size():
					_phase = Phase.COMPLETE
					continue
				_write_sweep_pixel(owner, _component_pixels[_write_cursor])
				_write_cursor += 1
				remaining -= 1
			Phase.FALLBACK_SCAN:
				if _scan_offset >= _pixel_bounds.size.x * _pixel_bounds.size.y:
					_finish_scan_row()
					var center: Vector3 = _fallback_center()
					var seed: int = owner._snap_candidate(center, _candidate_generation)
					if seed < 0:
						_begin_next_fallback(owner)
					elif _scan_single_component:
						_component_pixels = _scan_candidates
						_write_cursor = 0
						_phase = Phase.FALLBACK_WRITE
					else:
						_begin_component(owner, seed, Phase.FALLBACK_CONNECT)
					continue
				_scan_radial_candidate(
					owner, _fallback_center(), _fallback_normal(), command.footprint_radius
				)
				remaining -= 1
			Phase.FALLBACK_CONNECT:
				if not _advance_component(owner):
					_phase = Phase.FALLBACK_WRITE
					_write_cursor = 0
					continue
				remaining -= 1
			Phase.FALLBACK_WRITE:
				if _write_cursor >= _component_pixels.size():
					_begin_next_fallback(owner)
					continue
				_write_radial_pixel(
					owner,
					_component_pixels[_write_cursor],
					_fallback_center(),
					command.footprint_radius
				)
				_write_cursor += 1
				remaining -= 1
	return initial - remaining


func _begin_radial(owner) -> void:
	_pixel_bounds = owner._candidate_pixel_bounds(
		Vector2(command.center.x - command.radius, command.center.z - command.radius),
		Vector2(command.center.x + command.radius, command.center.z + command.radius)
	)
	if not _pixel_bounds.has_area():
		return
	_candidate_generation = owner._next_candidate_generation()
	_scan_offset = 0
	_reset_scan_connectivity()
	_phase = Phase.RADIAL_SCAN


func _begin_sweep(owner) -> void:
	_pixel_bounds = owner._candidate_pixel_bounds(
		Vector2(
			minf(command.from_point.x, command.to_point.x) - command.footprint_radius,
			minf(command.from_point.z, command.to_point.z) - command.footprint_radius
		),
		Vector2(
			maxf(command.from_point.x, command.to_point.x) + command.footprint_radius,
			maxf(command.from_point.z, command.to_point.z) + command.footprint_radius
		)
	)
	if not _pixel_bounds.has_area():
		return
	_candidate_generation = owner._next_candidate_generation()
	_scan_offset = 0
	_reset_scan_connectivity()
	_phase = Phase.SWEEP_SCAN


func _scan_radial_candidate(owner, center: Vector3, normal: Vector3, radius: float) -> void:
	var pixel_x: int = _pixel_bounds.position.x + _scan_offset % _pixel_bounds.size.x
	var pixel_y: int = _pixel_bounds.position.y + _scan_offset / _pixel_bounds.size.x
	_scan_offset += 1
	var index: int = pixel_y * int(owner.MASK_SIZE) + pixel_x
	if not owner._ensure_surface_sample(index):
		return
	if owner._surface_positions[index].distance_squared_to(center) > radius * radius:
		return
	if owner._surface_normals[index].dot(normal) < owner.NORMAL_FACING_THRESHOLD:
		return
	owner._candidate_generation[index] = _candidate_generation
	_record_scan_candidate(index, pixel_x, pixel_y)


func _scan_sweep_candidate(owner) -> void:
	var pixel_x: int = _pixel_bounds.position.x + _scan_offset % _pixel_bounds.size.x
	var pixel_y: int = _pixel_bounds.position.y + _scan_offset / _pixel_bounds.size.x
	_scan_offset += 1
	var index: int = pixel_y * int(owner.MASK_SIZE) + pixel_x
	if not owner._ensure_surface_sample(index):
		return
	var surface_point: Vector3 = owner._surface_positions[index]
	var delta: Vector3 = command.to_point - command.from_point
	var length_squared: float = delta.length_squared()
	var t: float = clampf(
		(surface_point - command.from_point).dot(delta) / maxf(length_squared, 0.000001),
		0.0,
		1.0
	)
	var closest: Vector3 = command.from_point + delta * t
	if surface_point.distance_squared_to(closest) \
			> command.footprint_radius * command.footprint_radius:
		return
	var expected_normal: Vector3 = command.from_normal.lerp(command.to_normal, t).normalized()
	if owner._surface_normals[index].dot(expected_normal) < owner.NORMAL_FACING_THRESHOLD:
		return
	owner._candidate_generation[index] = _candidate_generation
	_record_scan_candidate(index, pixel_x, pixel_y)


func _begin_component(owner, seed: int, next_phase: Phase) -> void:
	_component_queue.clear()
	_component_pixels.clear()
	_component_cursor = 0
	_visit_generation = owner._next_visited_generation()
	_component_queue.append(seed)
	owner._visited_generation[seed] = _visit_generation
	_phase = next_phase


func _advance_component(owner) -> bool:
	if _component_cursor >= _component_queue.size():
		return false
	var current: int = _component_queue[_component_cursor]
	_component_cursor += 1
	_component_pixels.append(current)
	var point := Vector2i(current % int(owner.MASK_SIZE), current / int(owner.MASK_SIZE))
	for offset in NEIGHBOR_OFFSETS:
		var neighbor: Vector2i = point + offset
		if neighbor.x < 0 or neighbor.x >= owner.MASK_SIZE \
				or neighbor.y < 0 or neighbor.y >= owner.MASK_SIZE:
			continue
		var neighbor_index: int = neighbor.y * int(owner.MASK_SIZE) + neighbor.x
		if owner._candidate_generation[neighbor_index] != _candidate_generation \
				or owner._visited_generation[neighbor_index] == _visit_generation:
			continue
		owner._visited_generation[neighbor_index] = _visit_generation
		_component_queue.append(neighbor_index)
	return true


func _begin_next_fallback(owner) -> void:
	_component_queue.clear()
	_component_pixels.clear()
	_component_cursor = 0
	_write_cursor = 0
	_fallback_endpoint += 1
	while _fallback_endpoint < 2:
		var center: Vector3 = _fallback_center()
		var radius: float = command.footprint_radius
		_pixel_bounds = owner._candidate_pixel_bounds(
			Vector2(center.x - radius, center.z - radius),
			Vector2(center.x + radius, center.z + radius)
		)
		_candidate_generation = owner._next_candidate_generation()
		_scan_offset = 0
		_reset_scan_connectivity()
		if _pixel_bounds.has_area():
			_phase = Phase.FALLBACK_SCAN
			return
		_fallback_endpoint += 1
	_phase = Phase.COMPLETE


func _reset_scan_connectivity() -> void:
	_scan_candidates.clear()
	_scan_single_component = true
	_scan_row_y = -1
	_scan_row_first_x = -1
	_scan_row_last_x = -1
	_previous_row_y = -1
	_previous_row_first_x = -1
	_previous_row_last_x = -1


func _record_scan_candidate(index: int, pixel_x: int, pixel_y: int) -> void:
	_scan_candidates.append(index)
	if _scan_row_y < 0:
		_scan_row_y = pixel_y
		_scan_row_first_x = pixel_x
		_scan_row_last_x = pixel_x
		return
	if pixel_y != _scan_row_y:
		_finish_scan_row()
		_scan_row_y = pixel_y
		_scan_row_first_x = pixel_x
		_scan_row_last_x = pixel_x
		return
	if pixel_x != _scan_row_last_x + 1:
		_scan_single_component = false
	_scan_row_last_x = pixel_x


func _finish_scan_row() -> void:
	if _scan_row_y < 0:
		return
	if _previous_row_y >= 0:
		if _scan_row_y != _previous_row_y + 1 \
				or _scan_row_first_x > _previous_row_last_x + 1 \
				or _scan_row_last_x < _previous_row_first_x - 1:
			_scan_single_component = false
	_previous_row_y = _scan_row_y
	_previous_row_first_x = _scan_row_first_x
	_previous_row_last_x = _scan_row_last_x
	_scan_row_y = -1
	_scan_row_first_x = -1
	_scan_row_last_x = -1


func _fallback_center() -> Vector3:
	return command.from_point if _fallback_endpoint == 0 else command.to_point


func _fallback_normal() -> Vector3:
	return command.from_normal if _fallback_endpoint == 0 else command.to_normal


func _write_radial_pixel(owner, index: int, center: Vector3, radius: float) -> void:
	var distance: float = owner._surface_positions[index].distance_to(center)
	_accumulate_write(owner, index, owner._alpha_for_distance(distance, radius))


func _write_sweep_pixel(owner, index: int) -> void:
	var surface_point: Vector3 = owner._surface_positions[index]
	var delta: Vector3 = command.to_point - command.from_point
	var length_squared: float = delta.length_squared()
	var t: float = clampf(
		(surface_point - command.from_point).dot(delta) / maxf(length_squared, 0.000001),
		0.0,
		1.0
	)
	var distance: float = surface_point.distance_to(command.from_point + delta * t)
	_accumulate_write(
		owner,
		index,
		owner._alpha_for_distance(distance, command.footprint_radius)
	)


func _accumulate_write(owner, index: int, alpha: int) -> void:
	var write_result: int = owner._write_paint_value(index, alpha, int(command.channel))
	if write_result != owner.WRITE_RESULT_NONE:
		written_pixel_count += 1
	if (write_result & owner.WRITE_RESULT_NEW_TARGET) != 0:
		newly_painted_pixel_count += 1
