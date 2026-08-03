class_name ContainmentSpec
extends RefCounted

const CONTRACT_VERSION := 4
const APRON_OWNER_ID := &"world/apron"
const APRON_SHAPE_ID := &"ApronShape"
const BACKSTOP_OWNER_ID := &"world/backstop"
const BACKSTOP_SHAPE_ID := &"BackstopWall"

var contract_version: int:
	get:
		return _contract_version
var containment_bounds: AABB:
	get:
		return _containment_bounds
var apron_xz_bounds: Rect2:
	get:
		return _apron_xz_bounds
var apron_minimum_y: float:
	get:
		return _apron_minimum_y
var backstop_center: Vector3:
	get:
		return _backstop_center
var backstop_size: Vector3:
	get:
		return _backstop_size
var rear_transition_depth: float:
	get:
		return _rear_transition_depth
var maximum_join_gap: float:
	get:
		return _maximum_join_gap
var collision_layer: int:
	get:
		return _collision_layer
var collision_mask: int:
	get:
		return _collision_mask

var _contract_version: int
var _containment_bounds: AABB
var _apron_xz_bounds: Rect2
var _apron_minimum_y: float
var _backstop_center: Vector3
var _backstop_size: Vector3
var _rear_transition_depth: float
var _maximum_join_gap: float
var _collision_layer: int
var _collision_mask: int


func _init(
		version: int = CONTRACT_VERSION,
		bounds: AABB = AABB(Vector3(-245.0, -32.0, -178.0), Vector3(490.0, 286.0, 230.0)),
		apron_bounds: Rect2 = Rect2(Vector2(-245.0, -172.25), Vector2(490.0, 224.25)),
		apron_min_y: float = -30.5,
		wall_center: Vector3 = Vector3(0.0, 111.0, -174.25),
		wall_size: Vector3 = Vector3(480.0, 284.0, 4.0),
		transition_depth: float = 0.25,
		join_gap: float = 0.01,
		layer: int = 1,
		mask: int = 2
) -> void:
	_contract_version = version
	_containment_bounds = bounds
	_apron_xz_bounds = apron_bounds
	_apron_minimum_y = apron_min_y
	_backstop_center = wall_center
	_backstop_size = wall_size
	_rear_transition_depth = transition_depth
	_maximum_join_gap = join_gap
	_collision_layer = layer
	_collision_mask = mask


func is_valid() -> bool:
	if _contract_version != CONTRACT_VERSION or not _aabb_is_finite(_containment_bounds) \
			or not _rect_is_finite(_apron_xz_bounds) or not _backstop_center.is_finite() \
			or not _backstop_size.is_finite() or not is_finite(_apron_minimum_y):
		return false
	if _containment_bounds.size.x <= 0.0 or _containment_bounds.size.y <= 0.0 \
			or _containment_bounds.size.z <= 0.0 or _apron_xz_bounds.size.x <= 0.0 \
			or _apron_xz_bounds.size.y <= 0.0 or _backstop_size.x <= 0.0 \
			or _backstop_size.y <= 0.0 or _backstop_size.z <= 0.0:
		return false
	if _rear_transition_depth <= 0.0 or _maximum_join_gap < 0.0 \
			or _maximum_join_gap > 0.01 or _collision_layer != 1 or _collision_mask != 2:
		return false
	if _containment_bounds != AABB(Vector3(-245.0, -32.0, -178.0), Vector3(490.0, 286.0, 230.0)) \
			or _apron_xz_bounds != Rect2(Vector2(-245.0, -172.25), Vector2(490.0, 224.25)) \
			or not is_equal_approx(_apron_minimum_y, -30.5) \
			or not _backstop_center.is_equal_approx(Vector3(0.0, 111.0, -174.25)) \
			or not _backstop_size.is_equal_approx(Vector3(480.0, 284.0, 4.0)) \
			or not is_equal_approx(_rear_transition_depth, 0.25):
		return false
	var backstop_bounds := AABB(_backstop_center - _backstop_size * 0.5, _backstop_size)
	return _containment_bounds.encloses(backstop_bounds) \
			and _apron_minimum_y >= _containment_bounds.position.y \
			and is_equal_approx(backstop_front_z(), -172.25)


func backstop_front_z() -> float:
	return _backstop_center.z + _backstop_size.z * 0.5


static func _aabb_is_finite(value: AABB) -> bool:
	return value.position.is_finite() and value.size.is_finite()


static func _rect_is_finite(value: Rect2) -> bool:
	return value.position.is_finite() and value.size.is_finite()
