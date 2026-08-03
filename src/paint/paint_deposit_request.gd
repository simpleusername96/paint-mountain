class_name PaintDepositRequest
extends RefCounted

enum SourceKind {
	TRAIL,
	IMPACT,
	FINAL_PUDDLE,
	BURST,
}

var source_kind: SourceKind:
	get:
		return _source_kind
var world_position: Vector3:
	get:
		return _world_position
var world_normal: Vector3:
	get:
		return _world_normal
var radius: float:
	get:
		return _radius
var amount: float:
	get:
		return _amount
var allow_flow: bool:
	get:
		return _allow_flow
var maximum_flow_steps: int:
	get:
		return _maximum_flow_steps
var source_instance_id: int:
	get:
		return _source_instance_id
var physics_tick: int:
	get:
		return _physics_tick
var sequence_number: int:
	get:
		return _sequence_number

var _source_kind: SourceKind
var _world_position: Vector3
var _world_normal: Vector3
var _radius: float
var _amount: float
var _allow_flow: bool
var _maximum_flow_steps: int
var _source_instance_id: int
var _physics_tick: int
var _sequence_number: int


func _init(
		request_source_kind: SourceKind = SourceKind.TRAIL,
		request_world_position: Vector3 = Vector3.ZERO,
		request_world_normal: Vector3 = Vector3.UP,
		request_radius: float = 0.0,
		request_amount: float = 0.0,
		request_allow_flow: bool = false,
		request_maximum_flow_steps: int = 0,
		request_source_instance_id: int = 0,
		request_physics_tick: int = 0,
		request_sequence_number: int = 0
) -> void:
	_source_kind = request_source_kind
	_world_position = request_world_position
	_world_normal = request_world_normal.normalized() if not request_world_normal.is_zero_approx() else Vector3.UP
	_radius = maxf(request_radius, 0.0)
	_amount = maxf(request_amount, 0.0)
	_allow_flow = request_allow_flow
	_maximum_flow_steps = maxi(request_maximum_flow_steps, 0)
	_source_instance_id = request_source_instance_id
	_physics_tick = request_physics_tick
	_sequence_number = request_sequence_number


func is_valid() -> bool:
	return radius > 0.0 and amount > 0.0 and physics_tick >= 0 and sequence_number >= 0
