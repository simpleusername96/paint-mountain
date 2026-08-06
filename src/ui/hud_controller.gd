class_name HUDController
extends CanvasLayer

signal begin_aiming_requested
signal fire_requested
signal restart_requested
signal pause_requested
signal settings_requested
signal stage_select_requested
signal main_menu_requested
signal next_stage_requested
signal replay_requested
signal finish_requested
signal interaction_mode_requested(mode: int)
signal replay_speed_requested(speed: float)
signal power_step_requested(direction: float)
signal replay_pause_requested(paused: bool)
signal replay_restart_requested
signal replay_exit_requested

static var _first_session_hint_seen := false

@onready var _top: TopStatusBar = %TopStatusBar
@onready var _aim: AimControls = %AimControls
@onready var _coverage: CoverageMeter = %CoverageMeter
@onready var _actions: ActionButtons = %ActionButtons
@onready var _run_status: RunStatusCard = %RunStatusCard
@onready var _interaction: CameraInteractionControl = %CameraInteractionControl
@onready var _shot_summary: ShotSummary = %ShotSummary
@onready var _result: ResultPanel = %ResultPanel
@onready var _replay: ReplayBar = %ReplayBar
@onready var _mechanism: MechanismInfoCard = %MechanismInfoCard
@onready var _briefing: PanelContainer = %BriefingPanel
@onready var _pause: PauseOverlay = %PauseOverlay
@onready var _first_hint: PanelContainer = %FirstSessionHint
@onready var _hint_timer: Timer = %HintTimer
var _stage_data: StageData
var _current_state := StageController.State.LOADING
var _shots_remaining := 0
var _replay_active := false
var _hint_pending := false
var _last_aim := Vector3.ZERO
var _last_coverage := 0.0
var _current_interaction_mode := CameraDirector.InteractionMode.AIM_LOCKED
var _run_started := false
var _clock_finished := false
var _resident_total := 0
var _moving_residents := 0
var _resting_residents := 0
var _has_resident_breakdown := false
var _pause_overlay_suspended := false


func update_activity(
		_active_shot_ids: PackedInt64Array,
		active_projectiles: int,
		_fire_capacity: int
) -> void:
	# Resident-ball activity no longer changes camera controls. The interaction
	# toggle belongs to the Board Phase and remains stable while balls move.
	_resident_total = maxi(active_projectiles, 0)
	_has_resident_breakdown = false
	_run_status.update_resident_total(_resident_total)


func update_resident_activity(moving: int, resting: int) -> void:
	_moving_residents = maxi(moving, 0)
	_resting_residents = maxi(resting, 0)
	_resident_total = _moving_residents + _resting_residents
	_has_resident_breakdown = true
	_run_status.update_resident_activity(_moving_residents, _resting_residents)


func update_clock(snapshot: Dictionary) -> void:
	_run_started = bool(snapshot.get("started", false))
	_clock_finished = bool(snapshot.get("finished", false))
	_run_status.update_clock(snapshot)
	_apply_finish_availability()


func update_wind(
		snapshot: WindSnapshot,
		screen_direction: Vector2,
		depth_cue: RunStatusCard.DepthCue = RunStatusCard.DepthCue.NONE,
		next_screen_direction: Vector2 = Vector2.ZERO,
		next_depth_cue: RunStatusCard.DepthCue = RunStatusCard.DepthCue.NONE
) -> void:
	_run_status.update_wind(
		snapshot,
		screen_direction,
		depth_cue,
		next_screen_direction,
		next_depth_cue
	)


func _ready() -> void:
	_replay_active = false
	_replay.hide()
	_connect_components()
	_hint_timer.timeout.connect(func() -> void: _first_hint.visible = false)
	get_node("/root/GameState").settings_changed.connect(_on_settings_changed)


func configure(stage_data: StageData) -> void:
	_stage_data = stage_data
	_top.configure(stage_data)
	_coverage.configure(stage_data.target_coverage)
	_run_started = false
	_clock_finished = false
	_moving_residents = 0
	_resting_residents = 0
	_resident_total = 0
	_has_resident_breakdown = false
	_run_status.reset_for_stage(stage_data.maximum_shots, stage_data.resolved_duration_seconds())
	_result.configure_has_next(not StageCatalog.next_stage_id(stage_data.stage_id).is_empty())
	%BriefingTitle.text = tr(String(stage_data.display_name_key))
	%BriefingObjective.text = tr(String(stage_data.objective_key))
	update_shots(stage_data.maximum_shots, stage_data.maximum_shots)
	if stage_data.stage_id == &"stage_01" and not _first_session_hint_seen:
		_hint_pending = true
		_first_hint.visible = false
	else:
		_hint_pending = false
		_first_hint.visible = false
	if stage_data.mechanism_loadout.is_empty():
		_mechanism.hide_card()
	else:
		_mechanism.show_brief(stage_data.mechanism_loadout[0].kind)


