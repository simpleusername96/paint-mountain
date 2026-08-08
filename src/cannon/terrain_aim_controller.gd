class_name TerrainAimController
extends Node

## Owns the selected terrain target and latest-only human solve transaction.
## Device input only queues intent; this controller performs picks in physics
## and lets the scheduler validate one exact first-contact prediction at a time.
signal target_state_changed(target: TerrainAimTarget, visual_state: StringName)

const REJECTED_PRESENTATION_SECONDS := 0.35

var _camera: Camera3D
var _terrain: TerrainSurface
var _cannon: CannonController
var _stage_controller: StageController
var _scheduler: TrajectoryPredictionScheduler
var _wind_controller: WindController
var _preview: TerrainTargetPreview
var _picker := TerrainScreenRayPicker.new()
var _selected_target: TerrainAimTarget
var _committed_target: TerrainAimTarget
var _pending_target: TerrainAimTarget
var _pending_kind: StringName = &""
var _pending_value := 0.0
var _branch: StringName = &""
var _active_request_revision := -1
var _next_request_revision := 0
var _queued_pointer_revision := -1
var _queued_pointer_settled := false
var _last_wind_epoch := -2147483648
var _configured := false
var _user_selected := false
var _rejected_revision := -1
var _solve_request_count := 0


func configure(
		camera: Camera3D,
		terrain: TerrainSurface,
		cannon: CannonController,
		stage_controller: StageController,
		scheduler: TrajectoryPredictionScheduler,
		wind_controller: WindController,
		preview: TerrainTargetPreview
) -> bool:
	if camera == null or terrain == null or cannon == null or stage_controller == null \
			or scheduler == null or wind_controller == null or preview == null:
		return false
	_camera = camera
	_terrain = terrain
	_cannon = cannon
	_stage_controller = stage_controller
	_scheduler = scheduler
	_wind_controller = wind_controller
	_preview = preview
	_branch = _branch_for_aim(_current_aim())
	_last_wind_epoch = _current_wind_epoch()
	if not _cannon.prediction_changed.is_connected(_on_prediction_changed):
		_cannon.prediction_changed.connect(_on_prediction_changed)
	_configured = true
	set_physics_process(true)
	_on_prediction_changed(_cannon.current_prediction())
	return true


func _physics_process(_delta: float) -> void:
	if not _configured or _picker.queued_request_revision() < 0:
		return
	var target := _picker.pick_latest_in_physics(_terrain)
	var consumed_revision := _picker.consumed_request_revision()
	var settled := consumed_revision == _queued_pointer_revision \
			and _queued_pointer_settled
	if target != null:
		_user_selected = true
		_request_explicit_target(target, settled)
	elif settled and _selected_target != null and _active_request_revision < 0:
		# Invalid gaps never move the target. The last valid drag request is already
		# latest-only; release only settles that existing selection.
		_present_selected_state()


func queue_pointer_target(screen_position: Vector2, settled: bool = false) -> bool:
	if not _configured or not screen_position.is_finite():
		return false
	_next_request_revision += 1
	_queued_pointer_revision = _next_request_revision
	_queued_pointer_settled = settled
	return _picker.queue_latest(_camera, screen_position, _queued_pointer_revision)


func request_elevation_delta(delta_degrees: float) -> bool:
	if not _can_request_explicit_adjustment() or not is_finite(delta_degrees):
		return false
	var base_value := _pending_value \
			if _pending_kind == &"elevation" and _active_request_revision >= 0 \
			else _cannon.elevation_degrees
	var requested := AimTuple.snap_angle(clampf(
		base_value + delta_degrees,
		AimTuple.MINIMUM_ELEVATION_DEGREES,
		AimTuple.MAXIMUM_ELEVATION_DEGREES
	))
	if is_equal_approx(requested, base_value):
		return false
	return _begin_solve(_selected_target, &"elevation", requested, true)


