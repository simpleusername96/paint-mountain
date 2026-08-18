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
