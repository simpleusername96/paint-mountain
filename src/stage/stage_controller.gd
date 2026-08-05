class_name StageController
extends Node

signal state_changed(current_state: int, previous_state: int)
signal shots_changed(shots_remaining: int, maximum_shots: int)
signal shot_fired(shot_number: int, yaw: float, elevation: float, power: float)
signal shot_result(coverage_gain: float, total_coverage: float)
signal shot_observation_sealed(observation: ShotObservation)
# Retained only so older scenes and replay tooling still parse during migration.
# Live attempts emit stage_finished instead of pass/fail signals.
signal stage_cleared(final_coverage: float, shots_used: int)
signal stage_failed(final_coverage: float, missing_coverage: float)
signal restart_completed(elapsed_milliseconds: float)
signal aim_action_accepted(yaw: float, elevation: float, power: float, origin: int)
signal fire_action_accepted(origin: int)
signal restart_action_accepted(origin: int)
signal finish_action_accepted(origin: int)
signal shot_family_activity_changed(active_shot_ids: PackedInt64Array, active_projectiles: int, fire_capacity: int)
signal terminal_pending_changed(pending: bool)
signal fire_readiness_changed(snapshot: Dictionary)
signal stage_clock_started(duration_ticks: int)
signal stage_clock_changed(elapsed_ticks: int, remaining_ticks: int)
signal stage_finished(result: Dictionary)

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
	# Deprecated serialized aliases retained for replay decoding only. The live
	# board never enters these motion/result states; shot activity is orthogonal.
	PROJECTILE_IN_FLIGHT,
	PAINT_SETTLING,
	SHOT_RESULT,
	STAGE_CLEAR,
	STAGE_FAILED,
	PAUSED,
	# Appended so legacy serialized state integers above remain decodable.
	FINISHING,
	RESULT,
}

const MAX_CONCURRENT_ROOT_SHOTS := 2
const SETTLEMENT_OBSERVER_PRIORITY := 1100
const CONTAINMENT_DOMAIN_PROOF := preload("res://src/terrain/containment_domain_proof.gd")
const FINISH_REASON_MANUAL := &"manual"
const FINISH_REASON_TIMEOUT := &"timeout"
const FINISH_REASON_DEBUG := &"debug"

var current_state: State = State.LOADING
var stage_data: StageData
var shots_remaining: int = 0
var coverage_before_shot: float = 0.0

var _cannon: CannonController
var _projectile_manager: ProjectileManager
var _paint_system: PaintSystem
var _terrain_surface: TerrainSurface
var _generated_layout: GeneratedStageLayout
var _mechanisms: Array[TerrainGlyphMechanism] = []
var _state_before_pause: State = State.BRIEFING
var _decision_generation: int = 0
var _shot_observation: ShotObservation
var _sealed_shot_observation: ShotObservation
var _shot_observations: Dictionary = {}
var _sealed_shot_observations: Dictionary = {}
var _shot_ids_pending_observation_seal: Dictionary = {}
var _inactive_settlement_ticks: int = 0
var _last_finished_family_physics_tick: int = -1
var _last_applied_paint_command_tick: int = -1
var _last_drained_paint_command_tick: int = -1
var _last_paint_mask_checksum: int = 0
var _locked_action_origin: int = -1
var _terminal_pending := false
var _last_fire_readiness_key := ""
var _run_started := false
var _elapsed_run_ticks := 0
var _duration_run_ticks := 0
var _result_snapshot: Dictionary = {}


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
		mechanisms: Array[TerrainGlyphMechanism] = []
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
	if not _cannon.prediction_changed.is_connected(_on_prediction_changed):
		_cannon.prediction_changed.connect(_on_prediction_changed)
	_projectile_manager.stage_bounds = _generated_layout.containment.containment_bounds
	if not _projectile_manager.shot_family_finished.is_connected(_on_shot_family_finished):
		_projectile_manager.shot_family_finished.connect(_on_shot_family_finished)
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


