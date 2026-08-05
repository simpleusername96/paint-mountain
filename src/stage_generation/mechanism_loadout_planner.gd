class_name MechanismLoadoutPlanner
extends RefCounted

const MAXIMUM_GLYPHS := 6
const FOOTPRINT_SAMPLE_COUNT := 16
const MAXIMUM_CENTER_SLOPE_DEGREES := 42.0
const MAXIMUM_NORMAL_VARIATION_DEGREES := 32.0
const GLYPH_EDGE_MARGIN := 0.75
const GLYPH_SEPARATION_MARGIN := 1.0
const MINIMUM_AIMING_DIAMETER_PIXELS := 12.0
const MINIMUM_BRIEFING_DIAMETER_PIXELS := 16.0


static func plan(
		stage_data: StageData,
		layout: GeneratedStageLayout
) -> Array[MechanismPlacement]:
	var empty: Array[MechanismPlacement] = []
	if stage_data == null or layout == null or not layout.is_valid():
		return empty
	if stage_data.mechanism_loadout.size() > MAXIMUM_GLYPHS:
		layout.metrics["placement_rejection"] = "glyph_count"
		return empty
	if stage_data.mechanism_loadout.is_empty():
		return empty
	var anchors := _build_generic_anchors(layout)
	if anchors.size() < stage_data.mechanism_loadout.size():
		layout.metrics["placement_rejection"] = "generic_anchor_count"
		return empty

	var candidate_sets: Array = []
	var request_order: Array[Dictionary] = []
	for request_index in range(stage_data.mechanism_loadout.size()):
		var mechanism_data := stage_data.mechanism_loadout[request_index]
		if mechanism_data == null or not mechanism_data.is_valid():
			layout.metrics["placement_rejection"] = "invalid_mechanism_data"
			return empty
		var candidates: Array[Dictionary] = []
		for anchor in anchors:
			var candidate := _candidate_for(stage_data, layout, mechanism_data, anchor)
			if not candidate.is_empty():
				candidates.append(candidate)
		candidates.sort_custom(_candidate_less)
		if candidates.is_empty():
			layout.metrics["placement_failed_kind"] = MechanismData.Kind.keys()[int(mechanism_data.canonical_kind())]
			layout.metrics["placement_rejection"] = "kind_suitability"
			return empty
		candidate_sets.append(candidates)
		request_order.append({
			"request_index": request_index,
			"candidate_count": candidates.size(),
			"kind": int(mechanism_data.canonical_kind()),
		})
	request_order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.candidate_count) != int(b.candidate_count):
			return int(a.candidate_count) < int(b.candidate_count)
		if int(a.kind) != int(b.kind):
			return int(a.kind) > int(b.kind)
		return int(a.request_index) < int(b.request_index)
	)

	var selected: Array = []
	selected.resize(stage_data.mechanism_loadout.size())
	if not _assign_candidates(0, request_order, candidate_sets, selected, {}):
		layout.metrics["placement_rejection"] = "glyph_separation_or_assignment"
		return empty
	var placements: Array[MechanismPlacement] = []
	for candidate in selected:
		placements.append(candidate.placement)
	return placements


static func _build_generic_anchors(layout: GeneratedStageLayout) -> Array[MechanismGlyphAnchor]:
	var anchors: Array[MechanismGlyphAnchor] = []
	for pad in layout.route_graph.pad_nodes():
		var route_t := layout.route_graph.route_normalized_t_for_node(pad.route_index, pad.id)
		var local_xz := Vector2(pad.position.x, pad.position.z)
		var sample := layout.surface_sample_at_local(local_xz.x, local_xz.y, false)
		var tangent := layout.route_graph.route_tangent(pad.route_index, route_t)
		if route_t < 0.0 or sample.is_empty() or tangent.is_zero_approx():
			continue
		var anchor := MechanismGlyphAnchor.new(
			pad.id,
			local_xz,
			sample.point,
			sample.normal,
			pad.route_index,
			layout.route_graph.route_role(pad.route_index) as StageRouteProfile.Role,
			route_t,
			tangent,
			maxf(pad.pad_radius, layout.route_graph.route_width(pad.route_index) * 0.5),
			pad.mechanism_kind
		)
		if anchor.is_valid():
			anchors.append(anchor)
	anchors.sort_custom(func(a: MechanismGlyphAnchor, b: MechanismGlyphAnchor) -> bool:
		return String(a.id) < String(b.id)
	)
	return anchors


