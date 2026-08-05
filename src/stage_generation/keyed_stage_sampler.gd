class_name KeyedStageSampler
extends RefCounted

## Key-addressed sampling keeps unrelated generation fields from perturbing routes.

const FNV_OFFSET_BASIS: int = 2166136261
const FNV_PRIME: int = 16777619


static func sample_unit(stage_id: StringName, attempt_seed: int, field_key: String) -> float:
	var key := "paint_mountain:%s:v7:%d:%s" % [String(stage_id), attempt_seed, field_key]
	return float(fnv1a32(key) & 0x7fffffff) / 2147483647.0


static func sample_range(
		stage_id: StringName,
		attempt_seed: int,
		field_key: String,
		value_range: Vector2
) -> float:
	return lerpf(value_range.x, value_range.y, sample_unit(stage_id, attempt_seed, field_key))


static func fnv1a32(value: String) -> int:
	var hash: int = FNV_OFFSET_BASIS
	for byte in value.to_utf8_buffer():
		hash = (hash ^ byte) & 0xffffffff
		hash = (hash * FNV_PRIME) & 0xffffffff
	return hash
