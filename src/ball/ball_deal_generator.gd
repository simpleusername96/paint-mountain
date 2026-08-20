class_name BallDealGenerator
extends RefCounted

const MAXIMUM_ATTEMPTS := 128
const MAXIMUM_RESIDENT_BALLS := 21


static func generate(stage_id: StringName, deal_seed: int, maximum_shots: int, profile: BallDealProfile) -> Array[BallToken]:
	if maximum_shots <= 0 or profile == null or not profile.is_valid():
		return []
	var random := VersionedIntegerPrng.new(VersionedIntegerPrng.seed_for(stage_id, deal_seed))
	for _attempt in range(MAXIMUM_ATTEMPTS):
		var candidate := _candidate(random, maximum_shots, profile)
		if is_valid_deal(candidate, maximum_shots, profile):
			return candidate
	var fallback := _fallback(maximum_shots, profile)
	if is_valid_deal(fallback, maximum_shots, profile):
		return fallback
	return []


static func is_valid_deal(tokens: Array[BallToken], maximum_shots: int, profile: BallDealProfile) -> bool:
	if profile == null or not profile.is_valid() or tokens.size() != maximum_shots:
		return false
	var red_count := 0
	var green_count := 0
	var burst_count := 0
	var split_count := 0
	var standard_count := 0
	var kind_counts := {}
	var prefix_length := maximum_shots - 2 if maximum_shots >= 4 else maximum_shots
	for index in range(tokens.size()):
		var token := tokens[index]
		if token == null or not token.is_valid() or not profile.allows_kind(token.kind):
			return false
		if token.channel == PaintChannel.Value.RED:
			red_count += 1
		else:
			green_count += 1
		if token.kind == BallKind.Value.IMPACT_BURST:
			burst_count += 1
		elif token.kind == BallKind.Value.APEX_SPLIT:
			split_count += 1
		else:
			standard_count += 1
		kind_counts[token.kind] = int(kind_counts.get(token.kind, 0)) + 1
		# The correction reserve is outside the constrained prefix. This preserves
		# the four-shot Standard-only profile while keeping generated prefixes varied.
		if index < prefix_length and index >= 2 and tokens[index - 1].channel == token.channel and tokens[index - 2].channel == token.channel:
			return false
		if index < prefix_length and index >= 2 and tokens[index - 1].kind == token.kind and tokens[index - 2].kind == token.kind:
			return false
	if maximum_shots >= 2 and (red_count == 0 or green_count == 0):
		return false
	if burst_count > 2 or split_count > 2:
		return false
	if maximum_shots >= 3 and standard_count == 0:
		return false
	for required_kind in profile.required_kinds:
		if int(kind_counts.get(required_kind, 0)) == 0:
			return false
	if standard_count + burst_count + split_count * 3 > MAXIMUM_RESIDENT_BALLS:
		return false
	if maximum_shots >= 4:
		var final_kinds := [tokens[maximum_shots - 2].kind, tokens[maximum_shots - 1].kind]
		var final_channels := [tokens[maximum_shots - 2].channel, tokens[maximum_shots - 1].channel]
		if final_kinds != [BallKind.Value.STANDARD, BallKind.Value.STANDARD] \
				or not (final_channels.has(PaintChannel.Value.RED) and final_channels.has(PaintChannel.Value.GREEN)):
			return false
	return true


static func _candidate(random: VersionedIntegerPrng, maximum_shots: int, profile: BallDealProfile) -> Array[BallToken]:
	var tokens: Array[BallToken] = []
	var prefix_length := maximum_shots - 2 if maximum_shots >= 4 else maximum_shots
	for _index in range(prefix_length):
		tokens.append(BallToken.new(profile.allowed_kinds[random.next_index(profile.allowed_kinds.size())], random.next_index(2)))
	if maximum_shots >= 4:
		var first_channel := random.next_index(2)
		tokens.append(BallToken.new(BallKind.Value.STANDARD, first_channel))
		tokens.append(BallToken.new(BallKind.Value.STANDARD, 1 - first_channel))
	return tokens


static func _fallback(maximum_shots: int, profile: BallDealProfile) -> Array[BallToken]:
	var tokens: Array[BallToken] = []
	var prefix_length := maximum_shots - 2 if maximum_shots >= 4 else maximum_shots
	for kind in profile.required_kinds:
		if tokens.size() >= prefix_length:
			return []
		tokens.append(BallToken.new(kind, tokens.size() % 2))
	var fill_index := 0
	while tokens.size() < prefix_length:
		var kind := profile.allowed_kinds[fill_index % profile.allowed_kinds.size()]
		tokens.append(BallToken.new(kind, tokens.size() % 2))
		fill_index += 1
	if maximum_shots >= 4:
		var first_channel := tokens.size() % 2
		tokens.append(BallToken.new(BallKind.Value.STANDARD, first_channel))
		tokens.append(BallToken.new(BallKind.Value.STANDARD, 1 - first_channel))
	return tokens
