class_name ContainmentDomainProof
extends RefCounted

## Conservative first-flight containment proof for the complete continuous aim
## domain. When this envelope passes, no canonical tuple can reach a bounds
## face before the apron or backstop, so the exact at-risk lattice is empty.

static func evaluate(cannon: CannonController, spec: ContainmentSpec) -> Dictionary:
	if cannon == null or not cannon.is_node_ready() or cannon.projectile_data == null \
			or spec == null or not spec.is_valid():
		return {"valid": false, "rejection": &"invalid_input"}
	var radius := cannon.projectile_data.radius
	var muzzle_minimum := Vector3(INF, INF, INF)
	var muzzle_maximum := Vector3(-INF, -INF, -INF)
	for yaw in _muzzle_extrema_yaws():
		for elevation in _muzzle_extrema_elevations():
			var origin := cannon.get_launch_origin_for(yaw, elevation)
			muzzle_minimum = muzzle_minimum.min(origin)
			muzzle_maximum = muzzle_maximum.max(origin)

	var gravity_magnitude := float(ProjectSettings.get_setting(
		"physics/3d/default_gravity",
		9.8
	))
	var gravity_direction := Vector3(ProjectSettings.get_setting(
		"physics/3d/default_gravity_vector",
		Vector3.DOWN
	)).normalized()
	if gravity_magnitude <= 0.0 or not gravity_direction.is_equal_approx(Vector3.DOWN):
		return {"valid": false, "rejection": &"invalid_gravity"}
	var maximum_vertical_speed := cannon.projectile_data.maximum_launch_speed \
			* sin(deg_to_rad(AimTuple.MAXIMUM_ELEVATION_DEGREES))
	var maximum_apex_y := muzzle_maximum.y + _damped_vertical_displacement(
		maximum_vertical_speed,
		gravity_magnitude,
		cannon.projectile_data.linear_damp
	)

	var wall_bounds := spec.backstop_bounds()
	var rear_contact_center_z := spec.backstop_front_z() + radius
	var maximum_origin_abs_x := maxf(absf(muzzle_minimum.x), absf(muzzle_maximum.x))
	# Late-stage targets intentionally use a wider horizontal fan than the rear
	# wall alone can span. The implicit side walls catch lateral travel before a
	# projectile can reach the fixed containment AABB edge; the rear wall remains
	# the only wall at the visible mountain join.
	var side_wall_inner_half_width := minf(
		absf(spec.side_wall_center(-1).x + spec.side_wall_size().x * 0.5),
		absf(spec.side_wall_center(1).x - spec.side_wall_size().x * 0.5)
	)
	var maximum_rear_abs_x := maximum_origin_abs_x
	var rear_lateral_clearance := side_wall_inner_half_width - radius - maximum_origin_abs_x
	var upper_clearance := wall_bounds.end.y - radius - maximum_apex_y
	var apron_contact_center_y := spec.apron_minimum_y + radius
	var wall_bottom_overlap := apron_contact_center_y - (wall_bounds.position.y + radius)
	var lower_clearance := apron_contact_center_y \
			- (spec.containment_bounds.position.y + radius)
	var rear_clearance := rear_contact_center_z \
			- (spec.containment_bounds.position.z + radius)
	var front_clearance := spec.containment_bounds.end.z - radius - muzzle_maximum.z

	var all_launches_move_rearward := true
	for yaw in _muzzle_extrema_yaws():
		for elevation in _muzzle_extrema_elevations():
			if CannonBallistics.launch_direction(yaw, elevation).z >= 0.0:
				all_launches_move_rearward = false

	var apron_covers_side_and_front_bounds := is_equal_approx(
		spec.apron_xz_bounds.position.x,
		spec.containment_bounds.position.x
	) and is_equal_approx(
		spec.apron_xz_bounds.end.x,
		spec.containment_bounds.end.x
	) and is_equal_approx(
		spec.apron_xz_bounds.end.y,
		spec.containment_bounds.end.z
	)
	var side_wall_bounds_valid := spec.containment_bounds.encloses( \
		spec.side_wall_bounds(-1) \
	) and spec.containment_bounds.encloses(spec.side_wall_bounds(1))
	var valid := rear_lateral_clearance >= 0.0 \
			and upper_clearance >= 0.0 \
			and wall_bottom_overlap >= 0.0 \
			and lower_clearance >= 0.0 \
			and rear_clearance >= 0.0 \
			and front_clearance >= 0.0 \
			and all_launches_move_rearward \
			and apron_covers_side_and_front_bounds \
			and side_wall_bounds_valid
	return {
		"valid": valid,
		"rejection": &"" if valid else &"continuous_envelope",
		"muzzle_minimum": muzzle_minimum,
		"muzzle_maximum": muzzle_maximum,
		"maximum_apex_y": maximum_apex_y,
		"maximum_rear_abs_x": maximum_rear_abs_x,
		"rear_lateral_clearance": rear_lateral_clearance,
		"side_wall_bounds_valid": side_wall_bounds_valid,
		"upper_clearance": upper_clearance,
		"wall_bottom_overlap": wall_bottom_overlap,
		"lower_clearance": lower_clearance,
		"rear_clearance": rear_clearance,
		"front_clearance": front_clearance,
		"all_launches_move_rearward": all_launches_move_rearward,
		"apron_covers_side_and_front_bounds": apron_covers_side_and_front_bounds,
		# The continuous envelope dominates every 0.1/0.1/1 canonical tuple.
		# A passing proof therefore leaves no tuple requiring a bounds-face
		# predictor exception check; any failed inequality rejects the proof.
		"exact_lattice_candidate_count": 0 if valid else -1,
	}


static func _damped_vertical_displacement(
		initial_speed: float,
		gravity_magnitude: float,
		linear_damp: float
) -> float:
	# Match TrajectoryPredictor's fixed-step recurrence rather than using the
	# undamped v²/2g apex. This is intentionally conservative: it advances until
	# the vertical velocity turns downward and records the largest sampled y.
	const STEP := 1.0 / 60.0
	var velocity := initial_speed
	var displacement := 0.0
	var maximum := 0.0
	for _step in range(2400):
		velocity *= maxf(0.0, 1.0 - linear_damp * STEP)
		velocity -= gravity_magnitude * STEP
		displacement += velocity * STEP
		maximum = maxf(maximum, displacement)
		if velocity <= 0.0 and displacement >= maximum - 0.0001:
			break
	return maximum


static func _muzzle_extrema_yaws() -> PackedFloat32Array:
	return PackedFloat32Array([
		AimTuple.MINIMUM_YAW_DEGREES,
		0.0,
		AimTuple.MAXIMUM_YAW_DEGREES,
	])


static func _muzzle_extrema_elevations() -> PackedFloat32Array:
	return PackedFloat32Array([
		AimTuple.MINIMUM_ELEVATION_DEGREES,
		AimTuple.MAXIMUM_ELEVATION_DEGREES,
	])