func request_power_delta(delta_percent: float) -> bool:
	if not _can_request_explicit_adjustment() or not is_finite(delta_percent):
		return false
	var base_value := _pending_value \
			if _pending_kind == &"power" and _active_request_revision >= 0 \
			else _cannon.power_percent
	var requested := AimTuple.snap_power(clampf(
		base_value + delta_percent,
		AimTuple.MINIMUM_POWER_PERCENT,
		AimTuple.MAXIMUM_POWER_PERCENT
	))
	if is_equal_approx(requested, base_value):
		return false
	return _begin_solve(_selected_target, &"power", requested, true)


## Automatic wind maintenance never opens a Human Fire transaction. The last
## committed tuple stays launchable until a current replacement validates.
func request_wind_refresh() -> void:
	if not _configured:
		return
	var epoch := _current_wind_epoch()
	if epoch == _last_wind_epoch:
		return
	_last_wind_epoch = epoch
	if _selected_target == null or _cannon.human_aim_revision_pending():
		return
	_begin_solve(_selected_target, &"target", 0.0, false)


func reset_for_restart() -> void:
	_active_request_revision = -1
	_pending_kind = &""
	_pending_target = null
	_rejected_revision = -1
	_picker.clear()
	if _scheduler != null:
		_scheduler.cancel_target_solution()
	_selected_target = null
	_committed_target = null
	_user_selected = false
	_branch = _branch_for_aim(_current_aim())
	_last_wind_epoch = _current_wind_epoch()
	if _preview != null:
		_preview.clear_target()
	target_state_changed.emit(null, TerrainTargetPreview.STATE_HIDDEN)


func selected_target() -> TerrainAimTarget:
	return _selected_target


func selected_target_state() -> StringName:
	return _preview.visual_state() if _preview != null else TerrainTargetPreview.STATE_HIDDEN


func active_request_revision() -> int:
	return _active_request_revision


func solve_request_count() -> int:
	return _solve_request_count


func _request_explicit_target(target: TerrainAimTarget, _settled: bool) -> bool:
	if _active_request_revision >= 0 and _pending_target != null \
			and _pending_target.revision_key == target.revision_key:
		return true
	if _active_request_revision < 0 and _selected_target != null \
			and _selected_target.revision_key == target.revision_key:
		return true
	return _begin_solve(target, &"target", 0.0, true)


func _begin_solve(
		target: TerrainAimTarget,
		constraint: StringName,
		requested_value: float,
		explicit_human_revision: bool
) -> bool:
	if target == null or _scheduler == null:
		return false
	_next_request_revision += 1
	var revision := _next_request_revision
	if explicit_human_revision and not _stage_controller.begin_human_aim_revision(revision):
		return false
	_active_request_revision = revision
	_solve_request_count += 1
	_rejected_revision = -1
	_pending_target = target
	_pending_kind = constraint
	_pending_value = requested_value
	_selected_target = target
	_preview.present_target(target.world_point, target.world_normal, TerrainTargetPreview.STATE_PENDING)
	target_state_changed.emit(target, TerrainTargetPreview.STATE_PENDING)
	_scheduler.request_target_solution(
		target,
		constraint,
		requested_value,
		_branch,
		_current_aim(),
		revision,
		_on_solution.bind(revision, explicit_human_revision)
	)
	return true


