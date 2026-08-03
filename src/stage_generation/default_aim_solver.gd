class_name DefaultAimSolver
extends RefCounted

## Chooses only among already-certified witnesses. It never searches or exposes
## an aim hint to gameplay.


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
