class_name CannonController
extends Node3D

signal aim_changed(yaw_degrees: float, elevation_degrees: float, power_percent: float)
signal prediction_changed(prediction: TrajectoryPrediction)
signal prediction_status_changed(status: StringName)

@export var projectile_data: ProjectileData
@export_range(0.0, 100.0, 0.1) var default_power: float = 68.0

var yaw_degrees: float = 0.0
var elevation_degrees: float = 38.0
var power_percent: float = 68.0
var input_enabled: bool = true
var _prediction: TrajectoryPrediction
var _prediction_aim_key: StringName = &""
var _prediction_wind_identity: StringName = &""
var _prediction_launch_wind_tick: int = -1
var _prediction_context_key: StringName = &""
var _expected_prediction_context_key: StringName = &""
var _committed_aim: AimTuple
var _pending_human_aim_revision: int = -1

@onready var _yaw_pivot: Node3D = %YawPivot
@onready var _elevation_pivot: Node3D = %ElevationPivot
@onready var _muzzle: Marker3D = %Muzzle


func _ready() -> void:
	assert(
		_yaw_pivot.position.is_equal_approx(CannonBallistics.YAW_PIVOT_OFFSET) \
				and _elevation_pivot.position.is_equal_approx(
					CannonBallistics.ELEVATION_PIVOT_OFFSET
				) \
				and _muzzle.position.is_equal_approx(CannonBallistics.MUZZLE_OFFSET),
		"Cannon scene offsets must match the shared ballistic geometry contract."
	)
	power_percent = default_power
	_committed_aim = AimTuple.canonicalize(yaw_degrees, elevation_degrees, power_percent)
	_apply_visuals()
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func set_aim(
		new_yaw: float,
		new_elevation: float,
		new_power: float,
		publish_if_unchanged: bool = false
) -> void:
	var canonical := AimTuple.canonicalize(new_yaw, new_elevation, new_power)
	if canonical == null:
		return
	if is_equal_approx(canonical.yaw_degrees, yaw_degrees) \
			and is_equal_approx(canonical.elevation_degrees, elevation_degrees) \
			and is_equal_approx(canonical.power_percent, power_percent):
		_pending_human_aim_revision = -1
		_committed_aim = canonical
		if publish_if_unchanged:
			publish_current_aim()
		return
	_pending_human_aim_revision = -1
	_committed_aim = canonical
	_apply_canonical_aim(canonical)


## Explicit human revisions retain the last launchable tuple until a matching
## solver result either atomically replaces it or restores it.
func begin_human_aim_revision(revision: int) -> bool:
	if revision < 0:
		return false
	if _pending_human_aim_revision > revision:
		return false
	if _committed_aim == null:
		_committed_aim = AimTuple.canonicalize(yaw_degrees, elevation_degrees, power_percent)
	if _committed_aim == null:
		return false
	# Latest-only target solving may supersede an older pending revision. The
	# committed tuple remains untouched until this exact revision finishes.
	_pending_human_aim_revision = revision
	prediction_status_changed.emit(prediction_status())
	return true


func commit_human_aim_revision(
		revision: int,
		new_yaw: float,
		new_elevation: float,
		new_power: float
) -> bool:
	if revision != _pending_human_aim_revision:
		return false
	var canonical := AimTuple.canonicalize(new_yaw, new_elevation, new_power)
	if canonical == null or not canonical.is_valid():
		return false
	_committed_aim = canonical
	_pending_human_aim_revision = -1
	_apply_canonical_aim(canonical)
	return true


func restore_human_aim_revision(revision: int) -> bool:
	if revision != _pending_human_aim_revision or _committed_aim == null:
		return false
	_pending_human_aim_revision = -1
	_apply_canonical_aim(_committed_aim)
	return true


func human_aim_revision_pending() -> bool:
	return _pending_human_aim_revision >= 0


func _apply_canonical_aim(canonical: AimTuple) -> void:
	yaw_degrees = canonical.yaw_degrees
	elevation_degrees = canonical.elevation_degrees
	power_percent = canonical.power_percent
	_apply_visuals()
	publish_current_aim()
	prediction_status_changed.emit(prediction_status())


func publish_current_aim() -> void:
	aim_changed.emit(yaw_degrees, elevation_degrees, power_percent)


func set_prediction(
		value: TrajectoryPrediction,
		prediction_aim_key: StringName = &"",
		wind_schedule_identity: StringName = &"",
		launch_wind_tick: int = -1,
		prediction_context_key: StringName = &""
) -> void:
	_prediction = value
	_prediction_aim_key = prediction_aim_key if not prediction_aim_key.is_empty() else aim_key()
	_prediction_wind_identity = wind_schedule_identity
	_prediction_launch_wind_tick = launch_wind_tick
	_prediction_context_key = prediction_context_key
	prediction_changed.emit(_prediction)
	prediction_status_changed.emit(prediction_status())


func current_prediction() -> TrajectoryPrediction:
	return _prediction


func aim_key() -> StringName:
	return AimTuple.new(yaw_degrees, elevation_degrees, power_percent).stable_key()


func prediction_key() -> StringName:
	return _prediction_context_key


func prediction_aim_key() -> StringName:
	return _prediction_aim_key


func expected_prediction_context_key() -> StringName:
	return _expected_prediction_context_key


func expect_prediction_context(context_key: StringName) -> void:
	if _expected_prediction_context_key == context_key:
		return
	_expected_prediction_context_key = context_key
	prediction_status_changed.emit(prediction_status())


func prediction_wind_identity() -> StringName:
	return _prediction_wind_identity


func prediction_launch_wind_tick() -> int:
	return _prediction_launch_wind_tick


func prediction_matches_current_aim() -> bool:
	return _prediction != null and not _prediction_aim_key.is_empty() \
			and _prediction_aim_key == aim_key()


func prediction_matches_expected_context() -> bool:
	return prediction_matches_current_aim() \
			and not _prediction_context_key.is_empty() \
			and _prediction_context_key == _expected_prediction_context_key


func prediction_status() -> StringName:
	if not prediction_matches_expected_context():
		return &"pending"
	return &"fireable" if _prediction.is_fireable() else &"invalid"


func is_aim_valid() -> bool:
	return canonical_aim_is_valid()


func canonical_aim_is_valid() -> bool:
	var aim := AimTuple.new(yaw_degrees, elevation_degrees, power_percent)
	return aim.is_valid()


func has_fireable_prediction() -> bool:
	return prediction_status() == &"fireable"


## Compatibility preflight for low-level fixtures. Production Fire admission is
## owned by StageController; this method intentionally has no firing side effect.
func request_fire() -> bool:
	return input_enabled and projectile_data != null and canonical_aim_is_valid()


func get_launch_origin() -> Vector3:
	return CannonBallistics.projectile_launch_origin_for_transform(
		global_transform,
		yaw_degrees,
		elevation_degrees,
		projectile_data.radius
	)


func get_muzzle_position() -> Vector3:
	return _muzzle.global_position


func get_launch_origin_for(requested_yaw: float, requested_elevation: float) -> Vector3:
	return CannonBallistics.projectile_launch_origin_for_transform(
		global_transform,
		requested_yaw,
		requested_elevation,
		projectile_data.radius
	)


func get_launch_velocity() -> Vector3:
	return CannonBallistics.launch_velocity(
		projectile_data,
		yaw_degrees,
		elevation_degrees,
		power_percent
	)


func _apply_visuals() -> void:
	if not is_node_ready():
		return
	_yaw_pivot.rotation.y = -deg_to_rad(yaw_degrees)
	_elevation_pivot.rotation.x = deg_to_rad(elevation_degrees)
