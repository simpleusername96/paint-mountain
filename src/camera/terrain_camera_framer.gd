class_name TerrainCameraFramer
extends RefCounted

const DEFAULT_MARGIN := 1.08


static func framed_pose(
		bounds: AABB,
		authored_position: Vector3,
		authored_focus: Vector3,
		vertical_fov_degrees: float,
		aspect_ratio: float,
		margin: float = DEFAULT_MARGIN
) -> Array[Vector3]:
	return framed_pose_around(
		bounds,
		bounds.get_center(),
		authored_position,
		authored_focus,
		vertical_fov_degrees,
		aspect_ratio,
		margin
	)


static func framed_pose_around(
		bounds: AABB,
		focus: Vector3,
		authored_position: Vector3,
		authored_focus: Vector3,
		vertical_fov_degrees: float,
		aspect_ratio: float,
		margin: float = DEFAULT_MARGIN
) -> Array[Vector3]:
	assert(bounds.has_volume(), "Terrain camera framing requires non-empty render bounds.")
	assert(focus.is_finite(), "Terrain camera framing requires a finite focus.")
	assert(vertical_fov_degrees > 1.0 and vertical_fov_degrees < 179.0, "Terrain camera framing requires a valid vertical FOV.")
	assert(aspect_ratio > 0.0 and margin >= 1.0, "Terrain camera framing requires a positive aspect and non-cropping margin.")
	var forward := (authored_focus - authored_position).normalized()
	if forward.is_zero_approx():
		forward = Vector3(0.0, -0.2, -1.0).normalized()
	var reference_up := Vector3.FORWARD if absf(forward.dot(Vector3.UP)) > 0.98 else Vector3.UP
	var right := forward.cross(reference_up).normalized()
	var up := right.cross(forward).normalized()
	var vertical_half_fov := deg_to_rad(vertical_fov_degrees * 0.5)
	var horizontal_half_fov := atan(tan(vertical_half_fov) * aspect_ratio)
	var vertical_tangent := tan(vertical_half_fov)
	var horizontal_tangent := tan(horizontal_half_fov)
	var required_distance := 0.0
	for corner in bounds_corners(bounds):
		var relative := corner - focus
		var forward_offset := relative.dot(forward)
		required_distance = maxf(required_distance, maxf(
			absf(relative.dot(right)) / horizontal_tangent - forward_offset,
			absf(relative.dot(up)) / vertical_tangent - forward_offset
		))
	required_distance = maxf(required_distance * margin, 1.0)
	return [focus - forward * required_distance, focus]


static func bounds_corners(bounds: AABB) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for x_side in range(2):
		for y_side in range(2):
			for z_side in range(2):
				result.append(bounds.position + Vector3(
					bounds.size.x * float(x_side),
					bounds.size.y * float(y_side),
					bounds.size.z * float(z_side)
				))
	return result
