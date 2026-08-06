extends SceneTree

var _failed := false

func _initialize() -> void:
	_assert(StageProgressionData.requested_seed_for(30) == StageProgressionData.candidate_seed_for(30, 0), "requested seed must be deterministic candidate zero, not a persisted accepted map")
	for stage_number in range(1, StageProgressionData.STAGE_COUNT + 1):
		var seen: Dictionary = {}
		for candidate_index in range(32):
			var seed := StageProgressionData.candidate_seed_for(stage_number, candidate_index)
			_assert(seed > 0 and not seen.has(seed), "candidate seeds must be unique in 0-31")
			seen[seed] = true
	quit(1 if _failed else 0)

func _assert(condition: bool, message: String) -> void:
	if condition: return
	push_error("Stage progression candidate test failed: %s" % message)
	_failed = true
