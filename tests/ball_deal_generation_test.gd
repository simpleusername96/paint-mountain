extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := BallDealProfile.new()
	profile.allowed_kinds = [BallKind.Value.STANDARD, BallKind.Value.IMPACT_BURST, BallKind.Value.APEX_SPLIT]
	profile.required_kinds = [BallKind.Value.IMPACT_BURST, BallKind.Value.APEX_SPLIT]
	var first := BallDealGenerator.generate(&"stage_01", 42, 6, profile)
	var replay := BallDealGenerator.generate(&"stage_01", 42, 6, profile)
	_assert(BallDealGenerator.is_valid_deal(first, 6, profile), "generated deal must satisfy all structural constraints")
	_assert(_same_deal(first, replay), "same inputs must produce the exact same deal")
	_assert(first[4].kind == BallKind.Value.STANDARD and first[5].kind == BallKind.Value.STANDARD, "four-plus deals must reserve final Standard correction tokens")
	_assert(first[4].channel != first[5].channel, "correction reserve must contain one Red and one Green token")
	_assert(_contains_kind(first, BallKind.Value.IMPACT_BURST) \
			and _contains_kind(first, BallKind.Value.APEX_SPLIT),
		"required special kinds must appear in the deal")
	var standard_only := BallDealProfile.new()
	var standard_deal := BallDealGenerator.generate(&"stage_01", 42, 4, standard_only)
	_assert(BallDealGenerator.is_valid_deal(standard_deal, 4, standard_only), "four-shot Standard-only profiles must remain structurally valid")
	var vector := VersionedIntegerPrng.new(VersionedIntegerPrng.seed_for(&"stage_01", 42))
	_assert(vector.next_u31() == 1381247423 and vector.next_u31() == 1269567224, "versioned PRNG test vector must remain stable")
	var impossible_profile := BallDealProfile.new()
	impossible_profile.allowed_kinds = [BallKind.Value.STANDARD]
	var fallback := BallDealGenerator.generate(&"stage_02", 1, 22, impossible_profile)
	_assert(fallback.is_empty(), "capacity-invalid deal requests must not emit an unsafe fallback")
	quit(1 if _failed else 0)


func _same_deal(left: Array[BallToken], right: Array[BallToken]) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if not left[index].matches(right[index]):
			return false
	return true


func _contains_kind(tokens: Array[BallToken], kind: int) -> bool:
	for token in tokens:
		if token.kind == kind:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("ball_deal_generation_test failed: %s" % message)
