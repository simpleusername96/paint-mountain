class_name MechanismPlacementGenerator
extends RefCounted

const MAX_PLACEMENT_SLOPE_DEGREES := 18.0
const MINIMUM_SEPARATION := 10.0
const BOUNDS_CLEARANCE := 5.0


static func generate(stage_data: StageData, layout: GeneratedStageLayout) -> Array[MechanismPlacement]:
	var placements: Array[MechanismPlacement] = []
	if stage_data == null or layout == null:
		return placements
	for mechanism_data in stage_data.mechanism_loadout:
		var placement := _place_one(stage_data, layout, mechanism_data, placements)
		if placement == null:
			layout.metrics["placement_failed_kind"] = MechanismData.Kind.keys()[mechanism_data.kind]
			return []
		placements.append(placement)
	return placements


static func _place_one(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		mechanism_data: MechanismData,
		existing: Array[MechanismPlacement]
) -> MechanismPlacement:
	var route_index := _route_index_for(mechanism_data.kind, layout.route_spines.size())
	var range := _route_range_for(mechanism_data.kind)
	var route := layout.route_spines[route_index]
	var candidates: Array[Dictionary] = []
	var debug_counts := {"range": 0, "route": 0, "slope": 0, "projected": 0, "line_of_sight": 0, "visibility": 0, "branch": 0}
	var size := layout.sample_size()
	for z_index in range(2, size.y - 2, 2):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, float(z_index) / float(layout.cell_count.y))
		var route_t := _route_t_for_z(route, local_z)
		if route_t < range.x or route_t > range.y:
			continue
		debug_counts.range += 1
		var route_center := layout.route_position(route_index, route_t)
		for x_index in range(2, size.x - 2, 2):
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, float(x_index) / float(layout.cell_count.x))
			if absf(local_x - route_center.x) > 0.55 * layout.route_widths[route_index]:
				continue
			debug_counts.route += 1
			var local_xz := Vector2(local_x, local_z)
			if not _inside_clear_bounds(layout.local_bounds, local_xz):
				continue
			if not _separated_from(existing, local_xz):
				continue
			var normal := layout.normal_at_local(local_x, local_z)
			var slope := rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
			if slope > MAX_PLACEMENT_SLOPE_DEGREES:
				continue
			debug_counts.slope += 1
			var height := layout.height_at_local(local_x, local_z)
			var diameter := _diameter_for(mechanism_data.kind)
			var visibility := _visibility_score(stage_data, layout, Vector3(local_x, height + diameter * 0.5, local_z), diameter)
			if visibility == -2.0:
				debug_counts.projected += 1
				continue
			if visibility < 0.0:
				debug_counts.line_of_sight += 1
				continue
			debug_counts.visibility += 1
			if mechanism_data.kind == MechanismData.Kind.SPLITTER and _branch_separation(layout, route_t) < 18.0:
				continue
			debug_counts.branch += 1
			var score := _score_candidate(stage_data, layout, mechanism_data.kind, route_index, route_t, local_xz, height, slope, visibility)
			var grid_index := z_index * size.x + x_index
			candidates.append({
				"local_xz": local_xz,
				"route_t": route_t,
				"height": height,
				"score": score,
				"tie": (grid_index ^ layout.accepted_seed) & 0x7fffffff,
				"grid_index": grid_index,
			})
	if candidates.is_empty():
		layout.metrics["placement_debug_%s" % MechanismData.Kind.keys()[mechanism_data.kind]] = debug_counts
		return null
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.score), float(b.score)):
			return float(a.score) > float(b.score)
		if int(a.tie) != int(b.tie):
			return int(a.tie) < int(b.tie)
		return int(a.grid_index) < int(b.grid_index)
	)
	var selected: Dictionary = candidates[0]
	var result := MechanismPlacement.new()
	result.mechanism_data = mechanism_data
	result.local_xz = selected.local_xz
	result.height_offset = _height_offset_for(mechanism_data.kind)
	if mechanism_data.kind == MechanismData.Kind.BUMPER:
		var downstream := layout.route_position(1, minf(float(selected.route_t) + 0.14, 1.0))
		var direction := Vector2(downstream.x, downstream.z) - result.local_xz
		result.yaw_degrees = rad_to_deg(atan2(direction.x, -direction.y))
	return result


static func _route_index_for(kind: MechanismData.Kind, route_count: int) -> int:
	match kind:
		MechanismData.Kind.SPLITTER:
			return mini(1, route_count - 1)
		MechanismData.Kind.BUMPER:
			return mini(2, route_count - 1)
		_:
			return 0


static func _route_range_for(kind: MechanismData.Kind) -> Vector2:
	match kind:
		MechanismData.Kind.SPLITTER:
			return Vector2(0.56, 0.64)
		MechanismData.Kind.BUMPER:
			return Vector2(0.68, 0.78)
		_:
			return Vector2(0.28, 0.44)


