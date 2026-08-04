class_name DefaultAimSolver
extends RefCounted

## Owns deterministic default-aim selection. Runtime uses one bounded search for
## a real first terrain hit near the visible target center; exhaustive witness
## sets remain optional QA evidence.

static func find_runtime_aim(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		terrain_surface: TerrainSurface,
		layout: GeneratedStageLayout
) -> AimTuple:
	if space_state == null or cannon == null or cannon.projectile_data == null \
			or terrain_surface == null or layout == null or not layout.is_valid() \
			or not layout.has_valid_target_mask():
		return null
	var target_sample := layout.target_sample_nearest_centroid()
	if target_sample.is_empty():
		return null
	var target_world_point := terrain_surface.to_global(target_sample.point as Vector3)
	var target_world_normal := (
		terrain_surface.global_transform.basis.inverse().transposed() \
				* (target_sample.normal as Vector3)
	).normalized()
	if not target_world_point.is_finite() or not target_world_normal.is_finite() \
			or target_world_normal.is_zero_approx():
		return null
	var solved := DirectReachabilityValidator.solve_one_target(
		space_state,
		cannon,
		layout,
		layout.containment.containment_bounds,
		target_world_point,
		target_world_normal,
		target_sample
	)
	if not bool(solved.get("valid", false)):
		return null
	var aim := solved.get("aim") as AimTuple
	var prediction := solved.get("prediction") as TrajectoryPrediction
	if aim == null or not aim.is_valid() \
			or not _prediction_matches_target(prediction, target_world_point, target_sample):
		return null
	return aim


static func _prediction_matches_target(
		prediction: TrajectoryPrediction,
		target_world_point: Vector3,
		target_sample: Dictionary
) -> bool:
	if prediction == null or prediction.kind != TrajectoryPrediction.Kind.COLLISION \
			or prediction.hit_identity == null:
		return false
	var identity := prediction.hit_identity
	return identity.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			and identity.terrain_cell == target_sample.cell \
			and identity.terrain_triangle == int(target_sample.triangle) \
			and prediction.endpoint.distance_to(target_world_point) \
					<= DirectReachabilityValidator.TARGET_DISTANCE_TOLERANCE


static func select_witness_index(
		witnesses: Array[AimTuple],
		witness_impact_points: PackedVector3Array,
		target_centroid_xz: Vector2
) -> int:
	return DirectReachabilityValidator.select_witness_index(
		witnesses,
		witness_impact_points,
		target_centroid_xz
	)
