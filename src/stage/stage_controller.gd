class_name StageController
extends Node

signal state_changed(current_state: int, previous_state: int)
signal shots_changed(shots_remaining: int, maximum_shots: int)
signal shot_fired(shot_number: int, yaw: float, elevation: float, power: float)
signal shot_result(coverage_gain: float, total_coverage: float)
signal shot_observation_sealed(observation: ShotObservation)
signal stage_cleared(final_coverage: float, shots_used: int)
signal stage_failed(final_coverage: float, missing_coverage: float)
signal restart_completed(elapsed_milliseconds: float)
signal aim_action_accepted(yaw: float, elevation: float, power: float, origin: int)
signal fire_action_accepted(origin: int)
signal restart_action_accepted(origin: int)

enum ActionOrigin {
	HUMAN,
	REPLAY,
	AGENT,
	DEBUG,
}

enum State {
	LOADING,
	BRIEFING,
	AIMING,
	PROJECTILE_IN_FLIGHT,
	PAINT_SETTLING,
	SHOT_RESULT,
	STAGE_CLEAR,
	STAGE_FAILED,
	PAUSED,
}

const SHOT_RESULT_DURATION := 0.7

var current_state: State = State.LOADING
var stage_data: StageData
var shots_remaining: int = 0
var coverage_before_shot: float = 0.0

var _cannon: CannonController
var _projectile_manager: ProjectileManager
var _paint_system: PaintSystem
var _terrain_surface: TerrainSurface
var _mechanisms: Array[GimmickBase] = []
var _state_before_pause: State = State.BRIEFING
var _decision_generation: int = 0
var _shot_observation: ShotObservation
var _sealed_shot_observation: ShotObservation
var _settled_unconsumed_payload: float = 0.0
var _locked_action_origin: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure(
		data: StageData,
		cannon: CannonController,
		projectile_manager: ProjectileManager,
		paint_system: PaintSystem,
		terrain_surface: TerrainSurface,
		mechanisms: Array[GimmickBase] = []
) -> void:
	stage_data = data
	_cannon = cannon
	_projectile_manager = projectile_manager
	_paint_system = paint_system
	_terrain_surface = terrain_surface
	_mechanisms = mechanisms
	_projectile_manager.stage_bounds = stage_data.stage_bounds
	if not _projectile_manager.all_projectiles_settled.is_connected(_on_all_projectiles_settled):
		_projectile_manager.all_projectiles_settled.connect(_on_all_projectiles_settled)
	if not _projectile_manager.projectile_contact_reported.is_connected(_on_projectile_contact_reported):
		_projectile_manager.projectile_contact_reported.connect(_on_projectile_contact_reported)
	if not _projectile_manager.paint_deposit_resolved.is_connected(_on_paint_deposit_resolved):
		_projectile_manager.paint_deposit_resolved.connect(_on_paint_deposit_resolved)
	if not _projectile_manager.projectile_stopped.is_connected(_on_projectile_stopped):
		_projectile_manager.projectile_stopped.connect(_on_projectile_stopped)
	if not _projectile_manager.projectile_spawned.is_connected(_on_projectile_spawned):
		_projectile_manager.projectile_spawned.connect(_on_projectile_spawned)
	for mechanism in _mechanisms:
		if not mechanism.mechanism_activated.is_connected(_on_mechanism_activated):
			mechanism.mechanism_activated.connect(_on_mechanism_activated)
	restart(true)


func lock_action_origin(origin: ActionOrigin) -> bool:
	if _locked_action_origin >= 0 and _locked_action_origin != origin:
		return false
	_locked_action_origin = origin
	return true


func release_action_origin(origin: ActionOrigin) -> bool:
	if _locked_action_origin != origin:
		return false
	_locked_action_origin = -1
	return true


func action_origin_is_locked() -> bool:
	return _locked_action_origin >= 0


