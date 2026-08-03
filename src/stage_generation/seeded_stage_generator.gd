class_name SeededStageGenerator
extends RefCounted

const ATTEMPT_COUNT := 32
const ATTEMPT_STRIDE := 7919
const MASK_SIZE := 512
const MAX_ROUTE_SLOPE_DEGREES := 58.0
const P95_ROUTE_SLOPE_DEGREES := 50.0
const ROUTE_START_Z := -46.0
const ROUTE_END_Z := 54.0
const ROUTE_STATION_COUNT := 8
const DECORATION_MODEL_CYCLE: Array[StringName] = [
	&"tree_pineSmallA", &"tree_pineSmallB", &"rock_smallA", &"tree_pineTallA", &"rock_largeA",
]


static func generate(
		profile: StageGenerationProfile,
		terrain_seed: int = 0,
		stage_data: StageData = null
) -> GeneratedStageLayout:
	if profile == null or not profile.is_valid():
		push_error("Stage generation profile is invalid.")
		return null
	var requested_seed := terrain_seed if terrain_seed != 0 else profile.base_seed
	for attempt_index in range(ATTEMPT_COUNT):
		var attempt_seed := int((requested_seed + attempt_index * ATTEMPT_STRIDE) & 0x7fffffff)
		var layout := _build_attempt(profile, requested_seed, attempt_seed, attempt_index)
		if _validate(profile, layout) and _finalize_layout(profile, stage_data, layout):
			return layout
	var fallback := _build_attempt(profile, requested_seed, profile.fallback_seed, -1)
	if _validate(profile, fallback) and _finalize_layout(profile, stage_data, fallback):
		push_warning("Stage generation used validated fallback seed %d for %s." % [profile.fallback_seed, profile.profile_id])
		return fallback
	push_error("Stage generation failed every deterministic attempt and fallback for %s: %s" % [profile.profile_id, str(fallback.metrics)])
	return null


static func _build_attempt(
		profile: StageGenerationProfile,
		requested_seed: int,
		attempt_seed: int,
		attempt_index: int
) -> GeneratedStageLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = attempt_seed
	var route_result := _generate_routes(profile, rng)
	var routes: Array[PackedVector3Array] = route_result.routes
	var lobes := _generate_lobes(profile, routes, rng)
	var noise := FastNoiseLite.new()
	noise.seed = int(rng.randi() & 0x7fffffff)
	noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	noise.frequency = 0.035
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE

	var sample_size := profile.cell_count + Vector2i.ONE
	var heights := PackedFloat32Array()
	heights.resize(sample_size.x * sample_size.y)
	for z_index in range(sample_size.y):
		var local_z := lerpf(profile.local_bounds.position.y, profile.local_bounds.end.y, float(z_index) / float(profile.cell_count.y))
		for x_index in range(sample_size.x):
			var local_x := lerpf(profile.local_bounds.position.x, profile.local_bounds.end.x, float(x_index) / float(profile.cell_count.x))
			heights[z_index * sample_size.x + x_index] = _synthesize_height(
				profile, routes, route_result.widths, lobes, noise, local_x, local_z
			)

	var layout := GeneratedStageLayout.new()
	layout.profile_id = profile.profile_id
	layout.profile_version = profile.profile_version
	layout.terrain_seed = requested_seed
	layout.accepted_seed = attempt_seed
	layout.generation_attempt = attempt_index
	layout.cell_count = profile.cell_count
	layout.local_bounds = profile.local_bounds
	layout.heights = heights
	layout.route_spines = routes
	layout.route_widths = route_result.widths
	layout.route_roles = route_result.roles
	layout.route_shelf_positions = route_result.shelf_positions
	layout.route_shelf_radii = route_result.shelf_radii
	layout.checksum = _height_checksum(heights)
	return layout