static func _candidate_for(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		mechanism_data: MechanismData,
		anchor: MechanismGlyphAnchor
) -> Dictionary:
	if not _generic_suitability(stage_data, layout, mechanism_data, anchor):
		return {}
	var split_targets := PackedVector3Array()
	var uphill_tangent := Vector3.ZERO
	var kind_score := 0.0
	match mechanism_data.canonical_kind():
		MechanismData.Kind.SPLITTER:
			split_targets = _splitter_route_targets(layout, mechanism_data, anchor)
			if split_targets.size() != mechanism_data.child_count:
				return {}
			kind_score = _splitter_divergence_score(anchor.surface_point, split_targets)
		MechanismData.Kind.UPHILL_REBOUND:
			var witness := _uphill_witness(layout, mechanism_data, anchor)
			if witness.is_empty():
				return {}
			uphill_tangent = witness.tangent
			kind_score = float(witness.rise)
		_:
			kind_score = anchor.support_radius - mechanism_data.glyph_radius
	var forward := uphill_tangent if not uphill_tangent.is_zero_approx() else anchor.route_tangent
	var local_z_axis := -forward
	var local_x_axis := anchor.surface_normal.cross(local_z_axis).normalized()
	if local_x_axis.is_zero_approx():
		return {}
	local_z_axis = local_x_axis.cross(anchor.surface_normal).normalized()
	var placement := MechanismPlacement.new()
	placement.mechanism_data = mechanism_data
	placement.anchor_id = anchor.id
	placement.local_xz = anchor.local_xz
	placement.local_transform = Transform3D(
		Basis(local_x_axis, anchor.surface_normal, local_z_axis),
		anchor.surface_point
	)
	placement.route_role = anchor.route_role
	placement.route_index = anchor.route_index
	placement.route_t = anchor.route_t
	placement.downstream_tangent = forward
	placement.splitter_route_targets = split_targets
	placement.uphill_tangent = uphill_tangent
	var legacy_hint_bonus := 0.25 if anchor.legacy_kind_hint == int(mechanism_data.kind) else 0.0
	return {
		"anchor_id": anchor.id,
		"score": kind_score + legacy_hint_bonus,
		"placement": placement,
	}


static func _generic_suitability(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		mechanism_data: MechanismData,
		anchor: MechanismGlyphAnchor
) -> bool:
	var radius := mechanism_data.glyph_radius
	if anchor.support_radius < radius + GLYPH_EDGE_MARGIN:
		return false
	if not layout.local_bounds.grow(-(radius + GLYPH_EDGE_MARGIN)).has_point(anchor.local_xz):
		return false
	var center_slope := rad_to_deg(acos(clampf(anchor.surface_normal.y, -1.0, 1.0)))
	if center_slope > MAXIMUM_CENTER_SLOPE_DEGREES:
		return false
	var minimum_normal_dot := cos(deg_to_rad(MAXIMUM_NORMAL_VARIATION_DEGREES))
	for sample_index in range(FOOTPRINT_SAMPLE_COUNT):
		var angle := TAU * float(sample_index) / float(FOOTPRINT_SAMPLE_COUNT)
		var point := anchor.local_xz + Vector2.from_angle(angle) * radius
		var sample := layout.surface_sample_at_local(point.x, point.y, false)
		if sample.is_empty() or anchor.surface_normal.dot(Vector3(sample.normal)) < minimum_normal_dot:
			return false
	var diameter := radius * 2.0
	var world_point := stage_data.terrain_center + anchor.surface_point
	if _projected_horizontal_pixels(
		stage_data.aiming_camera_position,
		stage_data.aiming_camera_target,
		world_point,
		diameter
	) < MINIMUM_AIMING_DIAMETER_PIXELS:
		return false
	return _projected_horizontal_pixels(
		stage_data.briefing_camera_position,
		stage_data.briefing_camera_target,
		world_point,
		diameter
	) >= MINIMUM_BRIEFING_DIAMETER_PIXELS