func fire_readiness_snapshot(origin: ActionOrigin = ActionOrigin.HUMAN) -> Dictionary:
	var active_roots := _projectile_manager.active_root_count() if _projectile_manager != null else 0
	var active_bodies := _projectile_manager.active_count() if _projectile_manager != null else 0
	var remaining_capacity := maxi(MAX_CONCURRENT_ROOT_SHOTS - active_roots, 0)
	var editable := _cannon != null and _cannon.input_enabled \
			and current_state == State.AIMING and _origin_allowed(origin)
	var prediction := _cannon.current_prediction() if _cannon != null else null
	var prediction_status: StringName = _cannon.prediction_status() if _cannon != null else &"pending"
	var prediction_key: StringName = _cannon.prediction_key() if _cannon != null else &""
	var key := _aim_key()
	var reason := ""
	var reason_key := "ready"
	var fireable := editable and shots_remaining > 0 and not _terminal_pending \
			and active_roots < MAX_CONCURRENT_ROOT_SHOTS \
			and prediction_status == &"fireable" and prediction != null \
			and _cannon.is_aim_valid() and prediction_key == key
	if not editable:
		reason_key = "not_editable"
		reason = tr("fire.not_editable")
	elif shots_remaining <= 0:
		reason_key = "empty"
		reason = tr("fire.empty")
	elif _terminal_pending:
		reason_key = "terminal"
		reason = tr("fire.terminal")
	elif prediction_status == &"pending":
		reason_key = "pending"
		reason = tr("fire.pending")
	elif prediction_status == &"invalid":
		reason_key = "invalid"
		reason = tr("fire.invalid")
	elif active_roots >= MAX_CONCURRENT_ROOT_SHOTS:
		reason_key = "capacity"
		reason = tr("fire.capacity")
	return {
		"phase": state_name(),
		"editable": editable,
		"prediction": prediction,
		"prediction_status": prediction_status,
		"prediction_key": key,
		"prediction_aim_key": prediction_key,
		"active_root_count": active_roots,
		"active_body_count": active_bodies,
		"fire_capacity": remaining_capacity,
		"max_fire_capacity": MAX_CONCURRENT_ROOT_SHOTS,
		"shots_remaining": shots_remaining,
		"terminal_pending": _terminal_pending,
		"action_lock": _locked_action_origin,
		"fireable": fireable,
		"reason_key": reason_key,
		"reason": reason,
	}


func activity_snapshot() -> Dictionary:
	var active_root_count := _projectile_manager.active_root_count() \
			if _projectile_manager != null else 0
	if _projectile_manager == null:
		return {
			"active_shot_ids": PackedInt64Array(),
			"active_projectiles": 0,
			"fire_capacity": MAX_CONCURRENT_ROOT_SHOTS,
		}
	return {
		"active_shot_ids": _projectile_manager.active_shot_ids(),
		"active_projectiles": _projectile_manager.active_count(),
		"active_root_count": active_root_count,
		"fire_capacity": maxi(MAX_CONCURRENT_ROOT_SHOTS - active_root_count, 0),
		"terminal_pending": _terminal_pending,
	}


func clock_snapshot() -> Dictionary:
	return {
		"started": _run_started,
		"elapsed_ticks": _elapsed_run_ticks,
		"remaining_ticks": remaining_run_ticks(),
		"duration_ticks": _duration_run_ticks,
		"finished": not _result_snapshot.is_empty(),
	}


func result_snapshot() -> Dictionary:
	return _result_snapshot.duplicate(true)


func run_has_started() -> bool:
	return _run_started


func elapsed_run_ticks() -> int:
	return _elapsed_run_ticks


func remaining_run_ticks() -> int:
	return maxi(_duration_run_ticks - _elapsed_run_ticks, 0)


func lock_action_origin(origin: ActionOrigin) -> bool:
	if _locked_action_origin >= 0 and _locked_action_origin != origin:
		return false
	_locked_action_origin = origin
	_emit_fire_readiness()
	return true


func release_action_origin(origin: ActionOrigin) -> bool:
	if _locked_action_origin != origin:
		return false
	_locked_action_origin = -1
	_emit_fire_readiness()
	return true


func action_origin_is_locked() -> bool:
	return _locked_action_origin >= 0