static func _generate_routes(profile: StageGenerationProfile, rng: RandomNumberGenerator) -> Dictionary:
	var routes: Array[PackedVector3Array] = []
	var widths := PackedFloat32Array()
	var roles := PackedInt32Array()
	var shelf_positions := PackedFloat32Array()
	var shelf_radii := PackedFloat32Array()
	for route_profile in profile.routes:
		var magnitudes := PackedFloat32Array()
		for grade in route_profile.grade_pattern:
			var draw_range := route_profile.downhill_drop_range if grade < 0 else route_profile.uphill_rise_range
			magnitudes.append(rng.randf_range(draw_range.x, draw_range.y))
		var lateral_bend := rng.randf_range(route_profile.lateral_bend_range.x, route_profile.lateral_bend_range.y)
		var station_jitter := PackedFloat32Array()
		for _station_index in range(1, ROUTE_STATION_COUNT - 1):
			station_jitter.append(rng.randf_range(profile.station_x_jitter_range.x, profile.station_x_jitter_range.y))

		var route := PackedVector3Array()
		var height := profile.nominal_peak
		for station_index in range(ROUTE_STATION_COUNT):
			if station_index > 0:
				height += float(route_profile.grade_pattern[station_index - 1]) * magnitudes[station_index - 1]
			var t := float(station_index) / float(ROUTE_STATION_COUNT - 1)
			var jitter := 0.0 if station_index == 0 or station_index == ROUTE_STATION_COUNT - 1 else station_jitter[station_index - 1]
			var local_x := smoothstep(0.0, 1.0, t) * route_profile.endpoint_x \
					+ sin(PI * t) * lateral_bend + jitter
			route.append(Vector3(local_x, height, lerpf(ROUTE_START_Z, ROUTE_END_Z, t)))
		routes.append(route)
		widths.append(route_profile.width)
		roles.append(route_profile.role)
		shelf_positions.append(route_profile.mechanism_shelf_t)
		shelf_radii.append(route_profile.mechanism_shelf_radius)
	return {
		"routes": routes,
		"widths": widths,
		"roles": roles,
		"shelf_positions": shelf_positions,
		"shelf_radii": shelf_radii,
	}