static func _splitter_route_targets(
		layout: GeneratedStageLayout,
		mechanism_data: MechanismData,
		anchor: MechanismGlyphAnchor
) -> PackedVector3Array:
	var targets := PackedVector3Array()
	var route_indices := PackedInt32Array()
	for role in mechanism_data.child_target_route_roles:
		var route_index := layout.route_graph.route_index_for_role(role)
		if route_index < 0 or route_indices.has(route_index):
			return PackedVector3Array()
		var route_point := layout.route_graph.route_position(route_index, mechanism_data.child_target_t)
		var sample := layout.surface_sample_at_local(route_point.x, route_point.z, false)
		if sample.is_empty():
			return PackedVector3Array()
		route_indices.append(route_index)
		targets.append(sample.point)
	for first_index in range(targets.size()):
		for second_index in range(first_index + 1, targets.size()):
			var first_xz := Vector2(targets[first_index].x, targets[first_index].z)
			var second_xz := Vector2(targets[second_index].x, targets[second_index].z)
			if first_xz.distance_to(second_xz) < mechanism_data.glyph_radius * 1.2:
				return PackedVector3Array()
			var first_direction := (targets[first_index] - anchor.surface_point).normalized()
			var second_direction := (targets[second_index] - anchor.surface_point).normalized()
			if first_direction.dot(second_direction) > 0.94:
				return PackedVector3Array()
	return targets


static func _uphill_witness(
		layout: GeneratedStageLayout,
		mechanism_data: MechanismData,
		anchor: MechanismGlyphAnchor
) -> Dictionary:
	var best_rise := -INF
	var best_point := Vector3.ZERO
	for sample_index in range(12):
		var angle := TAU * float(sample_index) / 12.0
		var local_xz := anchor.local_xz \
				+ Vector2.from_angle(angle) * mechanism_data.uphill_sample_distance
		var sample := layout.surface_sample_at_local(local_xz.x, local_xz.y, false)
		if sample.is_empty():
			continue
		var rise := float(sample.point.y) - anchor.surface_point.y
		if rise > best_rise:
			best_rise = rise
			best_point = sample.point
	if best_rise < mechanism_data.minimum_uphill_rise:
		return {}
	var delta := best_point - anchor.surface_point
	var tangent := delta - anchor.surface_normal * delta.dot(anchor.surface_normal)
	if tangent.is_zero_approx():
		return {}
	return {"tangent": tangent.normalized(), "rise": best_rise}


static func _splitter_divergence_score(origin: Vector3, targets: PackedVector3Array) -> float:
	var score := 0.0
	for first_index in range(targets.size()):
		for second_index in range(first_index + 1, targets.size()):
			var a := (targets[first_index] - origin).normalized()
			var b := (targets[second_index] - origin).normalized()
			score += 1.0 - a.dot(b)
	return score


static func _assign_candidates(
		order_index: int,
		request_order: Array[Dictionary],
		candidate_sets: Array,
		selected: Array,
		used_anchor_ids: Dictionary
) -> bool:
	if order_index >= request_order.size():
		return true
	var request_index := int(request_order[order_index].request_index)
	for candidate: Dictionary in candidate_sets[request_index]:
		if used_anchor_ids.has(candidate.anchor_id):
			continue
		var placement := candidate.placement as MechanismPlacement
		if not _separated_from_selected(placement, selected):
			continue
		selected[request_index] = candidate
		used_anchor_ids[candidate.anchor_id] = true
		if _assign_candidates(order_index + 1, request_order, candidate_sets, selected, used_anchor_ids):
			return true
		used_anchor_ids.erase(candidate.anchor_id)
		selected[request_index] = null
	return false


static func _separated_from_selected(
		candidate: MechanismPlacement,
		selected: Array
) -> bool:
	for entry in selected:
		if entry == null:
			continue
		var existing := entry.placement as MechanismPlacement
		var required := candidate.mechanism_data.glyph_radius \
				+ existing.mechanism_data.glyph_radius + GLYPH_SEPARATION_MARGIN
		if candidate.local_xz.distance_to(existing.local_xz) < required:
			return false
	return true


static func _candidate_less(a: Dictionary, b: Dictionary) -> bool:
	if not is_equal_approx(float(a.score), float(b.score)):
		return float(a.score) > float(b.score)
	return String(a.anchor_id) < String(b.anchor_id)


static func _projected_horizontal_pixels(
		camera_position: Vector3,
		camera_target: Vector3,
		world_point: Vector3,
		diameter: float
) -> float:
	var forward := (camera_target - camera_position).normalized()
	var depth := (world_point - camera_position).dot(forward)
	if depth <= 0.01:
		return 0.0
	return diameter / (2.0 * tan(deg_to_rad(25.0)) * depth) * 1280.0
