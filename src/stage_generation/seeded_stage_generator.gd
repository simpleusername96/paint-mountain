class_name SeededStageGenerator
extends RefCounted

const ATTEMPT_COUNT := 32
const ATTEMPT_STRIDE := 7919
const MAX_ROUTE_SLOPE_DEGREES := 48.0
const P95_ROUTE_SLOPE_DEGREES := 42.0
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
	for attempt in range(ATTEMPT_COUNT):
		var attempt_seed := int((requested_seed + attempt * ATTEMPT_STRIDE) & 0x7fffffff)
		var layout := _build_attempt(profile, requested_seed, attempt_seed, attempt)
		if _validate(profile, layout) and _finalize_placements(profile, stage_data, layout):
			return layout
	var fallback := _build_attempt(profile, requested_seed, profile.fallback_seed, -1)
	if _validate(profile, fallback) and _finalize_placements(profile, stage_data, fallback):
		push_warning("Stage generation used validated fallback seed %d for %s." % [profile.fallback_seed, profile.profile_id])
		return fallback
	push_error("Stage generation failed every deterministic attempt and fallback for %s: %s" % [profile.profile_id, str(fallback.metrics)])
	return null


static func _finalize_placements(
		profile: StageGenerationProfile,
		stage_data: StageData,
		layout: GeneratedStageLayout
) -> bool:
	if stage_data == null:
		return true
	if not stage_data.mechanism_loadout.is_empty():
		var placements := MechanismPlacementGenerator.generate(stage_data, layout)
		if placements.size() != stage_data.mechanism_loadout.size():
			layout.metrics["rejection"] = "mechanism_placement"
			return false
		layout.mechanism_placements = placements
	layout.decoration_placements = _generate_decorations(stage_data, layout)
	if layout.decoration_placements.size() != _decoration_count(stage_data.stage_number):
		layout.metrics["rejection"] = "decoration_placement"
		return false
	return _exclude_mechanism_footprints(profile, layout)


static func _exclude_mechanism_footprints(
		profile: StageGenerationProfile,
		layout: GeneratedStageLayout
) -> bool:
	const MASK_SIZE := 512
	var eligible_count := 0
	for pixel_y in range(MASK_SIZE):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, float(pixel_y) / float(MASK_SIZE - 1))
		for pixel_x in range(MASK_SIZE):
			var index := pixel_y * MASK_SIZE + pixel_x
			if layout.eligible_mask[index] < 128:
				continue
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, float(pixel_x) / float(MASK_SIZE - 1))
			var excluded := false
			for placement in layout.mechanism_placements:
				var exclusion_radius := placement.mechanism_data.trigger_radius + 0.75
				if placement.local_xz.distance_squared_to(Vector2(local_x, local_z)) <= exclusion_radius * exclusion_radius:
					excluded = true
					break
			if not excluded:
				for decoration in layout.decoration_placements:
					if decoration.local_xz.distance_squared_to(Vector2(local_x, local_z)) <= 2.25:
						excluded = true
						break
			if excluded:
				layout.eligible_mask[index] = 0
			else:
				eligible_count += 1
	var eligible_ratio := float(eligible_count) / float(MASK_SIZE * MASK_SIZE)
	layout.metrics["eligible_ratio_after_mechanisms"] = eligible_ratio
	if eligible_ratio < profile.eligible_ratio_range.x:
		layout.metrics["rejection"] = "eligible_ratio_after_mechanisms"
		return false
	return true


static func _generate_decorations(
		stage_data: StageData,
		layout: GeneratedStageLayout
) -> Array[DecorationPlacement]:
	var candidates: Array[Vector2] = []
	var sample_size := layout.sample_size()
	for z_index in range(2, sample_size.y - 2):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, float(z_index) / float(layout.cell_count.y))
		for x_index in range(2, sample_size.x - 2):
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, float(x_index) / float(layout.cell_count.x))
			if layout.height_at_local(local_x, local_z) < 1.1:
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
				if local_xz.distance_to(mechanism.local_xz) < mechanism.mechanism_data.trigger_radius + 6.0:
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


