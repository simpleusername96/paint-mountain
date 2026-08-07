class_name AimCameraComposer
extends RefCounted

## Shared foreground-cannon composition. Terrain points remain authoritative;
## this selects one perspective pose and never scales world geometry.
const CAMERA_SIDE_OFFSET := 18.0
const CAMERA_HEIGHT_OFFSET := 10.0
const CAMERA_REAR_OFFSET := 32.0
const MAXIMUM_REAR_ADJUSTMENT := 25.0
const REAR_ADJUSTMENT_STEP := 5.0
const FRAME_MARGIN := 1.04


static func compose(
		interest_points: PackedVector3Array,
		terrain_bounds: AABB,
		cannon_transform: Transform3D,
		vertical_fov_degrees: float,
		aspect_ratio: float
) -> Dictionary:
	if interest_points.is_empty() or not terrain_bounds.has_volume() \
			or vertical_fov_degrees <= 0.0 or aspect_ratio <= 0.0:
		return {}
	var focus := Vector3(
		terrain_bounds.get_center().x,
		terrain_bounds.position.y + terrain_bounds.size.y * 0.43,
		terrain_bounds.get_center().z
	)
	var cannon_origin := cannon_transform.origin
	var rear_adjustment := 0.0
	while rear_adjustment <= MAXIMUM_REAR_ADJUSTMENT:
		var position := cannon_origin + Vector3(
			CAMERA_SIDE_OFFSET,
			CAMERA_HEIGHT_OFFSET,
			CAMERA_REAR_OFFSET + rear_adjustment
		)
		if TerrainCameraFramer.pose_fits_points(
			interest_points, position, focus, vertical_fov_degrees, aspect_ratio, FRAME_MARGIN
		):
			return {"position": position, "focus": focus}
		rear_adjustment += REAR_ADJUSTMENT_STEP
	return {
		"position": cannon_origin + Vector3(
			CAMERA_SIDE_OFFSET,
			CAMERA_HEIGHT_OFFSET,
			CAMERA_REAR_OFFSET + MAXIMUM_REAR_ADJUSTMENT
		),
		"focus": focus,
	}
