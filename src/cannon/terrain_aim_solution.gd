class_name TerrainAimSolution
extends RefCounted

## Immutable outcome of one terrain-target solve request.
enum Status { PENDING, VALID, INVALID_TARGET, NO_SOLUTION, STALE_CONTEXT }

var status: Status
var aim: AimTuple
var prediction: TrajectoryPrediction
var context_key: StringName
var rejection: StringName


func _init(
		new_status: Status = Status.PENDING,
		new_aim: AimTuple = null,
		new_prediction: TrajectoryPrediction = null,
		new_context_key: StringName = &"",
		new_rejection: StringName = &""
) -> void:
	status = new_status
	aim = new_aim
	prediction = new_prediction
	context_key = new_context_key
	rejection = new_rejection
