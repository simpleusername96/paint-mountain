class_name BallDealProfile
extends Resource

@export_category("Ball deal")
@export_range(1, 99, 1) var profile_version: int = 1
@export var allowed_kinds: Array[int] = [BallKind.Value.STANDARD]


func is_valid() -> bool:
	if profile_version != 1 or allowed_kinds.is_empty():
		return false
	var seen := {}
	for kind in allowed_kinds:
		if not BallKind.is_valid(kind) or seen.has(kind):
			return false
		seen[kind] = true
	return seen.has(BallKind.Value.STANDARD)


func allows_kind(kind: int) -> bool:
	return is_valid() and allowed_kinds.has(kind)