static func _decoration_count(stage_number: int) -> int:
	match stage_number:
		2:
			return 14
		3:
			return 18
		_:
			return 10


static func _build_attempt(
		profile: StageGenerationProfile,
		requested_seed: int,
		attempt_seed: int,
		attempt_index: int
) -> GeneratedStageLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = attempt_seed
	var generated_routes: Array[PackedVector3Array] = []
	var route_widths := PackedFloat32Array()
	for route_profile in profile.routes:
		var generated_points := PackedVector3Array()
		for source_point in route_profile.control_points:
			generated_points.append(Vector3(
				source_point.x + rng.randf_range(-profile.route_x_jitter, profile.route_x_jitter),
				source_point.y + rng.randf_range(-profile.route_height_jitter, profile.route_height_jitter),
				source_point.z
			))
		generated_routes.append(generated_points)
		route_widths.append(route_profile.width)

	var lobe_offsets: Array[Vector3] = []
	for _index in range(3):
		lobe_offsets.append(Vector3(
			rng.randf_range(-5.0, 5.0),
			rng.randf_range(-2.0, 2.0),
			rng.randf_range(-4.0, 4.0)
		))
	var noise := FastNoiseLite.new()
	noise.seed = attempt_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.45

	var size := profile.cell_count + Vector2i.ONE
	var heights := PackedFloat32Array()
	heights.resize(size.x * size.y)
	for z_index in range(size.y):
		var local_z := lerpf(profile.local_bounds.position.y, profile.local_bounds.end.y, float(z_index) / float(profile.cell_count.y))
		for x_index in range(size.x):
			var local_x := lerpf(profile.local_bounds.position.x, profile.local_bounds.end.x, float(x_index) / float(profile.cell_count.x))
			heights[z_index * size.x + x_index] = _synthesize_height(
				profile, generated_routes, route_widths, lobe_offsets, noise, local_x, local_z
			)
	_smooth_invalid_slopes(profile, heights, generated_routes)

	var layout := GeneratedStageLayout.new()
	layout.profile_id = profile.profile_id
	layout.profile_version = profile.profile_version
	layout.terrain_seed = requested_seed
	layout.accepted_seed = attempt_seed
	layout.generation_attempt = attempt_index
	layout.cell_count = profile.cell_count
	layout.local_bounds = profile.local_bounds
	layout.heights = heights
	layout.route_spines = generated_routes
	layout.route_widths = route_widths
	layout.checksum = _height_checksum(heights)
	return layout


