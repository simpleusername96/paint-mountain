class_name DefaultAimSolver
extends RefCounted

## Owns deterministic default-aim selection. Runtime uses one bounded search for
## a real first terrain hit near the visible target center; exhaustive witness
## sets remain optional QA evidence.

const YAW_OFFSETS := PackedFloat32Array([0.0, -6.0, 6.0, -12.0, 12.0, -18.0, 18.0])
const ELEVATIONS := PackedFloat32Array([24.0, 30.0, 36.0, 42.0, 48.0, 54.0, 60.0])
const POWERS := PackedInt32Array([52, 62, 72, 82, 92, 100])


static func find_runtime_aim(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		terrain_surface: TerrainSurface,
		layout: GeneratedStageLayout
) -> AimTuple:
	if space_state == null or cannon == null or cannon.projectile_data == null \
			or terrain_surface == null or layout == null \
			or not layout.has_valid_target_mask():
		return null
	var centroid_local := layout.target_centroid_local_xz()
	if not centroid_local.is_finite():
		return null
	var centroid_world := terrain_surface.to_global(Vector3(
		centroid_local.x,
		layout.height_at_local(centroid_local.x, centroid_local.y),
		centroid_local.y
	))
	var cannon_origin := cannon.global_position
	var horizontal_delta := Vector2(
		centroid_world.x - cannon_origin.x,
		centroid_world.z - cannon_origin.z
	)
	var center_yaw := rad_to_deg(atan2(horizontal_delta.x, -horizontal_delta.y))
	var best_aim: AimTuple
	var best_score := INF
	for yaw_offset in YAW_OFFSETS:
		var yaw := AimTuple.snap_angle(clampf(
			center_yaw + yaw_offset,
			AimTuple.MINIMUM_YAW_DEGREES,
			AimTuple.MAXIMUM_YAW_DEGREES
		))
		for elevation in ELEVATIONS:
			for power in POWERS:
				var aim := AimTuple.canonicalize(yaw, elevation, power)
				var origin := cannon.get_launch_origin_for(
					aim.yaw_degrees, aim.elevation_degrees
				)
				var velocity := CannonBallistics.launch_velocity(
					cannon.projectile_data,
					aim.yaw_degrees,
					aim.elevation_degrees,
					aim.power_percent
				)
				var prediction := TrajectoryPredictor.predict_motion(
					space_state,
					origin,
					velocity,
					cannon.projectile_data.radius,
					cannon.projectile_data.linear_damp,
					layout.containment.containment_bounds,
					TrajectoryPredictor.COLLISION_MASK,
					false
				)
				if prediction.kind != TrajectoryPrediction.Kind.COLLISION \
						or prediction.hit_identity == null \
						or prediction.hit_identity.contact_owner_id \
								!= TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
					continue
				var local_hit := terrain_surface.to_local(prediction.endpoint)
				var local_xz := Vector2(local_hit.x, local_hit.z)
				if not layout.is_target_local_xz(local_xz):
					continue
				var score := local_xz.distance_squared_to(centroid_local) \
						+ absf(aim.yaw_degrees - center_yaw) * 0.02 \
						+ absf(aim.elevation_degrees - 40.0) * 0.01
				if best_aim == null or score < best_score \
						or (is_equal_approx(score, best_score) \
								and _tuple_precedes(aim, best_aim)):
					best_aim = aim
					best_score = score
	return best_aim


static func select_witness_index(
		witnesses: Array[AimTuple],
		witness_impact_points: PackedVector3Array,
		target_centroid_xz: Vector2
) -> int:
	if witnesses.is_empty() or witnesses.size() != witness_impact_points.size() \
			or not target_centroid_xz.is_finite():
		return -1
	var best_index := -1
	var best_distance_squared := INF
	for index in range(witnesses.size()):
		var witness := witnesses[index]
		var impact := witness_impact_points[index]
		if witness == null or not witness.is_valid() or not impact.is_finite():
			return -1
		var distance_squared := Vector2(impact.x, impact.z).distance_squared_to(target_centroid_xz)
		if best_index < 0 or distance_squared < best_distance_squared:
			best_index = index
			best_distance_squared = distance_squared
		elif distance_squared == best_distance_squared \
				and _tuple_precedes(witness, witnesses[best_index]):
			best_index = index
	return best_index


static func _tuple_precedes(candidate: AimTuple, incumbent: AimTuple) -> bool:
	var candidate_key := [
		absf(candidate.yaw_degrees),
		candidate.elevation_degrees,
		candidate.power_percent,
		candidate.yaw_degrees,
	]
	var incumbent_key := [
		absf(incumbent.yaw_degrees),
		incumbent.elevation_degrees,
		incumbent.power_percent,
		incumbent.yaw_degrees,
	]
	for index in range(candidate_key.size()):
		if candidate_key[index] < incumbent_key[index]:
			return true
		if candidate_key[index] > incumbent_key[index]:
			return false
	return false