func update_aim(yaw: float, elevation: float, power: float) -> void:
	_last_aim = Vector3(yaw, elevation, power)
	_aim.update_aim(yaw, elevation, power)


func update_shots(remaining: int, _maximum: int) -> void:
	_shots_remaining = remaining
	_run_status.update_shots(remaining)


func update_coverage(value: float) -> void:
	_last_coverage = value
	_coverage.update_coverage(value)


func set_fire_readiness(snapshot: Dictionary) -> void:
	_actions.set_fire_readiness(snapshot)


func show_state(state: StageController.State) -> void:
	_current_state = state
	if state != StageController.State.AIMING:
		# The first-session input hint belongs only to the aiming surface; leaving
		# it over the live observation controls hides the ball and Fire affordance.
		_first_hint.visible = false
		_hint_timer.stop()
	_replay.visible = _replay_active
	_top.update_mode(state)
	# The interaction toggle is the only mode label during the Board Phase.
	# Keeping the serial-state "Aiming" chip beside "Map Inspection" is
	# truthful internally but contradictory to players.
	_top.mode_value.get_parent().visible = state != StageController.State.AIMING
	_briefing.visible = state == StageController.State.BRIEFING and not _replay_active
	var aiming_surface := state in [
		StageController.State.AIMING,
	]
	if aiming_surface:
		_mechanism.hide_card()
	_interaction.visible = aiming_surface and not _replay_active
	_interaction.set_mode_switch_available(aiming_surface and not _replay_active)
	_apply_interaction_presentation(false)
	_run_status.visible = aiming_surface and not _replay_active
	_apply_finish_availability()
	_coverage.visible = state not in [StageController.State.LOADING, StageController.State.BRIEFING]
	_result.visible = state == StageController.State.RESULT and not _replay_active
	_pause.visible = state == StageController.State.PAUSED and not _replay_active and not _pause_overlay_suspended
	if state == StageController.State.BRIEFING:
		%Start.grab_focus()
	elif state == StageController.State.AIMING and not _replay_active:
		if _current_interaction_mode == CameraDirector.InteractionMode.AIM_LOCKED:
			_actions.focus_fire()
		else:
			_interaction.grab_focus()
		if _hint_pending:
			_hint_pending = false
			_first_session_hint_seen = true
			_first_hint.visible = true
			_hint_timer.start()
	elif state == StageController.State.RESULT and not _replay_active:
		_result.focus_retry()
	elif state == StageController.State.PAUSED and not _replay_active:
		_pause.focus_resume.call_deferred()


func show_shot_observation(observation: ShotObservation) -> void:
	_shot_summary.show_observation(observation)


func set_interaction_mode(mode: CameraDirector.InteractionMode) -> void:
	_current_interaction_mode = mode
	_interaction.set_interaction_mode(mode)
	_apply_interaction_presentation(true)


func show_shot_result(_gain: float, _total: float) -> void:
	# ShotSummary consumes the sealed ShotObservation; this remains for the legacy signal connection.
	pass


func show_mechanism_brief(kind: MechanismData.Kind) -> void:
	if _current_state == StageController.State.BRIEFING:
		_mechanism.show_brief(kind)


func show_mechanism_activation(kind: MechanismData.Kind) -> void:
	_mechanism.show_activation(kind)


func show_coverage_result(
		final_coverage: float,
		star_count: int,
		previous_best: float = 0.0,
		elapsed_seconds: float = -1.0,
		shots_used: int = -1,
		finish_reason: StringName = &"manual"
) -> void:
	_result.show_coverage_result(
		final_coverage,
		star_count,
		previous_best,
		elapsed_seconds,
		shots_used,
		finish_reason
	)


