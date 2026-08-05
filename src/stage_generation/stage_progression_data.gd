class_name StageProgressionData
extends Resource

## Single source of truth for the thirty-stage geometry ladder. Runtime stage
## entry consumes one accepted seed from the catalog; it never chooses a
## template or searches for a replacement seed.

const FIRST_STAGE_SEED := 1347223552
const STAGE_SEED_STRIDE := 1000003
const CANDIDATE_STRIDE := 7919
const STAGE_COUNT := 30

@export_category("Versioned progression")
@export var progression_version: int = StageGenerationContract.CONTRACT_VERSION
@export var stage_count: int = STAGE_COUNT

# Candidate indices from the last accepted catalog seed map. The v8 offline
# artifact rebuild must replace any entry rejected by the new keyed sampler;
# runtime still never searches or substitutes a mountain after stage entry.
const ACCEPTED_CANDIDATE_INDEX_BY_STAGE := {
	3: 3,
	4: 0, 5: 0, 6: 15, 7: 0, 8: 0, 9: 1, 10: 0,
	11: 1, 12: 0, 13: 0, 14: 1, 15: 0, 16: 3, 17: 1,
	18: 1, 19: 1, 20: 0, 21: 0, 22: 1, 23: 8, 24: 1,
	25: 2, 26: 0, 27: 3, 28: 19, 29: 2, 30: 6,
}


static func target_for(stage_number: int) -> float:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	if n <= 10:
		return 4.0 + 0.5 * float(n - 1)
	if n <= 20:
		return snappedf(9.0 + 0.35 * float(n - 11), 0.5)
	return snappedf(12.5 + 0.30 * float(n - 21), 0.5)


static func shots_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	if n <= 5:
		return 4
	if n <= 15:
		return 5
	if n <= 25:
		return 6
	return 7


static func duration_seconds_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	if n <= 10:
		return 90
	if n <= 20:
		return 120
	return 180


static func normalized_t(stage_number: int) -> float:
	return float(clampi(stage_number, 1, STAGE_COUNT) - 1) / float(STAGE_COUNT - 1)


static func nominal_peak_for(stage_number: int) -> float:
	return snappedf(72.0 + 54.0 * normalized_t(stage_number), 0.5)


static func requested_seed_for(stage_number: int) -> int:
	return candidate_seed_for(stage_number, accepted_candidate_index_for(stage_number))


static func accepted_candidate_index_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	return int(ACCEPTED_CANDIDATE_INDEX_BY_STAGE.get(n, 0))


static func candidate_seed_for(stage_number: int, candidate_index: int = 0) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	return int((FIRST_STAGE_SEED + n * STAGE_SEED_STRIDE + maxi(0, candidate_index) * CANDIDATE_STRIDE) & 0x7fffffff)


static func terrain_size_for(stage_number: int) -> Vector2:
	var t := normalized_t(stage_number)
	return Vector2(
		float(roundi((180.0 + 60.0 * t) / 2.0) * 2),
		float(roundi((120.0 + 40.0 * t) / 2.0) * 2)
	)


static func cell_count_for(stage_number: int) -> Vector2i:
	var t := normalized_t(stage_number)
	return Vector2i(
		roundi((72.0 + 24.0 * t) / 2.0) * 2,
		roundi((48.0 + 16.0 * t) / 2.0) * 2
	)


static func station_count_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	return 8 if n <= 9 else (9 if n <= 19 else 10)


static func route_count_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	if n == 3:
		return 3
	return 1 if n <= 7 else (2 if n <= 17 else 3)


static func reversal_count_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	return 0 if n <= 3 else (1 if n <= 11 else (2 if n <= 21 else 3))


static func ridge_count_for(stage_number: int) -> int:
	return 3 + floori(float(clampi(stage_number, 1, STAGE_COUNT) - 1) / 5.0)


static func basin_count_for(stage_number: int) -> int:
	return 0 if stage_number <= 6 else (1 if stage_number <= 16 else 2)


static func pass_count_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	return 0 if n <= 5 else (1 if n <= 13 else (2 if n <= 21 else 3))


static func undulation_for(stage_number: int) -> float:
	return snappedf(2.0 + 6.0 * normalized_t(stage_number), 0.1)


static func route_width_for(stage_number: int) -> float:
	return snappedf(28.0 - 10.0 * normalized_t(stage_number), 0.5)


static func mechanism_count_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	if n == 1:
		return 0
	if n == 2:
		return 1
	if n <= 6:
		return 2
	if n <= 12:
		return 3
	if n <= 18:
		return 4
	if n <= 24:
		return 5
	return 6


static func difficulty_score_for(stage_number: int) -> float:
	var n := clampi(stage_number, 1, STAGE_COUNT)
	var size := terrain_size_for(n)
	# Stage 03's wide three-route fan is a Splitter teaching witness, not the
	# late-game route-density tier. Keep the authored difficulty ladder gradual.
	var difficulty_route_count := 1 if n == 3 else route_count_for(n)
	return 0.05 * (size.x - 180.0) \
			+ 0.05 * (size.y - 120.0) \
			+ 0.10 * (nominal_peak_for(n) - 72.0) \
			+ 4.0 * (difficulty_route_count - 1) \
			+ 2.0 * reversal_count_for(n) \
			+ 0.8 * (ridge_count_for(n) - 3) \
			+ pass_count_for(n) \
			+ basin_count_for(n) \
			+ 0.5 * (28.0 - route_width_for(n)) \
			+ 0.5 * mechanism_count_for(n) \
			+ 0.2 * (target_for(n) - 4.0) \
			+ 0.5 * (undulation_for(n) - 2.0) \
			+ 0.4 * (station_count_for(n) - 8)
