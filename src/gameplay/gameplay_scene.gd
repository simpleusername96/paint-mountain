extends Node3D

signal navigation_requested(destination: StringName)

const BURST_SCENE := preload("res://scenes/mechanisms/burst_node.tscn")
const SPLITTER_SCENE := preload("res://scenes/mechanisms/splitter_node.tscn")
const BUMPER_SCENE := preload("res://scenes/mechanisms/bumper_node.tscn")
const PAINT_DEPOSIT_TUNING := preload("res://resources/paint/default_paint_deposit_tuning.tres")

@export var stage_data: StageData

@onready var _camera: Camera3D = %Camera
@onready var _terrain_surface: TerrainSurface = %TerrainSurface
@onready var _terrain_mesh: MeshInstance3D = %TerrainMesh
@onready var _cannon: CannonController = %Cannon
@onready var _trajectory_preview: TrajectoryPreview = %TrajectoryPreview
@onready var _aim_input: AimInputController = %AimInputController
@onready var _projectile_manager: ProjectileManager = %ProjectileManager
@onready var _paint_system: PaintSystem = %PaintSystem
@onready var _stage_controller: StageController = %StageController
@onready var _camera_director: CameraDirector = %CameraDirector
@onready var _hud: HUDController = %HUD
@onready var _mechanism_root: Node3D = %Mechanisms
@onready var _environment_dressing: Node3D = %EnvironmentDressing
@onready var _replay_recorder: ReplayRecorder = %ReplayRecorder
@onready var _replay_presentation: ReplayPresentationController = %ReplayPresentationController
@onready var _agent_api: GameplayAgentApi = %GameplayAgentApi
@onready var _presentation_effects: PresentationEffects = %PresentationEffects
@onready var _debug_overlay: DebugOverlay = %DebugOverlay

var _shot_has_impacted: bool = false
var _mechanisms: Array[GimmickBase] = []
var _generated_layout: GeneratedStageLayout


func _ready() -> void:
	assert(stage_data != null, "GameplayScene requires StageData.")
	var game_state := get_node_or_null("/root/GameState")
	var selected_stage := StageCatalog.get_stage(game_state.selected_stage_id if game_state != null else stage_data.stage_id)
	if selected_stage != null:
		stage_data = selected_stage
	_build_stage_world()
	_connect_systems()
	_camera_director.configure(_camera, stage_data, _projectile_manager, _terrain_surface)
	_trajectory_preview.configure(_cannon)
	_hud.configure(stage_data)
	_stage_controller.configure(stage_data, _cannon, _projectile_manager, _paint_system, _terrain_surface, _mechanisms)
	_replay_presentation.configure(_replay_recorder, _stage_controller, _camera_director)
	_aim_input.configure(_cannon, _stage_controller)
	_recompute_prediction()
	_replay_recorder.start_attempt(stage_data, stage_data.stage_number * 1000 + stage_data.stage_version, _generated_layout)
	_agent_api.configure(
		stage_data,
		_stage_controller,
		_cannon,
		_paint_system,
		_projectile_manager,
		_camera_director,
		_mechanisms,
		_generated_layout
	)
	_debug_overlay.configure(
		stage_data,
		_stage_controller,
		_cannon,
		_projectile_manager,
		_paint_system,
		_trajectory_preview,
		_camera_director,
		_mechanisms,
		_replay_recorder
	)
	_debug_overlay.replay_last_shot_requested.connect(_start_last_shot_replay)
	_debug_overlay.mechanism_labels_toggled.connect(_set_mechanism_labels_visible)
	_hud.show_state(_stage_controller.current_state)
	_hud.update_payload(_cannon.projectile_data.initial_payload, _cannon.projectile_data.initial_payload)
	print("Paint Mountain gameplay scene ready in %s." % _stage_controller.state_name())


func _process(_delta: float) -> void:
	if _stage_controller.current_state not in [StageController.State.PROJECTILE_IN_FLIGHT, StageController.State.PAINT_SETTLING]:
		return
	var aggregate_payload := 0.0
	for projectile in _projectile_manager.active_projectiles():
		aggregate_payload += projectile.remaining_payload
	_hud.update_payload(aggregate_payload, _cannon.projectile_data.initial_payload)


func generated_layout() -> GeneratedStageLayout:
	return _generated_layout


func terrain_layout_read_only() -> GeneratedStageLayout:
	return _generated_layout


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_R:
			if not _replay_presentation.active:
				_stage_controller.restart(false, StageController.ActionOrigin.HUMAN)
		KEY_ESCAPE:
			if _replay_presentation.active:
				_replay_presentation.exit()
			else:
				_stage_controller.toggle_pause(StageController.ActionOrigin.HUMAN)


