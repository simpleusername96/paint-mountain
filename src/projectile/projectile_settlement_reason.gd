class_name ProjectileSettlementReason
extends RefCounted

const BACKSTOP := &"BACKSTOP"
const CONSUMED := &"consumed"
const ESCAPED_BOUNDS := &"escaped_bounds"
const MISSED_TERRAIN := &"missed_terrain"
const INVALID_GEOMETRY := &"invalid_geometry"
const CONTACT_CONFIGURATION_ERROR := &"contact_configuration_error"


static func is_backstop(reason: StringName) -> bool:
	return reason == BACKSTOP


static func is_terminal(reason: StringName) -> bool:
	return reason in [
		BACKSTOP,
		CONSUMED,
		ESCAPED_BOUNDS,
		MISSED_TERRAIN,
		INVALID_GEOMETRY,
		CONTACT_CONFIGURATION_ERROR,
	]
