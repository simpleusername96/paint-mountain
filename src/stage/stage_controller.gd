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
signal shot_family_activity_changed(active_shot_ids: PackedInt64Array, active_projectiles: int, fire_capacity: int)
signal terminal_pending_changed(pending: bool)

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
const MAX_CONCURRENT_ROOT_SHOTS := 2
const SETTLEMENT_OBSERVER_PRIORITY := 1100
const CONTAINMENT_DOMAIN_PROOF := preload("res://src/terrain/containment_domain_proof.gd")

var current_state: State = State.LOADING
var stage_data: StageData
var shots_remaining: int = 0
var coverage_before_shot: float = 0.0

var _cannon: CannonController
var _projectile_manager: ProjectileManager
var _paint_system: PaintSystem
var _terrain_surface: TerrainSurface
var _generated_layout: GeneratedStageLayout
var _mechanisms: Array[GimmickBase] = []
var _state_before_pause: State = State.BRIEFING
var _decision_generation: int = 0
var _shot_observation: ShotObservation
var _sealed_shot_observation: ShotObservation
var _shot_observations: Dictionary = {}
var _sealed_shot_observations: Dictionary = {}
var _inactive_settlement_ticks: int = 0
var _last_applied_paint_command_tick: int = -1
var _last_drained_paint_command_tick: int = -1
var _last_paint_mask_checksum: int = 0
var _locked_action_origin: int = -1
var _terminal_pending := false


func _init() -> void:
	process_physics_priority = SETTLEMENT_OBSERVER_PRIORITY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure(
		data: StageData,
		generated_layout: GeneratedStageLayout,
		cannon: CannonController,
		projectile_manager: ProjectileManager,
		paint_system: PaintSystem,
		terrain_surface: TerrainSurface,
		mechanisms: Array[GimmickBase] = []
) -> bool:
	if data == null or cannon == null or projectile_manager == null \
			or paint_system == null or terrain_surface == null:
		push_error("StageController requires complete stage runtime dependencies.")
		return false
	if generated_layout == null or not generated_layout.is_runtime_ready():
		push_error("StageController requires a runtime-ready GeneratedStageLayout before briefing.")
		return false
	var containment_proof: Dictionary = CONTAINMENT_DOMAIN_PROOF.evaluate(
		cannon,
		generated_layout.containment
	)
	if not bool(containment_proof.get("valid", false)):
		push_error(
			"StageController rejected the generated layout's aim-domain containment: %s" \
					% str(containment_proof)
		)
		return false
	var default_aim := generated_layout.default_aim
	if default_aim == null or not default_aim.is_valid():
		push_error("StageController requires a valid generated default aim.")
		return false
	stage_data = data
	_generated_layout = generated_layout
	_cannon = cannon
	_projectile_manager = projectile_manager
	_paint_system = paint_system
	_terrain_surface = terrain_surface
	_mechanisms = mechanisms
	_projectile_manager.stage_bounds = _generated_layout.containment.containment_bounds
	if not _projectile_manager.all_projectiles_settled.is_connected(_on_all_projectiles_settled):
		_projectile_manager.all_projectiles_settled.connect(_on_all_projectiles_settled)
	if not _projectile_manager.projectile_contact_reported.is_connected(_on_projectile_contact_reported):
		_projectile_manager.projectile_contact_reported.connect(_on_projectile_contact_reported)
	if not _projectile_manager.projectile_stopped.is_connected(_on_projectile_stopped):
		_projectile_manager.projectile_stopped.connect(_on_projectile_stopped)
	if not _projectile_manager.projectile_spawned.is_connected(_on_projectile_spawned):
		_projectile_manager.projectile_spawned.connect(_on_projectile_spawned)
	if not _projectile_manager.activity_changed.is_connected(_on_projectile_activity_changed):
		_projectile_manager.activity_changed.connect(_on_projectile_activity_changed)
	if not _paint_system.paint_command_applied.is_connected(_on_paint_command_applied):
		_paint_system.paint_command_applied.connect(_on_paint_command_applied)
	if not _paint_system.paint_command_rejected.is_connected(_on_paint_command_rejected):
		_paint_system.paint_command_rejected.connect(_on_paint_command_rejected)
	if not _paint_system.paint_commands_drained.is_connected(_on_paint_commands_drained):
		_paint_system.paint_commands_drained.connect(_on_paint_commands_drained)
	for mechanism in _mechanisms:
		if not mechanism.mechanism_activated.is_connected(_on_mechanism_activated):
			mechanism.mechanism_activated.connect(_on_mechanism_activated)
	return restart(true)


