class_name MechanismPlacementGenerator
extends RefCounted

const MAX_PLACEMENT_SLOPE_DEGREES := 28.0
const ROUTE_EDGE_CLEARANCE := 3.0
const TERRAIN_RAY_FINAL_ALLOWANCE := 0.5


static func generate(stage_data: StageData, layout: GeneratedStageLayout) -> Array[MechanismPlacement]:
	var placements: Array[MechanismPlacement] = []
	if stage_data == null or layout == null or not layout.is_valid():
		return placements
	for mechanism_data in stage_data.mechanism_loadout:
		var placement := _place_exact(stage_data, layout, mechanism_data, placements)
		if placement == null:
			layout.metrics["placement_failed_kind"] = MechanismData.Kind.keys()[mechanism_data.kind]
			return []
		placements.append(placement)
	return placements


static func _place_exact(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		mechanism_data: MechanismData,
		existing: Array[MechanismPlacement]
) -> MechanismPlacement:
	var pad: GeneratedRouteNode
	for candidate in layout.route_graph.pad_nodes_for_kind(mechanism_data.kind):
		var occupied := false
		for existing_placement in existing:
			if existing_placement.local_xz.distance_to(Vector2(candidate.position.x, candidate.position.z)) < 1.0:
				occupied = true
				break
		if not occupied:
			pad = candidate
			break
	if pad == null:
		return null
	var route_index := pad.route_index
	var route_t := layout.route_graph.route_normalized_t_for_node(route_index, pad.id)
	if route_t < 0.0 or pad.pad_radius <= 0.0:
		return null
	var route_point := pad.position
	var local_xz := Vector2(route_point.x, route_point.z)
	var surface_point := Vector3(
		local_xz.x,
		layout.height_at_local(local_xz.x, local_xz.y),
		local_xz.y
	)
	var surface_normal := layout.normal_at_local(local_xz.x, local_xz.y)
	var downhill_tangent := layout.route_graph.route_tangent(route_index, route_t)
	if downhill_tangent.is_zero_approx():
		return null
	if not _placement_valid(
		stage_data, layout, mechanism_data.kind, route_index, pad.pad_radius,
		local_xz, surface_point, surface_normal, existing
	):
		return null

	var local_z_axis := -downhill_tangent
	var local_x_axis := surface_normal.cross(local_z_axis).normalized()
	if local_x_axis.is_zero_approx():
		return null
	local_z_axis = local_x_axis.cross(surface_normal).normalized()
	var transform := Transform3D(
		Basis(local_x_axis, surface_normal, local_z_axis),
		surface_point + surface_normal * 0.05
	)
	var placement := MechanismPlacement.new()
	placement.mechanism_data = mechanism_data
	placement.local_xz = local_xz
	placement.local_transform = transform
	placement.route_role = layout.route_graph.route_role(route_index)
	placement.route_index = route_index
	placement.route_t = route_t
	placement.downstream_tangent = downhill_tangent
	return placement


static func _placement_valid(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		kind: MechanismData.Kind,
		route_index: int,
		shelf_radius: float,
		local_xz: Vector2,
		local_point: Vector3,
		normal: Vector3,
		existing: Array[MechanismPlacement]
) -> bool:
	var slope := rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
	if slope > MAX_PLACEMENT_SLOPE_DEGREES:
		layout.metrics["placement_rejection"] = "slope"
		return false
	var physical_radius := effective_collision_radius(kind)
	# A typed mechanism pad widens its route locally; placement clearance belongs
	# to that support boundary, while the shelf gate below owns its flat center.
	var support_radius := maxf(
		layout.route_graph.route_width(route_index) * 0.5,
		shelf_radius
	)
	if support_radius - physical_radius < ROUTE_EDGE_CLEARANCE:
		layout.metrics["placement_rejection"] = "route_edge_clearance"
		return false
	if shelf_radius * 0.60 < physical_radius:
		layout.metrics["placement_rejection"] = "shelf_radius"
		return false
	for placement in existing:
		var required := physical_radius \
				+ effective_collision_radius(placement.mechanism_data.kind) + 1.0
		if local_xz.distance_to(placement.local_xz) < required:
			layout.metrics["placement_rejection"] = "mechanism_separation"
			return false
	var edge_distance := minf(
		minf(local_xz.x - layout.local_bounds.position.x, layout.local_bounds.end.x - local_xz.x),
		minf(local_xz.y - layout.local_bounds.position.y, layout.local_bounds.end.y - local_xz.y)
	)
	if edge_distance < physical_radius + ROUTE_EDGE_CLEARANCE:
		layout.metrics["placement_rejection"] = "terrain_edge_clearance"
		return false
	if not _camera_visibility_passes(
		stage_data, layout, local_point, effective_visual_diameter(kind)
	):
		layout.metrics["placement_rejection"] = "camera_visibility"
		return false
	return true


static func _camera_visibility_passes(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		local_point: Vector3,
		diameter: float
) -> bool:
	var local_normal := layout.normal_at_local(local_point.x, local_point.z)
	var world_point := stage_data.terrain_center + local_point + local_normal * diameter
	if _projected_horizontal_pixels(stage_data.aiming_camera_position, stage_data.aiming_camera_target, world_point, diameter) < 12.0:
		layout.metrics["visibility_rejection"] = "aiming_projected_size"
		return false
	if _projected_horizontal_pixels(stage_data.briefing_camera_position, stage_data.briefing_camera_target, world_point, diameter) < 16.0:
		layout.metrics["visibility_rejection"] = "briefing_projected_size"
		return false
	# Placement is already on the authoritative route surface. A camera ray is
	# intentionally not a generation gate: it was the source of invisible or
	# missing items when a wide camera looked through the closed mountain mass.
	return true


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


static func _terrain_ray_clear(
		stage_data: StageData,
		layout: GeneratedStageLayout,
		camera_position: Vector3,
		world_point: Vector3
) -> bool:
	var ray_length := camera_position.distance_to(world_point)
	if ray_length <= TERRAIN_RAY_FINAL_ALLOWANCE:
		return true
	for sample_index in range(1, 65):
		var t := float(sample_index) / 64.0
		var point := camera_position.lerp(world_point, t)
		if point.distance_to(world_point) <= TERRAIN_RAY_FINAL_ALLOWANCE:
			continue
		var local_xz := Vector2(
			point.x - stage_data.terrain_center.x,
			point.z - stage_data.terrain_center.z
		)
		if not layout.local_bounds.has_point(local_xz):
			continue
		var sample := layout.surface_sample_at_local(local_xz.x, local_xz.y, false)
		if sample.is_empty():
			continue
		var sample_point: Vector3 = sample.point
		var surface_y := stage_data.terrain_center.y + sample_point.y
		if surface_y > point.y + 0.05:
			return false
	return true


static func effective_collision_radius(kind: MechanismData.Kind) -> float:
	match kind:
		MechanismData.Kind.BURST:
			return 3.6
		MechanismData.Kind.SPLITTER:
			return 3.5
		_:
			return 3.8


static func effective_visual_diameter(kind: MechanismData.Kind) -> float:
	match kind:
		MechanismData.Kind.BURST:
			return 8.4
		MechanismData.Kind.SPLITTER:
			return 10.0
		_:
			return 10.4
