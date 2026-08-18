class_name VersionedIntegerPrng
extends RefCounted

const VERSION := 1
const _MODULUS := 2147483647
const _MULTIPLIER := 48271

var _state: int


func _init(seed: int) -> void:
	_state = normalize_seed(seed)


static func normalize_seed(seed: int) -> int:
	var normalized := seed % _MODULUS
	if normalized <= 0:
		normalized += _MODULUS - 1
	return normalized


static func seed_for(stage_id: StringName, deal_seed: int) -> int:
	var stage_hash := 1
	for byte in String(stage_id).to_utf8_buffer():
		stage_hash = (stage_hash * 31 + int(byte)) % _MODULUS
	return normalize_seed(stage_hash + (deal_seed % (_MODULUS - 1)))


func next_u31() -> int:
	# Park-Miller stays in the positive unsigned 31-bit range, avoiding host RNGs.
	_state = (_state * _MULTIPLIER) % _MODULUS
	return _state


func next_index(exclusive_upper_bound: int) -> int:
	assert(exclusive_upper_bound > 0)
	return next_u31() % exclusive_upper_bound