static func _synthesize_height(
		profile: StageGenerationProfile,
		routes: Array[PackedVector3Array],
		widths: PackedFloat32Array,
		lobe_offsets: Array[Vector3],
		noise: FastNoiseLite,
		x: float,
		z: float
) -> float:
	var central := _gaussian_lobe(x, z, Vector2(0.0, -14.0), Vector2(68.0, 58.0), profile.nominal_peak, lobe_offsets[0])
	var left := _gaussian_lobe(x, z, Vector2(-42.0, 2.0), Vector2(46.0, 48.0), profile.nominal_peak * 0.72, lobe_offsets[1])
	var right := _gaussian_lobe(x, z, Vector2(42.0, 2.0), Vector2(46.0, 48.0), profile.nominal_peak * 0.68, lobe_offsets[2])
	var height := maxf(central, maxf(left, right))
	var strongest_influence := 0.0
	var shoulder_height := 0.0
	for route_index in range(routes.size()):
		var route_sample := _route_sample(routes[route_index], z)
		var distance := absf(x - route_sample.x)
		var width := widths[route_index]
		var influence := 1.0 - smoothstep(0.45 * width, 0.75 * width, distance)
		if influence > strongest_influence:
			strongest_influence = influence
			height = lerpf(height, route_sample.y, influence)
		var shoulder_distance := distance - 0.70 * width
		var shoulder_sigma := maxf(0.18 * width, 0.1)
		shoulder_height = maxf(shoulder_height, profile.shoulder_amplitude * exp(-pow(shoulder_distance / shoulder_sigma, 2.0)))
	height += shoulder_height * (1.0 - strongest_influence)
	height += noise.get_noise_2d(x, z) * profile.noise_amplitude * (1.0 - 0.65 * strongest_influence)
	var rounded := roundf(height / 3.0) * 3.0
	height = lerpf(height, rounded, lerpf(0.32, 0.12, strongest_influence))
	for shelf_index in range(profile.shelf_route_indices.size()):
		var shelf_route := profile.shelf_route_indices[shelf_index]
		var shelf_center := _route_point_at_t(routes[shelf_route], profile.shelf_route_positions[shelf_index])
		var shelf_radius := profile.shelf_radii[shelf_index]
		var shelf_distance := Vector2(x, z).distance_to(Vector2(shelf_center.x, shelf_center.z))
		var shelf_influence := 1.0 - smoothstep(0.25 * shelf_radius, shelf_radius, shelf_distance)
		height = lerpf(height, shelf_center.y, shelf_influence)
	var distance_to_edge := minf(
		minf(x - profile.local_bounds.position.x, profile.local_bounds.end.x - x),
		minf(z - profile.local_bounds.position.y, profile.local_bounds.end.y - z)
	)
	height *= smoothstep(0.0, 12.0, distance_to_edge)
	return clampf(height, 0.0, minf(90.0, profile.accepted_height_range.y))


static func _gaussian_lobe(
		x: float,
		z: float,
		center: Vector2,
		radii: Vector2,
		peak: float,
		offset: Vector3
) -> float:
	var dx := (x - center.x - offset.x) / radii.x
	var dz := (z - center.y - offset.z) / radii.y
	return (peak + offset.y) * exp(-(dx * dx + dz * dz))


static func _route_sample(route: PackedVector3Array, z: float) -> Vector2:
	if z <= route[0].z:
		return Vector2(route[0].x, route[0].y)
	for index in range(route.size() - 1):
		var start := route[index]
		var finish := route[index + 1]
		if z <= finish.z:
			var t := inverse_lerp(start.z, finish.z, z)
			var eased := smoothstep(0.0, 1.0, t)
			return Vector2(lerpf(start.x, finish.x, eased), lerpf(start.y, finish.y, eased))
	var last := route[route.size() - 1]
	return Vector2(last.x, last.y)


static func _route_point_at_t(route: PackedVector3Array, normalized_position: float) -> Vector3:
	var scaled := clampf(normalized_position, 0.0, 1.0) * float(route.size() - 1)
	var first := mini(floori(scaled), route.size() - 1)
	var second := mini(first + 1, route.size() - 1)
	return route[first].lerp(route[second], scaled - float(first))