static func _route_t_for_z(route: PackedVector3Array, local_z: float) -> float:
	if local_z <= route[0].z:
		return 0.0
	for index in range(route.size() - 1):
		if local_z <= route[index + 1].z:
			var segment_t := inverse_lerp(route[index].z, route[index + 1].z, local_z)
			return (float(index) + segment_t) / float(route.size() - 1)
	return 1.0


static func _score_candidate(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		kind: MechanismData.Kind,
		route_index: int,
		route_t: float,
		local_xz: Vector2,
		height: float,
		slope: float,
		visibility: float
) -> float:
	var height_score := clampf(height / 90.0, 0.0, 1.0)
	var downstream := clampf(1.0 - route_t, 0.0, 1.0)
	var flatness := clampf(1.0 - slope / MAX_PLACEMENT_SLOPE_DEGREES, 0.0, 1.0)
	var approach := _approach_alignment(stage_data, layout, route_index, route_t, local_xz)
	match kind:
		MechanismData.Kind.SPLITTER:
			return 0.35 * clampf(_branch_separation(layout, route_t) / 90.0, 0.0, 1.0) \
					+ 0.25 * height_score + 0.20 * approach + 0.20 * visibility
		MechanismData.Kind.BUMPER:
			return 0.35 * downstream + 0.25 * approach + 0.20 * height_score + 0.20 * visibility
		_:
			return 0.35 * height_score + 0.30 * downstream + 0.20 * visibility + 0.15 * flatness


static func _approach_alignment(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		route_index: int,
		route_t: float,
		local_xz: Vector2
) -> float:
	var cannon_xz := Vector2(stage_data.cannon_transform.origin.x - stage_data.terrain_center.x, stage_data.cannon_transform.origin.z - stage_data.terrain_center.z)
	var incoming := (local_xz - cannon_xz).normalized()
	var downstream_point := layout.route_position(route_index, minf(route_t + 0.08, 1.0))
	var downstream := (Vector2(downstream_point.x, downstream_point.z) - local_xz).normalized()
	return clampf((incoming.dot(downstream) + 1.0) * 0.5, 0.0, 1.0)


static func _branch_separation(layout: GeneratedStageLayout, route_t: float) -> float:
	if layout.route_spines.size() < 3:
		return 0.0
	var directions: Array[Vector2] = []
	for route_index in range(3):
		var start := layout.route_position(route_index, route_t)
		var finish := layout.route_position(route_index, minf(route_t + 0.18, 1.0))
		directions.append((Vector2(finish.x, finish.z) - Vector2(start.x, start.z)).normalized())
	var minimum_angle := 180.0
	for first in range(directions.size()):
		for second in range(first + 1, directions.size()):
			minimum_angle = minf(minimum_angle, rad_to_deg(acos(clampf(directions[first].dot(directions[second]), -1.0, 1.0))))
	return minimum_angle


static func _visibility_score(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		local_position: Vector3,
		diameter: float
) -> float:
	var world_position := stage_data.terrain_center + local_position
	var camera_position := stage_data.aiming_camera_position
	var camera_forward := (stage_data.aiming_camera_target - camera_position).normalized()
	var camera_depth := maxf((world_position - camera_position).dot(camera_forward), 0.01)
	var projected_1080 := diameter / (2.0 * tan(deg_to_rad(25.0)) * camera_depth) * 1080.0
	var projected_720 := diameter / (2.0 * tan(deg_to_rad(25.0)) * camera_depth) * 720.0
	if projected_1080 < 32.0 or projected_720 < 22.0:
		return -2.0
	for step in range(1, 21):
		var t := float(step) / 24.0
		var point := camera_position.lerp(world_position, t)
		var local_x := point.x - stage_data.terrain_center.x
		var local_z := point.z - stage_data.terrain_center.z
		if not layout.local_bounds.has_point(Vector2(local_x, local_z)):
			continue
		var surface_y := stage_data.terrain_center.y + layout.height_at_local(local_x, local_z)
		if surface_y > point.y + 0.5:
			return -1.0
	return clampf(minf(projected_1080 / 64.0, projected_720 / 44.0), 0.0, 1.0)


static func _inside_clear_bounds(bounds: Rect2, point: Vector2) -> bool:
	return point.x >= bounds.position.x + BOUNDS_CLEARANCE \
			and point.x <= bounds.end.x - BOUNDS_CLEARANCE \
			and point.y >= bounds.position.y + BOUNDS_CLEARANCE \
			and point.y <= bounds.end.y - BOUNDS_CLEARANCE


static func _separated_from(existing: Array[MechanismPlacement], point: Vector2) -> bool:
	for placement in existing:
		if placement.local_xz.distance_to(point) < MINIMUM_SEPARATION:
			return false
	return true


static func _diameter_for(kind: MechanismData.Kind) -> float:
	match kind:
		MechanismData.Kind.SPLITTER:
			return 4.5
		MechanismData.Kind.BUMPER:
			return 3.8
		_:
			return 4.2


static func _height_offset_for(kind: MechanismData.Kind) -> float:
	match kind:
		MechanismData.Kind.SPLITTER:
			return 1.1
		MechanismData.Kind.BUMPER:
			return 0.9
		_:
			return 1.0