func begin_aiming(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state != State.BRIEFING:
		return false
	_cannon.input_enabled = true
	var transitioned := _transition_to(State.AIMING)
	if transitioned:
		# The BRIEFING snapshot is intentionally non-editable. Publish the new
		# state immediately so the HUD cannot retain a stale disabled Fire button.
		_emit_fire_readiness()
	return transitioned


func enter_briefing(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state != State.AIMING or _run_started:
		return false
	_cannon.input_enabled = false
	var transitioned := _transition_to(State.BRIEFING)
	if transitioned:
		_emit_fire_readiness()
	return transitioned


func set_aim(yaw: float, elevation: float, power: float, origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin) \
			or current_state != State.AIMING \
			or not _cannon.input_enabled:
		return false
	_cannon.set_aim(yaw, elevation, power)
	aim_action_accepted.emit(_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent, origin)
	_emit_fire_readiness()
	return true


func request_fire(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	# Wind-aware previews carry an intended launch tick. Refresh synchronously at
	# the admission boundary so human, replay, and agent Fire use the same current
	# schedule sample instead of launching an older preview.
	_cannon.refresh_prediction_for_fire()
	var readiness := fire_readiness_snapshot(origin)
	if not bool(readiness.get("fireable", false)):
		# Fire is admitted only from this snapshot. In particular, a prediction
		# for an older AimTuple can never be launched while the next key is pending.
		_emit_fire_readiness()
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
	_start_run_clock()
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
	_emit_fire_readiness()
	return true


func restart(
		return_to_briefing: bool = true,
		origin: ActionOrigin = ActionOrigin.HUMAN
) -> bool:
	if not _origin_allowed(origin) or current_state == State.FINISHING:
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
	_shot_ids_pending_observation_seal.clear()
	_inactive_settlement_ticks = 0
	_last_finished_family_physics_tick = -1
	_reset_run_clock()
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
	var restart_state := State.BRIEFING if return_to_briefing else State.AIMING
	_state_before_pause = restart_state
	_transition_to(restart_state, true)
	var elapsed_ms := float(Time.get_ticks_usec() - started_at) / 1000.0
	restart_completed.emit(elapsed_ms)
	restart_action_accepted.emit(origin)
	_emit_fire_readiness()
	return true


func toggle_pause(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if not _origin_allowed(origin):
		return false
	if current_state == State.PAUSED:
		get_tree().paused = false
		return _transition_to(_state_before_pause, true)
	if current_state in [
		State.LOADING,
		State.FINISHING,
		State.RESULT,
		State.STAGE_CLEAR,
		State.STAGE_FAILED,
	]:
		return false
	_state_before_pause = current_state
	get_tree().paused = true
	return _transition_to(State.PAUSED, true)


func finish_stage(origin: ActionOrigin = ActionOrigin.HUMAN) -> bool:
	if origin not in [ActionOrigin.HUMAN, ActionOrigin.REPLAY, ActionOrigin.AGENT] \
			or not _origin_allowed(origin) or current_state != State.AIMING \
			or not _run_started or _terminal_pending:
		return false
	return _begin_finish(FINISH_REASON_MANUAL, origin, false, true)


func force_stage_clear(origin: ActionOrigin = ActionOrigin.DEBUG) -> void:
	# Compatibility entrypoint for debug and capture scripts. Normal gameplay
	# reaches the same coverage-only RESULT through finish_stage or timeout.
	if not _origin_allowed(origin):
		return
	if current_state == State.PAUSED:
		get_tree().paused = false
		_transition_to(_state_before_pause, true)
	if current_state not in [State.BRIEFING, State.AIMING]:
		return
	_begin_finish(FINISH_REASON_DEBUG, origin, true)


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


func _reset_run_clock() -> void:
	_run_started = false
	_elapsed_run_ticks = 0
	_result_snapshot.clear()
	var ticks_per_second := maxi(Engine.physics_ticks_per_second, 1)
	_duration_run_ticks = maxi(
		roundi(stage_data.resolved_duration_seconds() * float(ticks_per_second)),
		1
	)
	stage_clock_changed.emit(_elapsed_run_ticks, remaining_run_ticks())


func _start_run_clock() -> void:
	if _run_started:
		return
	_run_started = true
	stage_clock_started.emit(_duration_run_ticks)
	stage_clock_changed.emit(_elapsed_run_ticks, remaining_run_ticks())


func _begin_finish(
		reason: StringName,
		action_origin: int,
		allow_before_first_shot: bool = false,
		emit_finish_acceptance: bool = false
) -> bool:
	if _terminal_pending or current_state not in [State.BRIEFING, State.AIMING]:
		return false
	if not allow_before_first_shot and not _run_started:
		return false
	_decision_generation += 1
	_cannon.input_enabled = false
	_set_terminal_pending(true)
	if not _transition_to(State.FINISHING, allow_before_first_shot):
		_set_terminal_pending(false)
		_cannon.input_enabled = true
		return false
	if emit_finish_acceptance:
		finish_action_accepted.emit(action_origin)

	# ProjectileManager owns canonical ordering for contact-generated paint. Its
	# result barrier hands every already accepted intent to PaintSystem before
	# resident cleanup; later contacts cannot enter once FINISHING is active.
	_projectile_manager.finalize_pending_paint_intents()
	_paint_system.force_flush_paint_texture()
	_last_drained_paint_command_tick = _paint_system.last_drained_physics_tick()
	_last_paint_mask_checksum = _paint_system.paint_mask_checksum()
	var final_coverage := _paint_system.coverage_percent()
	_seal_open_observations_for_result(final_coverage)

	var rejection_count := 0
	for observation_variant in _shot_observations.values():
		var observation := observation_variant as ShotObservation
		if observation != null:
			rejection_count += observation.paint_command_rejection_count
	_result_snapshot = {
		"stage_id": stage_data.stage_id,
		"finish_reason": reason,
		"action_origin": action_origin,
		"coverage": final_coverage,
		"shots_used": stage_data.maximum_shots - shots_remaining,
		"shots_remaining": shots_remaining,
		"elapsed_ticks": _elapsed_run_ticks,
		"duration_ticks": _duration_run_ticks,
		"paint_mask_checksum": _last_paint_mask_checksum,
		"paint_command_rejection_count": rejection_count,
	}

	# Cleanup happens after the immutable score inputs above are captured.
	_projectile_manager.cleanup()
	_transition_to(State.RESULT)
	_emit_fire_readiness()
	stage_clock_changed.emit(_elapsed_run_ticks, remaining_run_ticks())
	stage_finished.emit(_result_snapshot.duplicate(true))
	return true


static func result_state_for(
		coverage: float,
		target: float,
		remaining_shots: int,
		paint_command_rejection_count: int = 0
) -> State:
	# Legacy replay/test decoder only. Live attempts no longer use target coverage
	# or ammunition exhaustion to choose a terminal state.
	if paint_command_rejection_count > 0:
		return State.STAGE_FAILED
	if coverage + 0.0001 >= target:
		return State.STAGE_CLEAR
	if remaining_shots <= 0:
		return State.STAGE_FAILED
	return State.AIMING


func _on_shot_family_finished(shot_id: int) -> void:
	var observation := _observation_for_shot(shot_id)
	if current_state != State.AIMING or observation == null or observation.is_sealed:
		return
	_shot_ids_pending_observation_seal[shot_id] = true
	_inactive_settlement_ticks = 0
	_last_finished_family_physics_tick = Engine.get_physics_frames()


func _physics_process(_delta: float) -> void:
	# Initial-flight families and resident paintballs have separate lifecycles.
	# Once a family first rests or terminates, only its observation waits for the
	# authoritative paint queues to stay drained for two complete physics ticks.
	if current_state == State.AIMING:
		var paint_intents_inactive := _projectile_manager.pending_intent_count() == 0
		var paint_inactive := _paint_system.pending_work_count() == 0
		var drain_covers_last_command := _last_drained_paint_command_tick \
				>= _last_applied_paint_command_tick
		var family_finish_tick_has_passed := Engine.get_physics_frames() \
				> _last_finished_family_physics_tick
		if not _shot_ids_pending_observation_seal.is_empty() \
				and family_finish_tick_has_passed \
				and paint_intents_inactive and paint_inactive \
				and drain_covers_last_command:
			_inactive_settlement_ticks += 1
		else:
			_inactive_settlement_ticks = 0
		if _inactive_settlement_ticks >= 2:
			_inactive_settlement_ticks = 0
			_seal_finished_shot_observations(_decision_generation)
		if _run_started:
			_elapsed_run_ticks = mini(_elapsed_run_ticks + 1, _duration_run_ticks)
			stage_clock_changed.emit(_elapsed_run_ticks, remaining_run_ticks())
			if _elapsed_run_ticks >= _duration_run_ticks:
				_begin_finish(FINISH_REASON_TIMEOUT, -1)
	return


func _seal_finished_shot_observations(generation: int) -> void:
	if generation != _decision_generation or current_state != State.AIMING:
		return
	if _shot_ids_pending_observation_seal.is_empty():
		return
	_paint_system.force_flush_paint_texture()
	var coverage := _paint_system.coverage_percent()
	_last_drained_paint_command_tick = _paint_system.last_drained_physics_tick()
	_last_paint_mask_checksum = _paint_system.paint_mask_checksum()
	var total_gain := 0.0
	var sealed_any := false
	var shot_ids := _shot_ids_pending_observation_seal.keys()
	shot_ids.sort()
	for shot_id in shot_ids:
		_shot_ids_pending_observation_seal.erase(shot_id)
		var observation := _observation_for_shot(int(shot_id))
		if _seal_observation(observation, coverage):
			total_gain += observation.coverage_gain
			sealed_any = true
	if sealed_any:
		shot_result.emit(total_gain, coverage)


func _seal_open_observations_for_result(coverage: float) -> void:
	var total_gain := 0.0
	_last_drained_paint_command_tick = _paint_system.last_drained_physics_tick()
	_last_paint_mask_checksum = _paint_system.paint_mask_checksum()
	var sealed_any := false
	for observation in _ordered_observations():
		if _seal_observation(observation, coverage):
			total_gain += observation.coverage_gain
			sealed_any = true
	_shot_ids_pending_observation_seal.clear()
	if sealed_any:
		shot_result.emit(total_gain, coverage)


func _seal_observation(observation: ShotObservation, coverage: float) -> bool:
	if observation == null or observation.is_sealed:
		return false
	observation.seal(
		coverage,
		_last_drained_paint_command_tick,
		_last_paint_mask_checksum
	)
	_sealed_shot_observations[observation.shot_id] = observation
	_sealed_shot_observation = observation
	shot_observation_sealed.emit(observation)
	return true


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
			or current_state not in [State.AIMING, State.FINISHING]:
		return
	var command_tick := int(command.physics_tick)
	_last_applied_paint_command_tick = maxi(_last_applied_paint_command_tick, command_tick)
	observation.record_paint_command(command_tick)


func _on_paint_command_rejected(command) -> void:
	var observation := _observation_for_shot(int(command.shot_id)) if command != null else null
	if observation == null or current_state not in [State.AIMING, State.FINISHING]:
		return
	observation.record_paint_command_rejection(command)
	push_warning(
		"Stage shot recorded a rejected authoritative paint command; result coverage uses accepted paint only."
	)


func _on_paint_commands_drained(
		last_drained_physics_tick: int,
		_command_count: int,
		paint_mask_checksum: int
) -> void:
	if current_state not in [State.AIMING, State.FINISHING]:
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
		maxi(MAX_CONCURRENT_ROOT_SHOTS - _projectile_manager.active_root_count(), 0)
	)
	_emit_fire_readiness()


func _on_prediction_changed(_prediction: TrajectoryPrediction) -> void:
	# Prediction status is part of the StageController-owned Fire contract. The
	# HUD never listens to Cannon validity directly, so a matching-key result
	# must be republished through the same snapshot path as aim and activity.
	_emit_fire_readiness()


func _set_terminal_pending(pending: bool) -> void:
	if _terminal_pending == pending:
		return
	_terminal_pending = pending
	terminal_pending_changed.emit(pending)
	_emit_fire_readiness()


func _aim_key() -> String:
	if _cannon == null:
		return ""
	return AimTuple.new(_cannon.yaw_degrees, _cannon.elevation_degrees, int(_cannon.power_percent)).stable_key()


func _emit_fire_readiness() -> void:
	var snapshot := fire_readiness_snapshot()
	var key := "%s|%s|%s|%d|%d|%s" % [
		String(snapshot.get("phase", "")),
		String(snapshot.get("prediction_key", "")),
		String(snapshot.get("reason_key", "")),
		int(snapshot.get("active_root_count", 0)),
		int(snapshot.get("shots_remaining", 0)),
		str(snapshot.get("fireable", false)),
	]
	if key == _last_fire_readiness_key:
		return
	_last_fire_readiness_key = key
	fire_readiness_changed.emit(snapshot)


func _on_mechanism_activated(
		mechanism: TerrainGlyphMechanism,
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
			return to_state in [State.BRIEFING, State.PAUSED, State.FINISHING]
		State.FINISHING:
			return to_state == State.RESULT
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
