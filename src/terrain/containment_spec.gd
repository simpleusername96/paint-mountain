class_name ContainmentSpec
extends RefCounted

const CONTRACT_VERSION := 4
const FIXED_CONTAINMENT_BOUNDS := AABB(Vector3(-245.0, -32.0, -178.0), Vector3(490.0, 286.0, 230.0))
const FIXED_APRON_XZ_BOUNDS := Rect2(Vector2(-245.0, -172.25), Vector2(490.0, 224.25))
const FIXED_APRON_MINIMUM_Y := -30.5
const FIXED_BACKSTOP_CENTER := Vector3(0.0, 111.0, -174.25)
const FIXED_BACKSTOP_SIZE := Vector3(480.0, 284.0, 4.0)
const FIXED_REAR_TRANSITION_DEPTH := 0.25
const FIXED_MAXIMUM_JOIN_GAP := 0.01
const FIXED_COLLISION_LAYER := 1
const FIXED_COLLISION_MASK := 2
const CONTACT_OWNER_META := &"contact_owner_id"
const CONTACT_SHAPE_META := &"contact_shape_id"
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
		bounds: AABB = FIXED_CONTAINMENT_BOUNDS,
		apron_bounds: Rect2 = FIXED_APRON_XZ_BOUNDS,
		apron_min_y: float = FIXED_APRON_MINIMUM_Y,
		wall_center: Vector3 = FIXED_BACKSTOP_CENTER,
		wall_size: Vector3 = FIXED_BACKSTOP_SIZE,
		transition_depth: float = FIXED_REAR_TRANSITION_DEPTH,
		join_gap: float = FIXED_MAXIMUM_JOIN_GAP,
		layer: int = FIXED_COLLISION_LAYER,
		mask: int = FIXED_COLLISION_MASK
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
			or _maximum_join_gap > FIXED_MAXIMUM_JOIN_GAP \
			or _collision_layer != FIXED_COLLISION_LAYER \
			or _collision_mask != FIXED_COLLISION_MASK:
		return false
	if _containment_bounds != FIXED_CONTAINMENT_BOUNDS \
			or _apron_xz_bounds != FIXED_APRON_XZ_BOUNDS \
			or not is_equal_approx(_apron_minimum_y, FIXED_APRON_MINIMUM_Y) \
			or not _backstop_center.is_equal_approx(FIXED_BACKSTOP_CENTER) \
			or not _backstop_size.is_equal_approx(FIXED_BACKSTOP_SIZE) \
			or not is_equal_approx(_rear_transition_depth, FIXED_REAR_TRANSITION_DEPTH):
		return false
	return _containment_bounds.encloses(backstop_bounds()) \
			and _apron_minimum_y >= _containment_bounds.position.y \
			and is_equal_approx(backstop_front_z(), -172.25)


func backstop_front_z() -> float:
	return _backstop_center.z + _backstop_size.z * 0.5


func backstop_bottom_y() -> float:
	return _backstop_center.y - _backstop_size.y * 0.5


func backstop_bounds() -> AABB:
	return AABB(_backstop_center - _backstop_size * 0.5, _backstop_size)


func apron_bottom_y() -> float:
	return _containment_bounds.position.y


func supports_terrain_join(terrain_xz_bounds: Rect2, terrain_world_base_y: float) -> bool:
	if not _rect_is_finite(terrain_xz_bounds) or not terrain_xz_bounds.has_area() \
			or not is_finite(terrain_world_base_y):
		return false
	if not _apron_xz_bounds.encloses(terrain_xz_bounds) \
			or terrain_world_base_y < _apron_minimum_y \
			or terrain_world_base_y > _containment_bounds.end.y:
		return false
	var rear_join_depth := terrain_xz_bounds.position.y - backstop_front_z()
	var wall_bounds := backstop_bounds()
	return absf(rear_join_depth - _rear_transition_depth) <= _maximum_join_gap \
			and terrain_xz_bounds.position.x >= wall_bounds.position.x \
			and terrain_xz_bounds.end.x <= wall_bounds.end.x


func checksum() -> int:
	var values := PackedInt64Array([
		_contract_version,
		_quantize(_containment_bounds.position.x),
		_quantize(_containment_bounds.position.y),
		_quantize(_containment_bounds.position.z),
		_quantize(_containment_bounds.size.x),
		_quantize(_containment_bounds.size.y),
		_quantize(_containment_bounds.size.z),
		_quantize(_apron_xz_bounds.position.x),
		_quantize(_apron_xz_bounds.position.y),
		_quantize(_apron_xz_bounds.size.x),
		_quantize(_apron_xz_bounds.size.y),
		_quantize(_apron_minimum_y),
		_quantize(_backstop_center.x),
		_quantize(_backstop_center.y),
		_quantize(_backstop_center.z),
		_quantize(_backstop_size.x),
		_quantize(_backstop_size.y),
		_quantize(_backstop_size.z),
		_quantize(_rear_transition_depth),
		_quantize(_maximum_join_gap),
		_collision_layer,
		_collision_mask,
	])
	var hash: int = 2166136261
	for value in values:
		for shift in range(0, 64, 8):
			hash = hash ^ int((value >> shift) & 0xff)
			hash = int((hash * 16777619) & 0xffffffff)
	return hash


static func _quantize(value: float) -> int:
	return roundi(value * 1000.0)


static func _aabb_is_finite(value: AABB) -> bool:
	return value.position.is_finite() and value.size.is_finite()


static func _rect_is_finite(value: Rect2) -> bool:
	return value.position.is_finite() and value.size.is_finite()