func activity_snapshot() -> Dictionary:
	if _projectile_manager == null:
		return {
			"active_shot_ids": PackedInt64Array(),
			"active_projectiles": 0,
			"fire_capacity": MAX_CONCURRENT_ROOT_SHOTS,
		}
	return {
		"active_shot_ids": _projectile_manager.active_shot_ids(),
		"active_projectiles": _projectile_manager.active_count(),
		"fire_capacity": MAX_CONCURRENT_ROOT_SHOTS,
		"terminal_pending": _terminal_pending,
	}


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
	if not _origin_allowed(origin) \
			or current_state not in [State.AIMING, State.PROJECTILE_IN_FLIGHT, State.PAINT_SETTLING] \
			or not _cannon.input_enabled:
		return false
	_cannon.set_aim(yaw, elevation, power)
	aim_action_accepted.emit(_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent, origin)
	return true


func request_fire(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state not in [State.AIMING, State.PROJECTILE_IN_FLIGHT, State.PAINT_SETTLING] \
			or shots_remaining <= 0 or _terminal_pending:
		return false
	if not _cannon.is_aim_valid():
		return false
	if not _projectile_manager.root_capacity_available(MAX_CONCURRENT_ROOT_SHOTS):
		return false
	var launch_origin := _cannon.get_launch_origin()
	var velocity := _cannon.get_launch_velocity()
	coverage_before_shot = _paint_system.coverage_percent()
	var shot_observation := ShotObservation.new()
	shot_observation.configure(
		stage_data.maximum_shots - shots_remaining + 1,
		_cannon.yaw_degrees,
		_cannon.elevation_degrees,
		_cannon.power_percent,
		coverage_before_shot
	)
	_inactive_settlement_ticks = 0
	_last_applied_paint_command_tick = -1
	_last_drained_paint_command_tick = _paint_system.last_drained_physics_tick()
	_last_paint_mask_checksum = _paint_system.paint_mask_checksum()
	shot_observation.record_paint_drain(
		_last_drained_paint_command_tick,
		_last_paint_mask_checksum
	)
	var projectile := _projectile_manager.spawn_projectile(_cannon.projectile_data, launch_origin, velocity)
	if projectile == null:
		return false
	shot_observation.shot_id = projectile.shot_id
	shot_observation.peak_active_projectile_count = _projectile_manager.active_count()
	_shot_observations[projectile.shot_id] = shot_observation
	_shot_observation = shot_observation
	shots_remaining -= 1
	# A second root shot may be fired while the first family is still in motion.
	# The cannon remains interactive; only the two-family capacity guard limits fire.
	_cannon.input_enabled = true
	shots_changed.emit(shots_remaining, stage_data.maximum_shots)
	shot_fired.emit(
		stage_data.maximum_shots - shots_remaining,
		_cannon.yaw_degrees,
		_cannon.elevation_degrees,
		_cannon.power_percent
	)
	fire_action_accepted.emit(origin)
	if current_state == State.AIMING or current_state == State.PAINT_SETTLING:
		return _transition_to(State.PROJECTILE_IN_FLIGHT)
	return true


func restart(
		return_to_briefing: bool = true,
		origin: ActionOrigin = ActionOrigin.HUMAN
) -> bool:
	if not _origin_allowed(origin):
		return false
	if stage_data == null or _generated_layout == null or _cannon == null \
			or _projectile_manager == null or _paint_system == null:
		return false
	if not _generated_layout.is_runtime_ready():
		push_error("Stage restart rejected because its generated layout is incomplete.")
		return false
	var default_aim := _generated_layout.default_aim
	if default_aim == null or not default_aim.is_valid():
		push_error("Stage restart rejected because its generated default aim is invalid.")
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
	_shot_observations.clear()
	_sealed_shot_observations.clear()
	_inactive_settlement_ticks = 0
	_set_terminal_pending(false)
	_last_applied_paint_command_tick = -1
	_last_drained_paint_command_tick = -1
	_last_paint_mask_checksum = _paint_system.paint_mask_checksum()
	_cannon.set_aim(
		default_aim.yaw_degrees,
		default_aim.elevation_degrees,
		float(default_aim.power_percent),
		true
	)
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


func sealed_shot_observations() -> Array[ShotObservation]:
	var result: Array[ShotObservation] = []
	var ids := _sealed_shot_observations.keys()
	ids.sort()
	for shot_id in ids:
		var observation := _sealed_shot_observations[shot_id] as ShotObservation
		if observation != null:
			result.append(observation)
	return result


static func result_state_for(
		coverage: float,
		target: float,
		remaining_shots: int,
		paint_command_rejection_count: int = 0
) -> State:
	if paint_command_rejection_count > 0:
		return State.STAGE_FAILED
	if coverage + 0.0001 >= target:
		return State.STAGE_CLEAR
	if remaining_shots <= 0:
		return State.STAGE_FAILED
	return State.AIMING


func _on_all_projectiles_settled() -> void:
	if current_state != State.PROJECTILE_IN_FLIGHT \
			or _projectile_manager.active_count() > 0 \
			or _projectile_manager.pending_intent_count() > 0:
		return
	_transition_to(State.PAINT_SETTLING)
	_inactive_settlement_ticks = 0
	_decision_generation += 1


func _physics_process(_delta: float) -> void:
	# A family can finish on the same tick that its final paint intent is
	# canonicalized. The manager's historical all-settled signal is intentionally
	# conservative for the rapid-fire path, so poll the shared activity contract
	# here as well; this prevents the board from remaining in PROJECTILE_IN_FLIGHT
	# after the last queued mark has drained.
	if current_state == State.PROJECTILE_IN_FLIGHT \
			and _projectile_manager.active_count() == 0 \
			and _projectile_manager.pending_intent_count() == 0:
		_on_all_projectiles_settled()
	if current_state != State.PAINT_SETTLING:
		return
	var projectiles_inactive := _projectile_manager.active_count() == 0 \
			and _projectile_manager.pending_intent_count() == 0
	var paint_inactive := _paint_system.pending_work_count() == 0
	var drain_covers_last_command := _last_drained_paint_command_tick \
			>= _last_applied_paint_command_tick
	if projectiles_inactive and paint_inactive and drain_covers_last_command:
		_inactive_settlement_ticks += 1
	else:
		_inactive_settlement_ticks = 0
	if _inactive_settlement_ticks < 2:
		return
	_inactive_settlement_ticks = 0
	_seal_shot(_decision_generation)


func _seal_shot(generation: int) -> void:
	if generation != _decision_generation or current_state != State.PAINT_SETTLING:
		return
	_paint_system.force_flush_paint_texture()
	var coverage := _paint_system.coverage_percent()
	var total_gain := 0.0
	_last_paint_mask_checksum = _paint_system.paint_mask_checksum()
	for observation in _ordered_observations():
		if observation.is_sealed:
			continue
		observation.seal(
			coverage,
			_last_drained_paint_command_tick,
			_last_paint_mask_checksum
		)
		_sealed_shot_observations[observation.shot_id] = observation
		_sealed_shot_observation = observation
		total_gain += observation.coverage_gain
		shot_observation_sealed.emit(observation)
	if coverage + 0.0001 >= stage_data.target_coverage or shots_remaining <= 0:
		_set_terminal_pending(true)
	_transition_to(State.SHOT_RESULT)
	shot_result.emit(total_gain, coverage)
	_finish_shot_result.call_deferred(generation, coverage)


func _finish_shot_result(generation: int, coverage: float) -> void:
	await get_tree().create_timer(SHOT_RESULT_DURATION, true, false, true).timeout
	if generation != _decision_generation or current_state != State.SHOT_RESULT:
		return
	var rejection_count := 0
	for observation in _sealed_shot_observations.values():
		rejection_count += observation.paint_command_rejection_count
	var result := result_state_for(
		coverage,
		stage_data.target_coverage,
		shots_remaining,
		rejection_count
	)
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


func _on_projectile_contact_reported(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	var observation := _observation_for_projectile(projectile)
	if observation == null or contact == null:
		return
	var category: StringName = &"world"
	if _terrain_surface.is_top_collider(contact.collider):
		category = &"terrain"
	elif contact.collider is CollisionObject3D and (contact.collider.collision_layer & 4) != 0:
		category = &"mechanism"
	observation.record_contact(
		projectile.spawn_ordinal if is_instance_valid(projectile) else -1,
		contact,
		category
	)


func _on_paint_command_applied(
		command,
		_written_pixel_count: int,
		_newly_painted_pixel_count: int
) -> void:
	var observation := _observation_for_shot(int(command.shot_id)) if command != null else null
	if observation == null or command == null \
			or current_state not in [State.PROJECTILE_IN_FLIGHT, State.PAINT_SETTLING]:
		return
	var command_tick := int(command.physics_tick)
	_last_applied_paint_command_tick = maxi(_last_applied_paint_command_tick, command_tick)
	observation.record_paint_command(command_tick)


func _on_paint_command_rejected(command) -> void:
	var observation := _observation_for_shot(int(command.shot_id)) if command != null else null
	if observation == null \
			or current_state not in [State.PROJECTILE_IN_FLIGHT, State.PAINT_SETTLING]:
		return
	observation.record_paint_command_rejection(command)
	push_warning(
		"Stage shot recorded a rejected authoritative paint command and will fail closed."
	)


func _on_paint_commands_drained(
		last_drained_physics_tick: int,
		_command_count: int,
		paint_mask_checksum: int
) -> void:
	if current_state not in [State.PROJECTILE_IN_FLIGHT, State.PAINT_SETTLING]:
		return
	_last_drained_paint_command_tick = maxi(
		_last_drained_paint_command_tick,
		last_drained_physics_tick
	)
	_last_paint_mask_checksum = paint_mask_checksum
	for observation_variant in _shot_observations.values():
		var observation := observation_variant as ShotObservation
		if observation != null and not observation.is_sealed:
			observation.record_paint_drain(
				_last_drained_paint_command_tick,
				paint_mask_checksum
			)


func _on_projectile_stopped(projectile: PaintProjectile, reason: StringName) -> void:
	var observation := _observation_for_projectile(projectile)
	if observation != null:
		observation.record_settlement(
			projectile.spawn_ordinal if is_instance_valid(projectile) else -1,
			reason,
			Engine.get_physics_frames()
		)


func _on_projectile_spawned(projectile: PaintProjectile) -> void:
	var observation := _observation_for_projectile(projectile)
	if observation != null:
		if projectile.split_generation > 0:
			observation.record_child_spawn(
				projectile.spawn_ordinal,
				projectile.split_generation,
				Engine.get_physics_frames(),
				_projectile_manager.active_count()
			)
		else:
			observation.peak_active_projectile_count = maxi(
				observation.peak_active_projectile_count,
				_projectile_manager.active_count()
			)


func _on_projectile_activity_changed(
		active_shot_ids: PackedInt64Array,
		active_projectiles: int
) -> void:
	shot_family_activity_changed.emit(
		active_shot_ids,
		active_projectiles,
		MAX_CONCURRENT_ROOT_SHOTS
	)


func _set_terminal_pending(pending: bool) -> void:
	if _terminal_pending == pending:
		return
	_terminal_pending = pending
	terminal_pending_changed.emit(pending)


func _on_mechanism_activated(
		mechanism: GimmickBase,
		projectile: PaintProjectile,
		kind: MechanismData.Kind
) -> void:
	var observation := _observation_for_projectile(projectile)
	if observation != null:
		observation.record_mechanism_activation(
			projectile.spawn_ordinal if is_instance_valid(projectile) else -1,
			StringName(mechanism.name) if is_instance_valid(mechanism) else &"",
			kind,
			Engine.get_physics_frames()
		)


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


func _origin_allowed(origin: ActionOrigin) -> bool:
	return _locked_action_origin < 0 or _locked_action_origin == origin


func _observation_for_shot(shot_id: int) -> ShotObservation:
	if shot_id <= 0:
		return _shot_observation
	return _shot_observations.get(shot_id) as ShotObservation


func _observation_for_projectile(projectile: PaintProjectile) -> ShotObservation:
	return _observation_for_shot(projectile.shot_id if is_instance_valid(projectile) else 0)


func _ordered_observations() -> Array[ShotObservation]:
	var result: Array[ShotObservation] = []
	var ids := _shot_observations.keys()
	ids.sort()
	for shot_id in ids:
		var observation := _shot_observations[shot_id] as ShotObservation
		if observation != null:
			result.append(observation)
	return result