static func _smooth_invalid_slopes(
		profile: StageGenerationProfile,
		heights: PackedFloat32Array,
		routes: Array[PackedVector3Array]
) -> void:
	var size := profile.cell_count + Vector2i.ONE
	var step_x := profile.local_bounds.size.x / float(profile.cell_count.x)
	var step_z := profile.local_bounds.size.y / float(profile.cell_count.y)
	var pinned := {}
	for route in routes:
		for point in route:
			var px := roundi(inverse_lerp(profile.local_bounds.position.x, profile.local_bounds.end.x, point.x) * profile.cell_count.x)
			var pz := roundi(inverse_lerp(profile.local_bounds.position.y, profile.local_bounds.end.y, point.z) * profile.cell_count.y)
			pinned[pz * size.x + px] = true
	for _pass in range(2):
		var source := heights.duplicate()
		for z_index in range(1, size.y - 1):
			for x_index in range(1, size.x - 1):
				var index := z_index * size.x + x_index
				if pinned.has(index):
					continue
				var dx := (source[index + 1] - source[index - 1]) / (2.0 * step_x)
				var dz := (source[index + size.x] - source[index - size.x]) / (2.0 * step_z)
				var slope := rad_to_deg(atan(sqrt(dx * dx + dz * dz)))
				if slope <= P95_ROUTE_SLOPE_DEGREES:
					continue
				var average := 0.25 * (source[index - 1] + source[index + 1] + source[index - size.x] + source[index + size.x])
				heights[index] = lerpf(source[index], average, 0.22)


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
	var size := layout.sample_size()
	for x in range(size.x):
		if layout.heights[x] > 1.0 or layout.heights[(size.y - 1) * size.x + x] > 1.0:
			layout.metrics["rejection"] = "edge_height"
			return false
	for z in range(size.y):
		if layout.heights[z * size.x] > 1.0 or layout.heights[z * size.x + size.x - 1] > 1.0:
			layout.metrics["rejection"] = "edge_height"
			return false
	var reversal_count := _meaningful_reversals(layout.route_spines[0])
	layout.metrics["reversals"] = reversal_count
	if reversal_count < profile.minimum_reversals or reversal_count > profile.maximum_reversals:
		layout.metrics["rejection"] = "reversals"
		return false
	var route_slopes := PackedFloat32Array()
	var steepest_route := -1
	var steepest_sample := -1
	var steepest_point := Vector3.ZERO
	var steepest_slope := -INF
	for route_index in range(layout.route_spines.size()):
		var route := layout.route_spines[route_index]
		for sample_index in range(65):
			var sample := layout.route_position(route_index, float(sample_index) / 64.0)
			var distance_to_edge := minf(
				minf(sample.x - layout.local_bounds.position.x, layout.local_bounds.end.x - sample.x),
				minf(sample.z - layout.local_bounds.position.y, layout.local_bounds.end.y - sample.z)
			)
			if distance_to_edge < 15.0:
				continue
			var slope := rad_to_deg(acos(clampf(layout.normal_at_local(sample.x, sample.z).y, -1.0, 1.0)))
			route_slopes.append(slope)
			if slope > steepest_slope:
				steepest_slope = slope
				steepest_route = route_index
				steepest_sample = sample_index
				steepest_point = sample
	route_slopes.sort()
	var p95_index := clampi(floori(float(route_slopes.size() - 1) * 0.95), 0, route_slopes.size() - 1)
	layout.metrics["maximum_route_slope"] = route_slopes[-1]
	layout.metrics["p95_route_slope"] = route_slopes[p95_index]
	layout.metrics["steepest_route"] = steepest_route
	layout.metrics["steepest_sample"] = steepest_sample
	layout.metrics["steepest_point"] = steepest_point
	if route_slopes[-1] > MAX_ROUTE_SLOPE_DEGREES or route_slopes[p95_index] > P95_ROUTE_SLOPE_DEGREES:
		layout.metrics["rejection"] = "route_slope"
		return false
	var eligible_result := _build_eligible_mask(layout)
	var eligible_mask: PackedByteArray = eligible_result.bytes
	var eligible_ratio := float(eligible_result.count) / float(512 * 512)
	layout.metrics["eligible_ratio"] = eligible_ratio
	if eligible_ratio < profile.eligible_ratio_range.x or eligible_ratio > profile.eligible_ratio_range.y:
		layout.metrics["rejection"] = "eligible_ratio"
		return false
	layout.eligible_mask = eligible_mask
	layout.metrics = {
		"maximum_height": maximum_height,
		"reversals": reversal_count,
		"maximum_route_slope": route_slopes[-1],
		"p95_route_slope": route_slopes[p95_index],
		"eligible_ratio": eligible_ratio,
		"triangles": profile.cell_count.x * profile.cell_count.y * 2,
	}
	return true