static func _generate_lobes(
		profile: StageGenerationProfile,
		routes: Array[PackedVector3Array],
		rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var lobes: Array[Dictionary] = []
	for lobe_index in range(profile.lobe_count):
		var center_x_offset := rng.randf_range(-12.0, 12.0)
		var center_z_offset := rng.randf_range(-6.0, 6.0)
		var radius_x := rng.randf_range(profile.lobe_x_radius_range.x, profile.lobe_x_radius_range.y)
		var radius_z := rng.randf_range(profile.lobe_z_radius_range.x, profile.lobe_z_radius_range.y)
		var peak_multiplier := rng.randf_range(profile.lobe_peak_multiplier_range.x, profile.lobe_peak_multiplier_range.y)
		var t := (float(lobe_index) + 0.5) / float(profile.lobe_count)
		var route_x_total := 0.0
		for route in routes:
			route_x_total += _route_point_at_t(route, t).x
		lobes.append({
			"center": Vector2(
				route_x_total / float(routes.size()) + center_x_offset,
				lerpf(ROUTE_START_Z, ROUTE_END_Z, t) + center_z_offset
			),
			"radii": Vector2(radius_x, radius_z),
			"peak_multiplier": peak_multiplier,
		})
	return lobes


static func _synthesize_height(
		profile: StageGenerationProfile,
		routes: Array[PackedVector3Array],
		widths: PackedFloat32Array,
		lobes: Array[Dictionary],
		noise: FastNoiseLite,
		x: float,
		z: float
) -> float:
	var height := 0.0
	for lobe_index in range(lobes.size()):
		var lobe := lobes[lobe_index]
		var center: Vector2 = lobe.center
		var radii: Vector2 = lobe.radii
		var q := pow((x - center.x) / radii.x, 2.0) + pow((z - center.y) / radii.y, 2.0)
		var contribution := profile.nominal_peak * float(lobe.peak_multiplier) * pow(maxf(0.0, 1.0 - q), 2.0)
		height = contribution if lobe_index == 0 else _smooth_max(height, contribution, profile.smooth_max_k)
	height += noise.get_noise_2d(x, z) * profile.noise_amplitude
	var terraced := roundf(height / 4.0) * 4.0
	height = lerpf(height, terraced, 0.35)

	var lowest_target := INF
	var greatest_influence := 0.0
	for route_index in range(routes.size()):
		var route_sample := _route_sample(routes[route_index], z)
		var distance := absf(x - route_sample.x)
		var half_width := widths[route_index] * 0.5
		var influence := 1.0 if distance <= half_width else 1.0 - smoothstep(half_width, widths[route_index], distance)
		if influence <= 0.0:
			continue
		var route_target := route_sample.y + profile.bank_height * pow(distance / half_width, 2.0)
		lowest_target = minf(lowest_target, route_target)
		greatest_influence = maxf(greatest_influence, influence)
	if greatest_influence > 0.0:
		height = lerpf(height, lowest_target, greatest_influence)

	for route_index in range(routes.size()):
		var shelf_t := profile.routes[route_index].mechanism_shelf_t
		if shelf_t < 0.0:
			continue
		var shelf_center := _route_point_at_t(routes[route_index], shelf_t)
		var shelf_radius := profile.routes[route_index].mechanism_shelf_radius
		var shelf_distance := Vector2(x, z).distance_to(Vector2(shelf_center.x, shelf_center.z))
		var shelf_influence := 1.0 - smoothstep(0.92 * shelf_radius, shelf_radius, shelf_distance)
		height = lerpf(height, shelf_center.y, shelf_influence)

	height = clampf(height, 0.0, profile.accepted_height_range.y)
	var edge_distance := minf(
		minf(x - profile.local_bounds.position.x, profile.local_bounds.end.x - x),
		minf(z - profile.local_bounds.position.y, profile.local_bounds.end.y - z)
	)
	return height * smoothstep(0.0, 12.0, edge_distance)


static func _smooth_max(a: float, b: float, k: float) -> float:
	return maxf(a, b) + pow(maxf(0.0, k - absf(a - b)), 2.0) / (4.0 * k)


static func _validate(profile: StageGenerationProfile, layout: GeneratedStageLayout) -> bool:
	if layout == null or not layout.is_valid():
		return false
	var maximum_height := 0.0
	for height in layout.heights:
		if not is_finite(height):
			layout.metrics = {"rejection": "non_finite_height"}
			return false
		maximum_height = maxf(maximum_height, height)
	layout.metrics = {"maximum_height": maximum_height}
	if maximum_height < profile.accepted_height_range.x or maximum_height > profile.accepted_height_range.y:
		layout.metrics["rejection"] = "maximum_height"
		return false
	if not _validate_edges(layout):
		layout.metrics["rejection"] = "edge_height"
		return false
	if not _validate_routes(profile, layout):
		return false
	if not _validate_shelves(layout):
		layout.metrics["rejection"] = "mechanism_shelf"
		return false
	if not _validate_branch_separation(layout):
		layout.metrics["rejection"] = "branch_separation"
		return false
	layout.metrics["top_triangles"] = profile.cell_count.x * profile.cell_count.y * 2
	return true


static func _validate_edges(layout: GeneratedStageLayout) -> bool:
	var size := layout.sample_size()
	for x in range(size.x):
		if layout.heights[x] > 0.01 or layout.heights[(size.y - 1) * size.x + x] > 0.01:
			return false
	for z in range(size.y):
		if layout.heights[z * size.x] > 0.01 or layout.heights[z * size.x + size.x - 1] > 0.01:
			return false
	return true


static func _validate_routes(profile: StageGenerationProfile, layout: GeneratedStageLayout) -> bool:
	var all_slopes := PackedFloat32Array()
	var reversal_counts := PackedInt32Array()
	for route_index in range(layout.route_spines.size()):
		var route := layout.route_spines[route_index]
		var realized_route := PackedVector3Array()
		for point in route:
			realized_route.append(Vector3(point.x, layout.height_at_local(point.x, point.z), point.z))
		if layout.route_roles[route_index] != profile.routes[route_index].role:
			layout.metrics["rejection"] = "route_role"
			return false
		var reversals := _meaningful_reversals(route)
		reversal_counts.append(reversals)
		if reversals != profile.routes[route_index].target_reversals:
			layout.metrics["rejection"] = "route_reversals"
			return false
		if realized_route[0].y - realized_route[-1].y < 30.0:
			layout.metrics["rejection"] = "route_net_descent"
			return false
		for point in route:
			var edge_distance := minf(
				minf(point.x - layout.local_bounds.position.x, layout.local_bounds.end.x - point.x),
				minf(point.z - layout.local_bounds.position.y, layout.local_bounds.end.y - point.z)
			)
			if edge_distance < 6.0:
				layout.metrics["rejection"] = "route_edge_clearance"
				return false
		for segment_index in range(realized_route.size() - 1):
			var start := realized_route[segment_index]
			var finish := realized_route[segment_index + 1]
			# The final station carries the route into the nonplayable 12 m shell transition.
			if _edge_distance(layout.local_bounds, Vector2(start.x, start.z)) < 12.0 \
					or _edge_distance(layout.local_bounds, Vector2(finish.x, finish.z)) < 12.0:
				continue
			var horizontal_distance := Vector2(start.x, start.z).distance_to(Vector2(finish.x, finish.z))
			all_slopes.append(rad_to_deg(atan(absf(finish.y - start.y) / maxf(horizontal_distance, 0.001))))
	if all_slopes.is_empty():
		layout.metrics["rejection"] = "route_slope_samples"
		return false
	all_slopes.sort()
	var p95_index := clampi(floori(float(all_slopes.size() - 1) * 0.95), 0, all_slopes.size() - 1)
	var maximum_slope := all_slopes[-1]
	var p95_slope := all_slopes[p95_index]
	layout.route_reversal_counts = reversal_counts
	layout.metrics["route_reversals"] = reversal_counts
	layout.metrics["maximum_route_slope"] = maximum_slope
	layout.metrics["p95_route_slope"] = p95_slope
	if maximum_slope > MAX_ROUTE_SLOPE_DEGREES or p95_slope > P95_ROUTE_SLOPE_DEGREES:
		layout.metrics["rejection"] = "route_slope"
		return false
	return true


static func _validate_shelves(layout: GeneratedStageLayout) -> bool:
	for route_index in range(layout.route_spines.size()):
		var shelf_t := layout.route_shelf_positions[route_index]
		if shelf_t < 0.0:
			continue
		var center := layout.route_position(route_index, shelf_t)
		var radius := layout.route_shelf_radii[route_index] * 0.60
		for sample_index in range(17):
			var point := Vector2(center.x, center.z)
			if sample_index > 0:
				var angle := TAU * float(sample_index - 1) / 16.0
				point += Vector2(cos(angle), sin(angle)) * radius
			var slope := _local_slope_degrees(layout, point, 0.25)
			if slope > 8.0:
				return false
	return true


static func _validate_branch_separation(layout: GeneratedStageLayout) -> bool:
	if layout.route_spines.size() == 2:
		for sample_index in range(12):
			var t := lerpf(0.45, 1.0, float(sample_index) / 11.0)
			var first := layout.route_position(0, t)
			var second := layout.route_position(1, t)
			if Vector2(first.x, first.z).distance_to(Vector2(second.x, second.z)) < 24.0:
				return false
	if layout.route_spines.size() == 3:
		var splitter_index := _route_index_for_role(layout, StageRouteProfile.Role.SPLITTER)
		var bumper_index := _route_index_for_role(layout, StageRouteProfile.Role.BUMPER)
		if splitter_index < 0 or bumper_index < 0:
			return false
		for shelf_t in [layout.route_shelf_positions[splitter_index], layout.route_shelf_positions[bumper_index]]:
			var splitter := layout.route_position(splitter_index, shelf_t)
			var bumper := layout.route_position(bumper_index, shelf_t)
			if Vector2(splitter.x, splitter.z).distance_to(Vector2(bumper.x, bumper.z)) < 20.0:
				return false
	return true


static func _finalize_layout(
		profile: StageGenerationProfile,
		stage_data: StageData,
		layout: GeneratedStageLayout
) -> bool:
	if stage_data != null:
		if not stage_data.mechanism_loadout.is_empty():
			layout.mechanism_placements = MechanismPlacementGenerator.generate(stage_data, layout)
			if layout.mechanism_placements.size() != stage_data.mechanism_loadout.size():
				layout.metrics["rejection"] = "mechanism_placement"
				return false
		layout.decoration_placements = _generate_decorations(stage_data, layout)
		if layout.decoration_placements.size() != _decoration_count(stage_data.stage_number):
			layout.metrics["rejection"] = "decoration_placement"
			return false
	var eligible_result := _build_eligible_mask(layout)
	layout.eligible_mask = eligible_result.bytes
	layout.metrics["eligible_ratio"] = float(eligible_result.count) / float(MASK_SIZE * MASK_SIZE)
	_exclude_footprints(layout)
	var eligible_count := 0
	for byte in layout.eligible_mask:
		if byte >= 128:
			eligible_count += 1
	var eligible_ratio := float(eligible_count) / float(MASK_SIZE * MASK_SIZE)
	layout.metrics["eligible_ratio_after_exclusions"] = eligible_ratio
	if eligible_ratio < profile.eligible_ratio_range.x or eligible_ratio > profile.eligible_ratio_range.y:
		layout.metrics["rejection"] = "eligible_ratio_after_exclusions"
		return false
	layout.eligible_mask_checksum = _byte_checksum(layout.eligible_mask)
	return true


static func _build_eligible_mask(layout: GeneratedStageLayout) -> Dictionary:
	var mask := PackedByteArray()
	mask.resize(MASK_SIZE * MASK_SIZE)
	var sample_size := layout.sample_size()
	var normal_y := PackedFloat32Array()
	normal_y.resize(layout.heights.size())
	var step_x := layout.local_bounds.size.x / float(layout.cell_count.x)
	var step_z := layout.local_bounds.size.y / float(layout.cell_count.y)
	for z_index in range(sample_size.y):
		var back := maxi(z_index - 1, 0)
		var front := mini(z_index + 1, sample_size.y - 1)
		for x_index in range(sample_size.x):
			var left := maxi(x_index - 1, 0)
			var right := mini(x_index + 1, sample_size.x - 1)
			var dx := (layout.heights[z_index * sample_size.x + right] - layout.heights[z_index * sample_size.x + left]) \
					/ maxf(float(right - left) * step_x, step_x)
			var dz := (layout.heights[front * sample_size.x + x_index] - layout.heights[back * sample_size.x + x_index]) \
					/ maxf(float(front - back) * step_z, step_z)
			normal_y[z_index * sample_size.x + x_index] = Vector3(-dx, 1.0, -dz).normalized().y
	var count := 0
	for pixel_y in range(MASK_SIZE):
		var normalized_y := (float(pixel_y) + 0.5) / float(MASK_SIZE)
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, normalized_y)
		var grid_z := normalized_y * float(layout.cell_count.y)
		var z0 := mini(floori(grid_z), layout.cell_count.y)
		var z1 := mini(z0 + 1, layout.cell_count.y)
		var tz := grid_z - float(z0)
		for pixel_x in range(MASK_SIZE):
			var normalized_x := (float(pixel_x) + 0.5) / float(MASK_SIZE)
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, normalized_x)
			var edge_distance := minf(
				minf(local_x - layout.local_bounds.position.x, layout.local_bounds.end.x - local_x),
				minf(local_z - layout.local_bounds.position.y, layout.local_bounds.end.y - local_z)
			)
			if edge_distance < 2.5:
				continue
			var grid_x := normalized_x * float(layout.cell_count.x)
			var x0 := mini(floori(grid_x), layout.cell_count.x)
			var x1 := mini(x0 + 1, layout.cell_count.x)
			var tx := grid_x - float(x0)
			var top_height := lerpf(layout.heights[z0 * sample_size.x + x0], layout.heights[z0 * sample_size.x + x1], tx)
			var bottom_height := lerpf(layout.heights[z1 * sample_size.x + x0], layout.heights[z1 * sample_size.x + x1], tx)
			if lerpf(top_height, bottom_height, tz) < 4.0:
				continue
			var top_normal_y := lerpf(normal_y[z0 * sample_size.x + x0], normal_y[z0 * sample_size.x + x1], tx)
			var bottom_normal_y := lerpf(normal_y[z1 * sample_size.x + x0], normal_y[z1 * sample_size.x + x1], tx)
			if lerpf(top_normal_y, bottom_normal_y, tz) < cos(deg_to_rad(75.0)):
				continue
			mask[pixel_y * MASK_SIZE + pixel_x] = 255
			count += 1
	return {"bytes": mask, "count": count}


