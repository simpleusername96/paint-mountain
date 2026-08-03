class_name TrajectoryPrediction
extends RefCounted

enum Kind {
	COLLISION,
	BOUNDS_EXIT,
	TIMEOUT,
}

var kind: Kind:
	get:
		return _kind
var endpoint: Vector3:
	get:
		return _endpoint
var sampled_points: PackedVector3Array:
	get:
		return _sampled_points.duplicate()
var duration: float:
	get:
		return _duration
var collider: Object:
	get:
		return _collider
var normal: Vector3:
	get:
		return _normal
var diagnostic: StringName:
	get:
		return _diagnostic

var _kind: Kind
var _endpoint: Vector3
var _sampled_points: PackedVector3Array
var _duration: float
var _collider: Object
var _normal: Vector3
var _diagnostic: StringName


func _init(
		prediction_kind: Kind = Kind.TIMEOUT,
		prediction_endpoint: Vector3 = Vector3.ZERO,
		prediction_points: PackedVector3Array = PackedVector3Array(),
		prediction_duration: float = 0.0,
		prediction_collider: Object = null,
		prediction_normal: Vector3 = Vector3.ZERO,
		prediction_diagnostic: StringName = &""
) -> void:
	_kind = prediction_kind
	_endpoint = prediction_endpoint
	_sampled_points = prediction_points.duplicate()
	_duration = maxf(prediction_duration, 0.0)
	_collider = prediction_collider
	_normal = prediction_normal.normalized() if not prediction_normal.is_zero_approx() else Vector3.ZERO
	_diagnostic = prediction_diagnostic


func is_fireable() -> bool:
	return kind == Kind.COLLISION or kind == Kind.BOUNDS_EXIT