static func _build_eligible_mask(layout: GeneratedStageLayout) -> Dictionary:
	const MASK_SIZE := 512
	const INSET := 14
	var mask := PackedByteArray()
	mask.resize(MASK_SIZE * MASK_SIZE)
	var size := layout.sample_size()
	var normal_y := PackedFloat32Array()
	normal_y.resize(layout.heights.size())
	var step_x := layout.local_bounds.size.x / float(layout.cell_count.x)
	var step_z := layout.local_bounds.size.y / float(layout.cell_count.y)
	for z in range(size.y):
		var back_z := maxi(z - 1, 0)
		var front_z := mini(z + 1, size.y - 1)
		for x in range(size.x):
			var left_x := maxi(x - 1, 0)
			var right_x := mini(x + 1, size.x - 1)
			var dx_denominator := maxf(float(right_x - left_x) * step_x, step_x)
			var dz_denominator := maxf(float(front_z - back_z) * step_z, step_z)
			var dx := (layout.heights[z * size.x + right_x] - layout.heights[z * size.x + left_x]) / dx_denominator
			var dz := (layout.heights[front_z * size.x + x] - layout.heights[back_z * size.x + x]) / dz_denominator
			normal_y[z * size.x + x] = Vector3(-dx, 1.0, -dz).normalized().y
	var eligible_samples := PackedByteArray()
	eligible_samples.resize(layout.heights.size())
	for z in range(size.y):
		var local_z := lerpf(layout.local_bounds.position.y, layout.local_bounds.end.y, float(z) / float(layout.cell_count.y))
		var route_centers := PackedFloat32Array()
		for route in layout.route_spines:
			route_centers.append(_route_sample(route, local_z).x)
		for x in range(size.x):
			var sample_index := z * size.x + x
			if layout.heights[sample_index] <= 1.0 or normal_y[sample_index] < 0.529919:
				continue
			var local_x := lerpf(layout.local_bounds.position.x, layout.local_bounds.end.x, float(x) / float(layout.cell_count.x))
			for route_index in range(route_centers.size()):
				if absf(local_x - route_centers[route_index]) <= 0.75 * layout.route_widths[route_index]:
					eligible_samples[sample_index] = 255
					break
	var count := 0
	for pixel_y in range(INSET, MASK_SIZE - INSET):
		var sample_z := clampi(roundi(float(pixel_y) / float(MASK_SIZE - 1) * float(layout.cell_count.y)), 0, layout.cell_count.y)
		var sample_row := sample_z * size.x
		var mask_row := pixel_y * MASK_SIZE
		for pixel_x in range(INSET, MASK_SIZE - INSET):
			var sample_x := clampi(roundi(float(pixel_x) / float(MASK_SIZE - 1) * float(layout.cell_count.x)), 0, layout.cell_count.x)
			if eligible_samples[sample_row + sample_x] >= 128:
				mask[mask_row + pixel_x] = 255
				count += 1
	return {"bytes": mask, "count": count}


static func _meaningful_reversals(route: PackedVector3Array) -> int:
	var previous_sign := 0
	var reversals := 0
	for index in range(route.size() - 1):
		var start := route[index]
		var finish := route[index + 1]
		var grade_degrees := rad_to_deg(atan2(finish.y - start.y, finish.z - start.z))
		if absf(grade_degrees) < 2.0:
			continue
		var current_sign := signi(grade_degrees)
		if previous_sign != 0 and current_sign != previous_sign:
			reversals += 1
		previous_sign = current_sign
	return reversals


static func _height_checksum(heights: PackedFloat32Array) -> int:
	var hash: int = 2166136261
	for height in heights:
		var quantized := roundi(height * 1000.0)
		for shift in [0, 8, 16, 24]:
			hash = hash ^ ((quantized >> shift) & 0xff)
			hash = int((hash * 16777619) & 0xffffffff)
	return hash