static func _exclude_footprints(layout: GeneratedStageLayout) -> void:
	for placement in layout.mechanism_placements:
		_clear_mask_circle(layout, placement.local_xz, _mechanism_exclusion_radius(placement.mechanism_data.kind))
	for decoration in layout.decoration_placements:
		_clear_mask_circle(layout, decoration.local_xz, _decoration_footprint_radius(decoration))


static func _clear_mask_circle(layout: GeneratedStageLayout, center: Vector2, radius: float) -> void:
	var minimum_u := (center.x - radius - layout.local_bounds.position.x) / layout.local_bounds.size.x
	var maximum_u := (center.x + radius - layout.local_bounds.position.x) / layout.local_bounds.size.x
	var minimum_v := (center.y - radius - layout.local_bounds.position.y) / layout.local_bounds.size.y
	var maximum_v := (center.y + radius - layout.local_bounds.position.y) / layout.local_bounds.size.y
	var minimum_x := clampi(floori(minimum_u * MASK_SIZE - 0.5), 0, MASK_SIZE - 1)
	var maximum_x := clampi(ceili(maximum_u * MASK_SIZE - 0.5), 0, MASK_SIZE - 1)
	var minimum_y := clampi(floori(minimum_v * MASK_SIZE - 0.5), 0, MASK_SIZE - 1)
	var maximum_y := clampi(ceili(maximum_v * MASK_SIZE - 0.5), 0, MASK_SIZE - 1)
	for pixel_y in range(minimum_y, maximum_y + 1):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, (float(pixel_y) + 0.5) / float(MASK_SIZE))
		for pixel_x in range(minimum_x, maximum_x + 1):
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, (float(pixel_x) + 0.5) / float(MASK_SIZE))
			if center.distance_squared_to(Vector2(local_x, local_z)) <= radius * radius:
				layout.eligible_mask[pixel_y * MASK_SIZE + pixel_x] = 0


