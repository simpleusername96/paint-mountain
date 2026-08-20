class_name BallDealProfile
extends Resource

@export_category("Ball deal")
@export_range(1, 99, 1) var profile_version: int = 2
@export var allowed_kinds: Array[int] = [BallKind.Value.STANDARD]
@export var required_kinds: Array[int] = []


func is_valid() -> bool:
	if profile_version != 2 or allowed_kinds.is_empty():
		return false
	var seen := {}
	for kind in allowed_kinds:
		if not BallKind.is_valid(kind) or seen.has(kind):
			return false
		seen[kind] = true
	var required_seen := {}
	for kind in required_kinds:
		if not BallKind.is_valid(kind) or not seen.has(kind) or required_seen.has(kind):
			return false
		required_seen[kind] = true
	return seen.has(BallKind.Value.STANDARD)


func allows_kind(kind: int) -> bool:
	return is_valid() and allowed_kinds.has(kind)


func requires_kind(kind: int) -> bool:
	return is_valid() and required_kinds.has(kind)