func _build_stage_world() -> void:
	_terrain_surface.position = stage_data.terrain_center
	assert(stage_data.generation_profile != null, "Gameplay stages require a generation profile.")
	_generated_layout = SeededStageGenerator.generate(stage_data.generation_profile, stage_data.terrain_seed, stage_data)
	assert(_generated_layout != null, "Stage generation must produce a validated layout before briefing.")
	_terrain_surface.configure(_generated_layout)
	_projectile_manager.configure_terrain(_terrain_surface)
	_cannon.global_transform = stage_data.cannon_transform
	_cannon.set_aim(stage_data.initial_aim.x, stage_data.initial_aim.y, stage_data.initial_aim.z)
	_projectile_manager.stage_bounds = stage_data.stage_bounds
	var paint_material := ShaderMaterial.new()
	paint_material.shader = load("res://src/paint/terrain_paint.gdshader")
	_paint_system.configure(
		stage_data.paint_world_bounds(),
		stage_data.terrain_center.y,
		paint_material,
		stage_data.paint_color,
		_generated_layout,
		PAINT_DEPOSIT_TUNING
	)
	_terrain_mesh.material_override = paint_material
	_environment_dressing.configure(stage_data, _generated_layout)
	_spawn_mechanisms()


func _connect_systems() -> void:
	_cannon.aim_changed.connect(_on_aim_changed)
	_cannon.aim_validity_changed.connect(_hud.set_fire_enabled)
	_cannon.fire_requested.connect(func(_origin: Vector3, _velocity: Vector3) -> void: _stage_controller.request_fire(StageController.ActionOrigin.HUMAN))
	_projectile_manager.paint_deposit_requested.connect(_on_paint_deposit_requested)
	_projectile_manager.transient_splash_requested.connect(_on_transient_splash_requested)
	_paint_system.coverage_changed.connect(_hud.update_coverage)
	_stage_controller.state_changed.connect(_on_state_changed)
	_stage_controller.shots_changed.connect(_hud.update_shots)
	_stage_controller.shot_fired.connect(_on_shot_fired)
	_stage_controller.shot_result.connect(_on_shot_result)
	_stage_controller.shot_observation_sealed.connect(_on_shot_observation_sealed)
	_stage_controller.aim_action_accepted.connect(_on_aim_action_accepted)
	_stage_controller.fire_action_accepted.connect(_on_fire_action_accepted)
	_stage_controller.restart_action_accepted.connect(_on_restart_action_accepted)
	_stage_controller.stage_cleared.connect(_on_stage_cleared)
	_stage_controller.stage_failed.connect(_on_stage_failed)
	_hud.begin_aiming_requested.connect(func() -> void: _stage_controller.begin_aiming(StageController.ActionOrigin.HUMAN))
	_hud.fire_requested.connect(func() -> void: _aim_input.request_fire())
	_hud.power_step_requested.connect(_aim_input.adjust_power_button)
	_hud.restart_requested.connect(func() -> void: _stage_controller.restart(false, StageController.ActionOrigin.HUMAN))
	_hud.pause_requested.connect(func() -> void: _stage_controller.toggle_pause(StageController.ActionOrigin.HUMAN))
	_hud.settings_requested.connect(func() -> void: _request_navigation(&"settings"))
	_hud.stage_select_requested.connect(func() -> void: _request_navigation(&"stage_select"))
	_hud.main_menu_requested.connect(func() -> void: _request_navigation(&"main_menu"))
	_hud.next_stage_requested.connect(func() -> void: _request_navigation(&"next_stage"))
	_hud.replay_requested.connect(_start_replay)
	_hud.camera_mode_requested.connect(_on_camera_mode_requested)
	_hud.simulation_speed_requested.connect(_on_simulation_speed_requested)
	_hud.replay_pause_requested.connect(_replay_presentation.set_paused)
	_hud.replay_restart_requested.connect(_replay_presentation.restart_playback)
	_hud.replay_exit_requested.connect(_replay_presentation.exit)
	_replay_presentation.presentation_exited.connect(_on_replay_exited)
	_replay_presentation.active_changed.connect(_hud.set_replay_active)


func _on_aim_changed(yaw: float, elevation: float, power: float) -> void:
	_hud.update_aim(yaw, elevation, power)
	_recompute_prediction()


func _recompute_prediction() -> void:
	var prediction := TrajectoryPredictor.predict(
		get_world_3d().direct_space_state,
		_cannon,
		stage_data.stage_bounds
	)
	_cannon.set_prediction(prediction)