func begin_aiming(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state != State.BRIEFING:
		return false
	_cannon.input_enabled = true
	return _transition_to(State.AIMING)


func enter_briefing(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state != State.AIMING:
		return false
	_cannon.input_enabled = false
	return _transition_to(State.BRIEFING)


func set_aim(yaw: float, elevation: float, power: float, origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin) or current_state != State.AIMING or not _cannon.input_enabled:
		return false
	_cannon.set_aim(yaw, elevation, power)
	aim_action_accepted.emit(_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent, origin)
	return true


func request_fire(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state != State.AIMING or shots_remaining <= 0 or not _cannon.is_aim_valid():
		return false
	if _projectile_manager.active_count() > 0 or _paint_system.pending_work_count() > 0:
		return false
	var launch_origin := _cannon.get_launch_origin()
	var velocity := _cannon.get_launch_velocity()
	coverage_before_shot = _paint_system.coverage_percent()
	_shot_observation = ShotObservation.new()
	_shot_observation.configure(
		stage_data.maximum_shots - shots_remaining + 1,
		_cannon.yaw_degrees,
		_cannon.elevation_degrees,
		_cannon.power_percent,
		coverage_before_shot,
		_cannon.projectile_data.initial_payload
	)
	_sealed_shot_observation = null
	_settled_unconsumed_payload = 0.0
	var projectile := _projectile_manager.spawn_projectile(_cannon.projectile_data, launch_origin, velocity)
	if projectile == null:
		_shot_observation = null
		return false
	_shot_observation.peak_active_projectile_count = _projectile_manager.active_count()
	shots_remaining -= 1
	_cannon.input_enabled = false
	shots_changed.emit(shots_remaining, stage_data.maximum_shots)
	shot_fired.emit(
		stage_data.maximum_shots - shots_remaining,
		_cannon.yaw_degrees,
		_cannon.elevation_degrees,
		_cannon.power_percent
	)
	fire_action_accepted.emit(origin)
	return _transition_to(State.PROJECTILE_IN_FLIGHT)


func restart(
		return_to_briefing: bool = true,
		origin: ActionOrigin = ActionOrigin.HUMAN
) -> bool:
	if not _origin_allowed(origin):
		return false
	if stage_data == null or _cannon == null or _projectile_manager == null or _paint_system == null:
		return false
	get_tree().paused = false
	var started_at := Time.get_ticks_usec()
	_decision_generation += 1
	_transition_to(State.LOADING, true)
	_projectile_manager.cleanup()
	_paint_system.clear()
	for mechanism in _mechanisms:
		mechanism.reset_state()
	shots_remaining = stage_data.maximum_shots
	coverage_before_shot = 0.0
	_shot_observation = null
	_sealed_shot_observation = null
	_settled_unconsumed_payload = 0.0
	_cannon.set_aim(stage_data.initial_aim.x, stage_data.initial_aim.y, stage_data.initial_aim.z)
	_cannon.input_enabled = not return_to_briefing
	shots_changed.emit(shots_remaining, stage_data.maximum_shots)
	_transition_to(State.BRIEFING if return_to_briefing else State.AIMING, true)
	var elapsed_ms := float(Time.get_ticks_usec() - started_at) / 1000.0
	restart_completed.emit(elapsed_ms)
	restart_action_accepted.emit(origin)
	return true


func toggle_pause(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state == State.PAUSED:
		get_tree().paused = false
		return _transition_to(_state_before_pause, true)
	if current_state in [State.LOADING, State.STAGE_CLEAR, State.STAGE_FAILED]:
		return false
	_state_before_pause = current_state
	get_tree().paused = true
	return _transition_to(State.PAUSED, true)


func force_stage_clear(origin: ActionOrigin = ActionOrigin.DEBUG) -> void:
	if not _origin_allowed(origin):
		return
	if current_state == State.PAUSED:
		get_tree().paused = false
	_transition_to(State.STAGE_CLEAR, true)
	stage_cleared.emit(_paint_system.coverage_percent(), stage_data.maximum_shots - shots_remaining)


func debug_refill_shots(origin: ActionOrigin = ActionOrigin.DEBUG) -> void:
	if not _origin_allowed(origin) or not OS.is_debug_build() or stage_data == null:
		return
	shots_remaining = stage_data.maximum_shots
	shots_changed.emit(shots_remaining, stage_data.maximum_shots)


func state_name() -> String:
	return State.keys()[current_state]


func current_shot_observation() -> ShotObservation:
	return _shot_observation


func last_sealed_shot_observation() -> ShotObservation:
	return _sealed_shot_observation


static func result_state_for(coverage: float, target: float, remaining_shots: int) -> State:
	if coverage + 0.0001 >= target:
		return State.STAGE_CLEAR
	if remaining_shots <= 0:
		return State.STAGE_FAILED
	return State.AIMING


func _on_all_projectiles_settled() -> void:
	if current_state != State.PROJECTILE_IN_FLIGHT:
		return
	_transition_to(State.PAINT_SETTLING)
	_paint_system.flush_pending()
	_decision_generation += 1
	var generation := _decision_generation
	_finalize_shot.call_deferred(generation)


func _finalize_shot(generation: int) -> void:
	var stable_ticks := 0
	while stable_ticks < 2:
		await get_tree().physics_frame
		if generation != _decision_generation or current_state != State.PAINT_SETTLING:
			return
		if _projectile_manager.active_count() == 0 and _paint_system.pending_work_count() == 0:
			stable_ticks += 1
		else:
			stable_ticks = 0
	if generation != _decision_generation or current_state != State.PAINT_SETTLING:
		return
	var coverage := _paint_system.coverage_percent()
	var gain := maxf(0.0, coverage - coverage_before_shot)
	if _shot_observation != null:
		_shot_observation.record_payload(_aggregate_remaining_payload())
		_shot_observation.seal(coverage)
		_sealed_shot_observation = _shot_observation
		shot_observation_sealed.emit(_sealed_shot_observation)
	_transition_to(State.SHOT_RESULT)
	shot_result.emit(gain, coverage)
	await get_tree().create_timer(SHOT_RESULT_DURATION, true, false, true).timeout
	if generation != _decision_generation or current_state != State.SHOT_RESULT:
		return
	var result := result_state_for(coverage, stage_data.target_coverage, shots_remaining)
	match result:
		State.STAGE_CLEAR:
			_transition_to(State.STAGE_CLEAR)
			stage_cleared.emit(coverage, stage_data.maximum_shots - shots_remaining)
		State.STAGE_FAILED:
			_transition_to(State.STAGE_FAILED)
			stage_failed.emit(coverage, maxf(0.0, stage_data.target_coverage - coverage))
		_:
			_cannon.input_enabled = true
			_transition_to(State.AIMING)


func _on_projectile_contact_reported(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
	if _shot_observation == null or contact == null:
		return
	if _terrain_surface.is_top_collider(contact.collider):
		_shot_observation.record_contact(contact, true)
	elif contact.collider is CollisionObject3D and (contact.collider.collision_layer & 4) != 0:
		_shot_observation.record_contact(contact, false)


func _on_paint_deposit_resolved(
		_projectile: PaintProjectile,
		_request: PaintDepositRequest,
		_accepted_amount: float,
		_written_pixel_count: int
) -> void:
	if _shot_observation == null:
		return
	_shot_observation.record_payload(_aggregate_remaining_payload())


func _on_projectile_stopped(projectile: PaintProjectile, reason: StringName) -> void:
	if _shot_observation != null:
		if reason != &"split" and is_instance_valid(projectile):
			_settled_unconsumed_payload += projectile.remaining_payload
		_shot_observation.record_settlement(reason)
		_shot_observation.record_payload(_aggregate_remaining_payload())


func _on_projectile_spawned(projectile: PaintProjectile) -> void:
	if _shot_observation != null:
		if projectile.split_generation > 0:
			_shot_observation.record_children_spawned(1, _projectile_manager.active_count())
		else:
			_shot_observation.peak_active_projectile_count = maxi(
				_shot_observation.peak_active_projectile_count,
				_projectile_manager.active_count()
			)


func _on_mechanism_activated(
		_mechanism: GimmickBase,
		_projectile: PaintProjectile,
		kind: MechanismData.Kind
) -> void:
	if _shot_observation != null:
		_shot_observation.record_mechanism_activation(kind)


func _transition_to(next_state: State, force: bool = false) -> bool:
	if next_state == current_state:
		return true
	if not force and not _is_allowed_transition(current_state, next_state):
		push_warning("Rejected stage transition %s -> %s" % [State.keys()[current_state], State.keys()[next_state]])
		return false
	var previous := current_state
	current_state = next_state
	state_changed.emit(current_state, previous)
	return true


func _is_allowed_transition(from_state: State, to_state: State) -> bool:
	match from_state:
		State.LOADING:
			return to_state == State.BRIEFING or to_state == State.AIMING
		State.BRIEFING:
			return to_state == State.AIMING or to_state == State.PAUSED
		State.AIMING:
			return to_state in [State.BRIEFING, State.PROJECTILE_IN_FLIGHT, State.PAUSED]
		State.PROJECTILE_IN_FLIGHT:
			return to_state in [State.PAINT_SETTLING, State.PAUSED]
		State.PAINT_SETTLING:
			return to_state in [State.SHOT_RESULT, State.PAUSED]
		State.SHOT_RESULT:
			return to_state in [State.AIMING, State.STAGE_CLEAR, State.STAGE_FAILED, State.PAUSED]
		State.PAUSED:
			return true
		_:
			return false


func _aggregate_remaining_payload() -> float:
	var remaining := _settled_unconsumed_payload
	for projectile in _projectile_manager.active_projectiles():
		remaining += projectile.remaining_payload
	return remaining


func _origin_allowed(origin: ActionOrigin) -> bool:
	return _locked_action_origin < 0 or _locked_action_origin == origin