static func _generate_decorations(stage_data: StageData, layout: GeneratedStageLayout) -> Array[DecorationPlacement]:
	var candidates: Array[Vector2] = []
	var sample_size := layout.sample_size()
	for z_index in range(2, sample_size.y - 2):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, float(z_index) / float(layout.cell_count.y))
		for x_index in range(2, sample_size.x - 2):
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, float(x_index) / float(layout.cell_count.x))
			if layout.height_at_local(local_x, local_z) < 4.0:
				continue
			if layout.normal_at_local(local_x, local_z).y < cos(deg_to_rad(42.0)):
				continue
			var route_distance := layout.route_distance(local_x, local_z)
			var route_index := int(route_distance.route_index)
			if route_index >= 0 and float(route_distance.distance) < 0.75 * layout.route_widths[route_index] + 1.0:
				continue
			var local_xz := Vector2(local_x, local_z)
			var mechanism_clear := true
			for mechanism in layout.mechanism_placements:
				if local_xz.distance_to(mechanism.local_xz) < _mechanism_exclusion_radius(mechanism.mechanism_data.kind) + 5.0:
					mechanism_clear = false
					break
			if mechanism_clear:
				candidates.append(local_xz)
	var rng := RandomNumberGenerator.new()
	rng.seed = int((layout.accepted_seed ^ 0x5A17D3C1) & 0x7fffffff)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary
	var result: Array[DecorationPlacement] = []
	var requested_count := _decoration_count(stage_data.stage_number)
	for candidate in candidates:
		var separated := true
		for existing in result:
			if candidate.distance_to(existing.local_xz) < 4.0:
				separated = false
				break
		if not separated:
			continue
		var model_id := DECORATION_MODEL_CYCLE[result.size() % DECORATION_MODEL_CYCLE.size()]
		var is_tree := String(model_id).begins_with("tree_")
		var scale_value := rng.randf_range(3.0, 4.5) if is_tree else rng.randf_range(2.0, 3.2)
		result.append(DecorationPlacement.new(model_id, candidate, rng.randf_range(0.0, 360.0), scale_value))
		if result.size() >= requested_count:
			break
	return result