func _on_solution(
		solution: TerrainAimSolution,
		revision: int,
		explicit_human_revision: bool
) -> bool:
	if revision != _active_request_revision or solution == null:
		return false
	if solution.status == TerrainAimSolution.Status.PENDING:
		return false
	if solution.status == TerrainAimSolution.Status.VALID and solution.aim != null:
		var accepted := _stage_controller.commit_human_aim_revision(
			revision,
			solution.aim.yaw_degrees,
			solution.aim.elevation_degrees,
			solution.aim.power_percent
		) if explicit_human_revision else _stage_controller.set_aim(
			solution.aim.yaw_degrees,
			solution.aim.elevation_degrees,
			solution.aim.power_percent,
			StageController.ActionOrigin.HUMAN
		)
		if not accepted:
			return false
		_committed_target = _pending_target
		_selected_target = _committed_target
		_pending_target = null
		_branch = _branch_for_aim(solution.aim)
		_active_request_revision = -1
		_pending_kind = &""
		_preview.present_target(
			_selected_target.world_point,
			_selected_target.world_normal,
			TerrainTargetPreview.STATE_CONFIRMED
		)
		target_state_changed.emit(_selected_target, TerrainTargetPreview.STATE_CONFIRMED)
		return true
	if solution.status in [
		TerrainAimSolution.Status.INVALID_TARGET,
		TerrainAimSolution.Status.NO_SOLUTION,
	]:
		var rejected_target := _pending_target
		_pending_target = null
		if not explicit_human_revision:
			_selected_target = _committed_target
			_active_request_revision = -1
			_pending_kind = &""
			_present_selected_state()
			return false
		if explicit_human_revision:
			_stage_controller.restore_human_aim_revision(revision)
		_selected_target = _committed_target
		_active_request_revision = -1
		_pending_kind = &""
		if rejected_target != null:
			_rejected_revision = revision
			_preview.present_target(
				rejected_target.world_point,
				rejected_target.world_normal,
				TerrainTargetPreview.STATE_REJECTED
			)
			target_state_changed.emit(rejected_target, TerrainTargetPreview.STATE_REJECTED)
			get_tree().create_timer(REJECTED_PRESENTATION_SECONDS).timeout.connect(
				_restore_preview_after_rejection.bind(revision)
			)
		return false
	return false


func _restore_preview_after_rejection(revision: int) -> void:
	if revision != _rejected_revision or _active_request_revision >= 0:
		return
	_rejected_revision = -1
	_present_selected_state()


func _on_prediction_changed(prediction: TrajectoryPrediction) -> void:
	if not _configured:
		return
	if _selected_target == null and not _user_selected \
			and _prediction_is_current_top(prediction):
		_selected_target = TerrainAimTarget.new(
			prediction.collision_contact_point(), prediction.normal, prediction.hit_identity
		)
		_committed_target = _selected_target
		_branch = _branch_for_aim(_current_aim())
	if _active_request_revision < 0:
		_present_selected_state()


func _present_selected_state() -> void:
	if _selected_target == null:
		_preview.clear_target()
		target_state_changed.emit(null, TerrainTargetPreview.STATE_HIDDEN)
		return
	var prediction := _cannon.current_prediction()
	var state := TerrainTargetPreview.STATE_CONFIRMED \
			if _prediction_is_current_top(prediction) \
					and TerrainAimSolver.validates_target(
						prediction, _selected_target, _cannon.projectile_data.radius
					) \
			else TerrainTargetPreview.STATE_SELECTED
	_preview.present_target(_selected_target.world_point, _selected_target.world_normal, state)
	target_state_changed.emit(_selected_target, state)


func _prediction_is_current_top(prediction: TrajectoryPrediction) -> bool:
	return prediction != null \
			and prediction.kind == TrajectoryPrediction.Kind.COLLISION \
			and prediction.hit_identity != null \
			and prediction.hit_identity.contact_owner_id \
					== TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			and _cannon.prediction_matches_expected_context()


func _can_request_explicit_adjustment() -> bool:
	return _configured and _selected_target != null \
			and _stage_controller.current_state == StageController.State.AIMING \
			and _cannon.input_enabled


func _current_aim() -> AimTuple:
	if _cannon == null:
		return null
	return AimTuple.new(
		_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent
	)


func _branch_for_aim(aim: AimTuple) -> StringName:
	if aim == null:
		return &"low"
	return &"high" if aim.elevation_degrees \
			>= TerrainAimSolver.BRANCH_SPLIT_ELEVATION_DEGREES else &"low"


func _current_wind_epoch() -> int:
	if _wind_controller == null:
		return -2147483648
	return _wind_controller.prediction_epoch(
		TrajectoryPredictionJob.MAXIMUM_STEPS,
		TrajectoryPredictionScheduler.DYNAMIC_WIND_BUCKET_TICKS
	)
