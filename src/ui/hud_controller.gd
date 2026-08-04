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
signal camera_mode_requested(mode: int)
signal simulation_speed_requested(speed: float)
signal power_step_requested(direction: float)
signal replay_pause_requested(paused: bool)
signal replay_restart_requested
signal replay_exit_requested

static var _first_session_hint_seen := false

@onready var _top: TopStatusBar = %TopStatusBar
@onready var _aim: AimControls = %AimControls
@onready var _coverage: CoverageMeter = %CoverageMeter
@onready var _actions: ActionButtons = %ActionButtons
@onready var _observation: ObservationControls = %ObservationControls
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
	_result.configure_has_next(not StageCatalog.next_stage_id(stage_data.stage_id).is_empty())
	%BriefingTitle.text = tr(String(stage_data.display_name_key))
	%BriefingObjective.text = tr(String(stage_data.objective_key))
	update_shots(stage_data.maximum_shots, stage_data.maximum_shots)
	if stage_data.stage_id == &"first_descent" and not _first_session_hint_seen:
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
	_top.update_shots(remaining)


func update_coverage(value: float) -> void:
	_last_coverage = value
	_coverage.update_coverage(value)


func set_fire_enabled(enabled: bool) -> void:
	_actions.set_fire_enabled(enabled)


func show_state(state: StageController.State) -> void:
	_current_state = state
	_replay.visible = _replay_active
	_top.update_mode(state)
	_briefing.visible = state == StageController.State.BRIEFING and not _replay_active
	if state in [StageController.State.AIMING, StageController.State.PROJECTILE_IN_FLIGHT]:
		_mechanism.hide_card()
	_aim.visible = state == StageController.State.AIMING and not _replay_active
	_actions.visible = state == StageController.State.AIMING and not _replay_active
	_observation.visible = state in [StageController.State.PROJECTILE_IN_FLIGHT, StageController.State.PAINT_SETTLING, StageController.State.SHOT_RESULT] and not _replay_active
	_coverage.visible = state not in [StageController.State.LOADING, StageController.State.BRIEFING]
	_result.visible = state in [StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED] and not _replay_active
	_pause.visible = state == StageController.State.PAUSED and not _replay_active
	if state == StageController.State.BRIEFING:
		%Start.grab_focus()
	elif state == StageController.State.AIMING and not _replay_active:
		_actions.focus_fire()
		if _hint_pending:
			_hint_pending = false
			_first_session_hint_seen = true
			_first_hint.visible = true
			_hint_timer.start()
	elif state in [StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED] and not _replay_active:
		_result.focus_retry()
	elif state == StageController.State.PAUSED and not _replay_active:
		_pause.focus_resume.call_deferred()


func show_shot_observation(observation: ShotObservation) -> void:
	_shot_summary.show_observation(observation)


func show_shot_result(_gain: float, _total: float) -> void:
	# ShotSummary consumes the sealed ShotObservation; this remains for the legacy signal connection.
	pass


func show_mechanism_brief(kind: MechanismData.Kind) -> void:
	if _current_state == StageController.State.BRIEFING:
		_mechanism.show_brief(kind)


func show_mechanism_activation(kind: MechanismData.Kind) -> void:
	_mechanism.show_activation(kind)


func show_clear(final_coverage: float, shots_used: int, stars: int = 1, previous_best: float = 0.0) -> void:
	_result.show_clear(final_coverage, _stage_data.target_coverage, shots_used, stars, previous_best)


func show_failure(final_coverage: float, missing: float, previous_best: float = 0.0) -> void:
	_result.show_failure(final_coverage, missing, previous_best)


func set_replay_active(active: bool) -> void:
	_replay_active = active
	_replay.visible = active
	if active:
		_replay.reset_controls()
	show_state(_current_state)


func _connect_components() -> void:
	%Start.pressed.connect(func() -> void: begin_aiming_requested.emit())
	%Back.pressed.connect(func() -> void: stage_select_requested.emit())
	_aim.power_step_requested.connect(func(direction: float) -> void: power_step_requested.emit(direction))
	_top.settings_requested.connect(func() -> void: pause_requested.emit())
	_actions.fire_requested.connect(func() -> void: fire_requested.emit())
	_observation.camera_mode_requested.connect(func(mode: int) -> void: camera_mode_requested.emit(mode))
	_observation.simulation_speed_requested.connect(func(speed: float) -> void: simulation_speed_requested.emit(speed))
	_observation.pause_requested.connect(func() -> void: pause_requested.emit())
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
	_replay.speed_requested.connect(func(speed: float) -> void: simulation_speed_requested.emit(speed))
	_replay.exit_requested.connect(func() -> void: replay_exit_requested.emit())


func _on_settings_changed(_settings: Dictionary) -> void:
	if _stage_data != null:
		_top.configure(_stage_data)
		_top.update_shots(_shots_remaining)
		_top.update_mode(_current_state)
		%BriefingTitle.text = tr(String(_stage_data.display_name_key))
		%BriefingObjective.text = tr(String(_stage_data.objective_key))
		_aim.update_aim(_last_aim.x, _last_aim.y, _last_aim.z)
		_coverage.configure(_stage_data.target_coverage)
		_coverage.update_coverage(_last_coverage)
		if _current_state == StageController.State.BRIEFING and not _stage_data.mechanism_loadout.is_empty():
			_mechanism.show_brief(_stage_data.mechanism_loadout[0].kind)
	show_state(_current_state)
