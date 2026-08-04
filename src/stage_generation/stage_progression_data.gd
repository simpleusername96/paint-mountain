class_name StageProgressionData
extends RefCounted

## Deterministic stage identity and tuning for the all-open thirty-stage MVP.
## The shared seeded generator remains the geometry owner; this resource only
## progresses the visible rules, seed, scale target, and mechanism band.

const FIRST_STAGE_SEED := 1347223552
const STAGE_SEED_STRIDE := 1000003

static func target_for(stage_number: int) -> float:
	var n := clampi(stage_number, 1, 30)
	if n <= 10:
		return 4.0 + 0.5 * float(n - 1)
	if n <= 20:
		return snappedf(9.0 + 0.35 * float(n - 11), 0.5)
	return snappedf(12.5 + 0.30 * float(n - 21), 0.5)

static func shots_for(stage_number: int) -> int:
	var n := clampi(stage_number, 1, 30)
	if n <= 5:
		return 4
	if n <= 10:
		return 5
	if n <= 20:
		return 6
	return 7

static func nominal_peak_for(stage_number: int) -> float:
	# Legacy stages already establish the first three height bands (72/80/88).
	# Continue from the Stage 03 summit so Stage 04 never visually drops back to
	# the introductory profile, then rise gently to the Stage 30 ceiling.
	var n := clampi(stage_number, 1, 30)
	if n <= 3:
		return [72.0, 80.0, 88.0][n - 1]
	return 88.0 + float(n - 3) * 0.60

static func requested_seed_for(stage_number: int) -> int:
	return int((FIRST_STAGE_SEED + clampi(stage_number, 1, 30) * STAGE_SEED_STRIDE) & 0x7fffffff)

static func mechanism_count_for(stage_number: int) -> int:
	if stage_number <= 5:
		return 0
	if stage_number <= 20:
		return 1
	return 2

static func profile_band(stage_number: int) -> int:
	if stage_number <= 5:
		return 0
	if stage_number <= 20:
		return 1
	return 2
