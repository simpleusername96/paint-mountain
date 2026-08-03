class_name SurfaceContactGapValidator
extends RefCounted

const TERRAIN_COLLISION_MASK := 1


static func can_bridge(
		terrain_surface: TerrainSurface,
		tuning: PaintSurfaceTuning,
		target_mask: PackedByteArray,
		from_contact: ProjectileContact,
		to_contact: ProjectileContact,
		missing_ticks: int,
		space_state: PhysicsDirectSpaceState3D
) -> bool:
	if terrain_surface == null or tuning == null or not tuning.is_valid() \
			or from_contact == null or to_contact == null or space_state == null:
		return false
	if missing_ticks <= 0 or missing_ticks > tuning.maximum_bridge_ticks \
			or missing_ticks != to_contact.physics_tick - from_contact.physics_tick - 1 \
			or not from_contact.has_stable_identity() \
			or not to_contact.has_stable_identity() \
			or not from_contact.same_collider_shape(to_contact):
		return false
	if not from_contact.world_position.is_finite() or not to_contact.world_position.is_finite() \
			or not from_contact.normal.is_finite() or not to_contact.normal.is_finite():
		return false
	if from_contact.contact_owner_id != TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			or to_contact.contact_owner_id != TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
		return false
	var chord_length := from_contact.world_position.distance_to(to_contact.world_position)
	if chord_length > tuning.maximum_bridge_chord:
		return false
	var expected_mask_size := tuning.mask_size * tuning.mask_size
	if target_mask.size() != expected_mask_size:
		return false
	var segment_count := maxi(1, ceili(chord_length / tuning.bridge_sample_spacing))
	var previous_normal := from_contact.normal
	var minimum_normal_dot := cos(deg_to_rad(tuning.maximum_normal_delta_degrees))
	for sample_index in range(segment_count + 1):
		var weight := float(sample_index) / float(segment_count)
		var chord_point := from_contact.world_position.lerp(to_contact.world_position, weight)
		var surface_point := terrain_surface.world_surface_point(Vector2(chord_point.x, chord_point.z))
		var surface_normal := terrain_surface.world_surface_normal(Vector2(chord_point.x, chord_point.z))
		if not _is_target_point(
			terrain_surface,
			tuning.mask_size,
			tuning.painted_threshold_byte,
			target_mask,
			surface_point
		):
			return false
		if absf((chord_point - surface_point).dot(surface_normal)) > tuning.surface_clearance:
			return false
		if previous_normal.dot(surface_normal) < minimum_normal_dot:
			return false
		if not _ray_returns_same_top(
			space_state,
			surface_point,
			tuning.verification_ray_span,
			from_contact.collider,
			from_contact.collider_shape_index
		):
			return false
		previous_normal = surface_normal
	return previous_normal.dot(to_contact.normal) >= minimum_normal_dot


static func is_target_contact(
		terrain_surface: TerrainSurface,
		tuning: PaintSurfaceTuning,
		target_mask: PackedByteArray,
		contact: ProjectileContact
) -> bool:
	return terrain_surface != null and tuning != null and contact != null \
			and contact.has_stable_identity() \
			and contact.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			and terrain_surface.is_top_collider(contact.collider) \
			and _is_target_point(
				terrain_surface,
				tuning.mask_size,
				tuning.painted_threshold_byte,
				target_mask,
				contact.world_position
			)


static func _is_target_point(
		terrain_surface: TerrainSurface,
		mask_size: int,
		threshold_byte: int,
		target_mask: PackedByteArray,
		world_point: Vector3
) -> bool:
	var layout := terrain_surface.layout_read_only()
	if layout == null or mask_size <= 0 or target_mask.size() != mask_size * mask_size:
		return false
	var local_point := terrain_surface.to_local(world_point)
	var local_xz := Vector2(local_point.x, local_point.z)
	if not layout.local_bounds.has_point(local_xz):
		return false
	var normalized := Vector2(
		(local_xz.x - layout.local_bounds.position.x) / layout.local_bounds.size.x,
		(local_xz.y - layout.local_bounds.position.y) / layout.local_bounds.size.y
	)
	var pixel := Vector2i(
		clampi(floori(normalized.x * mask_size), 0, mask_size - 1),
		clampi(floori(normalized.y * mask_size), 0, mask_size - 1)
	)
	return target_mask[pixel.y * mask_size + pixel.x] >= threshold_byte


static func _ray_returns_same_top(
		space_state: PhysicsDirectSpaceState3D,
		surface_point: Vector3,
		ray_span: float,
		expected_collider: Object,
		expected_shape_index: int
) -> bool:
	var half_span := Vector3.UP * (ray_span * 0.5)
	var query := PhysicsRayQueryParameters3D.create(
		surface_point + half_span,
		surface_point - half_span,
		TERRAIN_COLLISION_MASK
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == expected_collider \
			and int(hit.get("shape", -1)) == expected_shape_index