func show_coverage_result_snapshot(result: Dictionary, star_count: int, previous_best: float = 0.0) -> void:
	var ticks_per_second := maxi(int(result.get("ticks_per_second", Engine.physics_ticks_per_second)), 1)
	var elapsed_seconds := float(result.get("elapsed_ticks", -ticks_per_second)) / float(ticks_per_second)
	show_coverage_result(
		float(result.get("coverage", 0.0)),
		star_count,
		previous_best,
		elapsed_seconds,
		int(result.get("shots_used", -1)),
		StringName(result.get("finish_reason", &"manual"))
	)


func set_replay_active(active: bool) -> void:
	_replay_active = active
	_replay.visible = active
	if active:
		_replay.reset_controls()
	show_state(_current_state)


func set_pause_overlay_suspended(suspended: bool) -> void:
	_pause_overlay_suspended = suspended
	show_state(_current_state)


func focus_pause_settings() -> void:
	_pause.focus_settings.call_deferred()


func _connect_components() -> void:
	%Start.pressed.connect(func() -> void: begin_aiming_requested.emit())
	%Back.pressed.connect(func() -> void: stage_select_requested.emit())
	_aim.power_step_requested.connect(func(direction: float) -> void: power_step_requested.emit(direction))
	_top.settings_requested.connect(func() -> void: pause_requested.emit())
	_actions.fire_requested.connect(func() -> void: fire_requested.emit())
	_run_status.finish_requested.connect(func() -> void: finish_requested.emit())
	_interaction.interaction_mode_requested.connect(
		func(mode: int) -> void: interaction_mode_requested.emit(mode)
	)
	_result.retry_requested.connect(func() -> void: restart_requested.emit())
	_result.next_requested.connect(func() -> void: next_stage_requested.emit())
	_result.stages_requested.connect(func() -> void: stage_select_requested.emit())
	_result.replay_requested.connect(func() -> void: replay_requested.emit())
	_pause.resume_requested.connect(func() -> void: pause_requested.emit())
	_pause.restart_requested.connect(func() -> void: restart_requested.emit())
	_pause.settings_requested.connect(func() -> void: settings_requested.emit())
	_pause.stages_requested.connect(func() -> void: stage_select_requested.emit())
	_pause.main_menu_requested.connect(func() -> void: main_menu_requested.emit())
	_replay.pause_toggled.connect(func(paused: bool) -> void: replay_pause_requested.emit(paused))
	_replay.restart_requested.connect(func() -> void: replay_restart_requested.emit())
	_replay.speed_requested.connect(func(speed: float) -> void: replay_speed_requested.emit(speed))
	_replay.exit_requested.connect(func() -> void: replay_exit_requested.emit())


func _on_settings_changed(_settings: Dictionary) -> void:
	_aim.refresh_locale()
	if _stage_data != null:
		_top.configure(_stage_data)
		_top.update_mode(_current_state)
		_run_status.refresh_locale()
		_run_status.update_shots(_shots_remaining)
		if _has_resident_breakdown:
			_run_status.update_resident_activity(_moving_residents, _resting_residents)
		else:
			_run_status.update_resident_total(_resident_total)
		%BriefingTitle.text = tr(String(_stage_data.display_name_key))
		%BriefingObjective.text = tr(String(_stage_data.objective_key))
		_aim.update_aim(_last_aim.x, _last_aim.y, _last_aim.z)
		_interaction.refresh_locale()
		_result.refresh_locale()
		_coverage.configure(_stage_data.target_coverage)
		_coverage.update_coverage(_last_coverage)
		if _current_state == StageController.State.BRIEFING and not _stage_data.mechanism_loadout.is_empty():
			_mechanism.show_brief(_stage_data.mechanism_loadout[0].kind)
	show_state(_current_state)


func _apply_interaction_presentation(update_focus: bool) -> void:
	var aim_locked := _current_interaction_mode == CameraDirector.InteractionMode.AIM_LOCKED
	var aiming_surface := _current_state == StageController.State.AIMING and not _replay_active
	_aim.visible = aiming_surface and aim_locked
	_actions.visible = aiming_surface and aim_locked
	if not aiming_surface:
		return
	if not aim_locked:
		_first_hint.visible = false
		_hint_timer.stop()
	if not update_focus:
		return
	if aim_locked:
		_actions.focus_fire.call_deferred()
	else:
		_interaction.grab_focus.call_deferred()


func _apply_finish_availability() -> void:
	_run_status.set_finish_available(
		_run_started
		and not _clock_finished
		and _current_state == StageController.State.AIMING
		and not _replay_active
	)