static func _route_sample(route: PackedVector3Array, z: float) -> Vector2:
	if z <= route[0].z:
		return Vector2(route[0].x, route[0].y)
	for index in range(route.size() - 1):
		if z <= route[index + 1].z:
			var t := inverse_lerp(route[index].z, route[index + 1].z, z)
			return Vector2(lerpf(route[index].x, route[index + 1].x, t), lerpf(route[index].y, route[index + 1].y, t))
	return Vector2(route[-1].x, route[-1].y)


static func _route_point_at_t(route: PackedVector3Array, normalized_position: float) -> Vector3:
	var scaled := clampf(normalized_position, 0.0, 1.0) * float(route.size() - 1)
	var first := mini(floori(scaled), route.size() - 1)
	var second := mini(first + 1, route.size() - 1)
	return route[first].lerp(route[second], scaled - float(first))


static func _route_index_for_role(layout: GeneratedStageLayout, role: StageRouteProfile.Role) -> int:
	for index in range(layout.route_roles.size()):
		if layout.route_roles[index] == role:
			return index
	return -1


static func _edge_distance(bounds: Rect2, point: Vector2) -> float:
	return minf(
		minf(point.x - bounds.position.x, bounds.end.x - point.x),
		minf(point.y - bounds.position.y, bounds.end.y - point.y)
	)