func _on_paint_deposit_requested(
		_projectile: PaintProjectile,
		request: PaintDepositRequest
) -> void:
	var result := _paint_system.apply_deposit(request)
	_projectile_manager.resolve_paint_deposit(_projectile, request, result)


func _on_transient_splash_requested(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
	_presentation_effects.splash(contact.world_position, clampf(contact.relative_normal_speed / 32.0, 0.7, 1.5))
	_audio_cue(&"impact")
	_camera_director.add_impact_shake(clampf(contact.relative_normal_speed / 80.0, 0.12, 0.42))
	_shot_has_impacted = true


func _on_shot_fired(_number: int, _yaw: float, _elevation: float, _power: float) -> void:
	_shot_has_impacted = false
	Engine.time_scale = 1.0
	_presentation_effects.muzzle_flash(_cannon.get_launch_origin())
	_audio_cue(&"fire")


func _on_shot_result(gain: float, total: float) -> void:
	_hud.show_shot_result(gain, total)


func _on_shot_observation_sealed(observation: ShotObservation) -> void:
	_hud.show_shot_observation(observation)
	if not _replay_presentation.active:
		_replay_recorder.record_observation(observation)


func _on_aim_action_accepted(yaw: float, elevation: float, power: float, origin: int) -> void:
	if origin != StageController.ActionOrigin.REPLAY and not _replay_presentation.active:
		_replay_recorder.record_aim(yaw, elevation, power)


func _on_fire_action_accepted(origin: int) -> void:
	if origin != StageController.ActionOrigin.REPLAY and not _replay_presentation.active:
		_replay_recorder.record_aim(_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent)
		_replay_recorder.record_fire()


func _on_restart_action_accepted(origin: int) -> void:
	if origin != StageController.ActionOrigin.REPLAY and not _replay_presentation.active:
		_replay_recorder.record_restart()


func _on_state_changed(current_state: int, previous_state: int) -> void:
	var state := current_state as StageController.State
	if previous_state == StageController.State.SHOT_RESULT and not _replay_presentation.active:
		_replay_recorder.update_latest_result_state(current_state)
	_hud.show_state(state)
	match state:
		StageController.State.BRIEFING:
			_set_mechanism_labels_visible(true)
			_trajectory_preview.visible = false
			_camera_director.set_mode(CameraDirector.Mode.BRIEFING)
		StageController.State.AIMING:
			_set_mechanism_labels_visible(true)
			Engine.time_scale = 1.0
			_trajectory_preview.visible = _setting_bool("trajectory_preview", true)
			if _trajectory_preview.visible:
				_trajectory_preview.refresh()
			_camera_director.set_mode(CameraDirector.Mode.AIMING)
		StageController.State.PROJECTILE_IN_FLIGHT:
			_set_mechanism_labels_visible(false)
			_trajectory_preview.visible = false
			_camera_director.set_mode(CameraDirector.Mode.FOLLOW if _setting_bool("follow_camera", true) else CameraDirector.Mode.WIDE)
		StageController.State.PAINT_SETTLING, StageController.State.SHOT_RESULT:
			Engine.time_scale = 1.0
			_camera_director.set_mode(CameraDirector.Mode.WIDE)
		StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED:
			Engine.time_scale = 1.0
			_camera_director.set_mode(CameraDirector.Mode.RESULT)


func _on_stage_cleared(final_coverage: float, shots_used: int) -> void:
	var stars := _stars_for_coverage(final_coverage)
	var game_state := get_node_or_null("/root/GameState")
	var previous_best := float(game_state.best_for(stage_data.stage_id).get("coverage", 0.0)) if game_state != null else 0.0
	_hud.show_clear(final_coverage, shots_used, stars, previous_best)
	_presentation_effects.clear_glint(stage_data.terrain_center + Vector3(0.0, float(_generated_layout.metrics.get("maximum_height", 70.0)) + 5.0, 0.0))
	_audio_cue(&"clear")
	if game_state != null and not _replay_presentation.active:
		game_state.complete_stage(stage_data.stage_id, final_coverage, stars)


func _on_stage_failed(final_coverage: float, missing: float) -> void:
	var game_state := get_node_or_null("/root/GameState")
	var previous_best := float(game_state.best_for(stage_data.stage_id).get("coverage", 0.0)) if game_state != null else 0.0
	_hud.show_failure(final_coverage, missing, previous_best)
	_audio_cue(&"fail")


func _on_camera_mode_requested(mode: int) -> void:
	if _replay_presentation.active:
		return
	if _stage_controller.current_state not in [
		StageController.State.PROJECTILE_IN_FLIGHT,
		StageController.State.PAINT_SETTLING,
		StageController.State.SHOT_RESULT,
	]:
		return
	_camera_director.set_mode(mode as CameraDirector.Mode)
	_replay_recorder.record_camera(mode)


func _on_simulation_speed_requested(speed: float) -> void:
	if _replay_presentation.active:
		_replay_presentation.set_speed(speed)
		return
	if _stage_controller.current_state == StageController.State.PROJECTILE_IN_FLIGHT and _shot_has_impacted:
		Engine.time_scale = clampf(speed, 1.0, 2.0)


func _spawn_mechanisms() -> void:
	_mechanisms.clear()
	var placements: Array[MechanismPlacement] = _generated_layout.mechanism_placements
	for placement in placements:
		var mechanism_scene: PackedScene
		match placement.mechanism_data.kind:
			MechanismData.Kind.BURST:
				mechanism_scene = BURST_SCENE
			MechanismData.Kind.SPLITTER:
				mechanism_scene = SPLITTER_SCENE
			MechanismData.Kind.BUMPER:
				mechanism_scene = BUMPER_SCENE
		var mechanism := mechanism_scene.instantiate() as GimmickBase
		mechanism.name = MechanismData.Kind.keys()[placement.mechanism_data.kind].capitalize()
		mechanism.data = placement.mechanism_data
		var world_transform := placement.local_transform
		world_transform.origin += stage_data.terrain_center
		mechanism.transform = world_transform
		mechanism.configure(_projectile_manager, _paint_system)
		_mechanism_root.add_child(mechanism)
		if mechanism is SplitterNode:
			var route_targets := PackedVector3Array()
			for required_role in mechanism.data.child_target_route_roles:
				var route_index := _route_index_for_role(required_role)
				assert(route_index >= 0, "Splitter child target role must exist in the accepted layout.")
				var route_target := _generated_layout.route_position(route_index, mechanism.data.child_target_t)
				route_targets.append(stage_data.terrain_center + Vector3(
					route_target.x,
					_generated_layout.height_at_local(route_target.x, route_target.z),
					route_target.z
				))
			mechanism.configure_route_targets(route_targets, placement.downstream_tangent)
		elif mechanism is BumperNode:
			mechanism.configure_downstream_tangent(placement.downstream_tangent)
		mechanism.mechanism_activated.connect(_on_mechanism_activated)
		mechanism.mechanism_selected.connect(_on_mechanism_selected)
		_mechanisms.append(mechanism)


func _route_index_for_role(role: int) -> int:
	for route_index in range(_generated_layout.route_roles.size()):
		if _generated_layout.route_roles[route_index] == role:
			return route_index
	return -1


func _on_mechanism_selected(mechanism: GimmickBase) -> void:
	if _stage_controller.current_state == StageController.State.BRIEFING:
		_camera_director.focus_briefing_target(mechanism.global_position)
		_hud.show_mechanism_brief(mechanism.data.kind)


func _on_mechanism_activated(
		mechanism: GimmickBase,
		_projectile: PaintProjectile,
		kind: MechanismData.Kind
) -> void:
	var payload := {
		"kind": MechanismData.Kind.keys()[kind],
		"position": mechanism.global_position,
	}
	_agent_api.notify_event(&"mechanism_activated", payload)
	_hud.show_mechanism_activation(kind)
	_presentation_effects.mechanism_burst(mechanism.global_position)
	_audio_cue(&"mechanism")
	_camera_director.add_impact_shake(0.32)


func _set_mechanism_labels_visible(visible: bool) -> void:
	for mechanism in _mechanisms:
		mechanism.set_label_visible(visible)


func _stars_for_coverage(coverage: float) -> int:
	var stars := 0
	for threshold in [stage_data.star_thresholds.x, stage_data.star_thresholds.y, stage_data.star_thresholds.z]:
		if coverage + 0.0001 >= threshold:
			stars += 1
	return stars


func _start_replay() -> void:
	var saved_attempt := _replay_recorder.export_attempt()
	if saved_attempt.get("actions", []).is_empty():
		return
	_replay_presentation.start(saved_attempt)


func _start_last_shot_replay() -> void:
	var saved_attempt := _replay_recorder.last_shot_attempt()
	if not saved_attempt.is_empty():
		_replay_presentation.start(saved_attempt)


func _on_replay_exited() -> void:
	_replay_recorder.start_attempt(
		stage_data,
		stage_data.stage_number * 1000 + stage_data.stage_version,
		_generated_layout
	)


func _request_navigation(destination: StringName) -> void:
	if not _replay_presentation.active:
		navigation_requested.emit(destination)


func _audio_cue(cue: StringName) -> void:
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.play_cue(cue)


func _setting_bool(key: String, fallback: bool) -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return bool(game_state.settings.get(key, fallback)) if game_state != null else fallback
