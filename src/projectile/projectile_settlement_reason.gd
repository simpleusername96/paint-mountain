class_name ProjectileSettlementReason
extends RefCounted

const BACKSTOP := &"BACKSTOP"


static func is_backstop(reason: StringName) -> bool:
	return reason == BACKSTOP