static func _local_slope_degrees(layout: GeneratedStageLayout, point: Vector2, step: float) -> float:
	var left := layout.height_at_local(point.x - step, point.y)
	var right := layout.height_at_local(point.x + step, point.y)
	var back := layout.height_at_local(point.x, point.y - step)
	var front := layout.height_at_local(point.x, point.y + step)
	var normal := Vector3(left - right, 2.0 * step, back - front).normalized()
	return rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))


static func _meaningful_reversals(route: PackedVector3Array) -> int:
	var previous_sign := 0
	var reversals := 0
	for index in range(route.size() - 1):
		var delta := route[index + 1].y - route[index].y
		if absf(delta) < 1.5:
			continue
		var current_sign := signi(delta)
		if previous_sign != 0 and current_sign != previous_sign:
			reversals += 1
		previous_sign = current_sign
	return reversals


static func _mechanism_exclusion_radius(kind: MechanismData.Kind) -> float:
	match kind:
		MechanismData.Kind.BURST:
			return 2.8
		MechanismData.Kind.SPLITTER:
			return 2.75
		_:
			return 2.9


static func _decoration_footprint_radius(decoration: DecorationPlacement) -> float:
	var base_radius := 0.35
	if decoration.model_id == &"tree_pineTallA":
		base_radius = 0.45
	elif decoration.model_id == &"rock_smallA":
		base_radius = 0.40
	elif decoration.model_id == &"rock_largeA":
		base_radius = 0.80
	return base_radius * decoration.uniform_scale + 0.5


static func _decoration_count(stage_number: int) -> int:
	match stage_number:
		2:
			return 14
		3:
			return 18
		_:
			return 10


static func _height_checksum(heights: PackedFloat32Array) -> int:
	var hash: int = 2166136261
	for height in heights:
		var quantized := roundi(height * 1000.0)
		for shift in [0, 8, 16, 24]:
			hash = hash ^ ((quantized >> shift) & 0xff)
			hash = int((hash * 16777619) & 0xffffffff)
	return hash


static func _byte_checksum(bytes: PackedByteArray) -> int:
	var hash: int = 2166136261
	for byte in bytes:
		hash = hash ^ byte
		hash = int((hash * 16777619) & 0xffffffff)
	return hash
