class_name BallKind
extends RefCounted

enum Value {
	STANDARD,
	IMPACT_BURST,
	APEX_SPLIT,
}


static func is_valid(value: int) -> bool:
	return value >= Value.STANDARD and value <= Value.APEX_SPLIT


static func is_special(value: int) -> bool:
	return value == Value.IMPACT_BURST or value == Value.APEX_SPLIT


static func stable_id(value: int) -> StringName:
	match value:
		Value.STANDARD:
			return &"standard"
		Value.IMPACT_BURST:
			return &"impact_burst"
		Value.APEX_SPLIT:
			return &"apex_split"
	return &""


## Stable declarative capability used by offline stage-feasibility checks.
## Runtime behavior remains owned by the projectile behavior implementations.
static func target_paint_capability_id(value: int) -> StringName:
	match value:
		Value.STANDARD:
			return &"direct_contact"
		Value.IMPACT_BURST:
			return &"impact_radial"
		Value.APEX_SPLIT:
			return &"apex_child_fan"
	return &""


static func target_paint_contributor_count(value: int) -> int:
	match value:
		Value.STANDARD, Value.IMPACT_BURST:
			return 1
		Value.APEX_SPLIT:
			return 3
	return 0
