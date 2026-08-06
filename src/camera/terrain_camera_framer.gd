class_name TerrainCameraFramer
extends RefCounted

const DEFAULT_MARGIN := 1.08
const FIT_DISTANCE_EPSILON := 0.05


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
	return framed_pose_around_points(
		_packed_bounds_corners(bounds),
		focus,
		authored_position,
		authored_focus,
		vertical_fov_degrees,
		aspect_ratio,
		margin
	)


static func framed_pose_around_points(
		points: PackedVector3Array,
		focus: Vector3,
		authored_position: Vector3,
		authored_focus: Vector3,
		vertical_fov_degrees: float,
		aspect_ratio: float,
		margin: float = DEFAULT_MARGIN
) -> Array[Vector3]:
	assert(not points.is_empty(), "Terrain camera framing requires at least one world point.")
	assert(focus.is_finite(), "Terrain camera framing requires a finite focus.")
	assert(vertical_fov_degrees > 1.0 and vertical_fov_degrees < 179.0, "Terrain camera framing requires a valid vertical FOV.")
	assert(aspect_ratio > 0.0 and margin >= 1.0, "Terrain camera framing requires a positive aspect and non-cropping margin.")
	var forward := _authored_forward(authored_position, authored_focus)
	var required_distance := maxf(
		_required_distance_around_points(
			points, focus, forward, vertical_fov_degrees, aspect_ratio, margin
		),
		1.0
	) + FIT_DISTANCE_EPSILON
	return [focus - forward * required_distance, focus]


## Uses the same frustum math as framed_pose_around so callers can preserve an
## authored pose whenever it already contains the requested bounds.
static func pose_fits_bounds(
		bounds: AABB,
		position: Vector3,
		focus: Vector3,
		vertical_fov_degrees: float,
		aspect_ratio: float,
		margin: float = DEFAULT_MARGIN
) -> bool:
	if not bounds.has_volume():
		return false
	return pose_fits_points(
		_packed_bounds_corners(bounds),
		position,
		focus,
		vertical_fov_degrees,
		aspect_ratio,
		margin
	)


static func pose_fits_points(
		points: PackedVector3Array,
		position: Vector3,
		focus: Vector3,
		vertical_fov_degrees: float,
		aspect_ratio: float,
		margin: float = DEFAULT_MARGIN
) -> bool:
	if points.is_empty() or not position.is_finite() or not focus.is_finite() \
			or vertical_fov_degrees <= 1.0 or vertical_fov_degrees >= 179.0 \
			or aspect_ratio <= 0.0 or margin < 1.0:
		return false
	var forward := _authored_forward(position, focus)
	var basis: Dictionary = _view_basis(forward)
	var view_forward: Vector3 = basis["forward"]
	var right: Vector3 = basis["right"]
	var up: Vector3 = basis["up"]
	var tangents: Dictionary = _frustum_tangents(vertical_fov_degrees, aspect_ratio)
	var horizontal_tangent: float = tangents["horizontal"]
	var vertical_tangent: float = tangents["vertical"]
	for point in points:
		var relative := point - position
		var depth := relative.dot(view_forward)
		if depth <= 0.0:
			return false
		if absf(relative.dot(right)) * margin > depth * horizontal_tangent:
			return false
		if absf(relative.dot(up)) * margin > depth * vertical_tangent:
			return false
	return true


static func _required_distance_around_points(
		points: PackedVector3Array,
		focus: Vector3,
		forward: Vector3,
		vertical_fov_degrees: float,
		aspect_ratio: float,
		margin: float = DEFAULT_MARGIN
) -> float:
	var basis: Dictionary = _view_basis(forward)
	var view_forward: Vector3 = basis["forward"]
	var right: Vector3 = basis["right"]
	var up: Vector3 = basis["up"]
	var tangents: Dictionary = _frustum_tangents(vertical_fov_degrees, aspect_ratio)
	var horizontal_tangent: float = tangents["horizontal"]
	var vertical_tangent: float = tangents["vertical"]
	var required_distance := 0.0
	for point in points:
		var relative := point - focus
		var forward_offset := relative.dot(view_forward)
		required_distance = maxf(required_distance, maxf(
			absf(relative.dot(right)) * margin / horizontal_tangent - forward_offset,
			absf(relative.dot(up)) * margin / vertical_tangent - forward_offset
		))
	return required_distance


static func _authored_forward(authored_position: Vector3, authored_focus: Vector3) -> Vector3:
	var forward := (authored_focus - authored_position).normalized()
	return Vector3(0.0, -0.2, -1.0).normalized() if forward.is_zero_approx() else forward


static func _view_basis(forward: Vector3) -> Dictionary:
	var reference_up := Vector3.FORWARD if absf(forward.dot(Vector3.UP)) > 0.98 else Vector3.UP
	var right := forward.cross(reference_up).normalized()
	return {"forward": forward, "right": right, "up": right.cross(forward).normalized()}


static func _frustum_tangents(vertical_fov_degrees: float, aspect_ratio: float) -> Dictionary:
	var vertical_half_fov := deg_to_rad(vertical_fov_degrees * 0.5)
	return {
		"vertical": tan(vertical_half_fov),
		"horizontal": tan(atan(tan(vertical_half_fov) * aspect_ratio)),
	}


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


static func _packed_bounds_corners(bounds: AABB) -> PackedVector3Array:
	var result := PackedVector3Array()
	for corner in bounds_corners(bounds):
		result.append(corner)
	return result
