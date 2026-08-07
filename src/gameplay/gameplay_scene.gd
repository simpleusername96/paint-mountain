extends Node3D

signal navigation_requested(destination: StringName)

const BURST_SCENE := preload("res://scenes/mechanisms/burst_node.tscn")
const SPLITTER_SCENE := preload("res://scenes/mechanisms/splitter_node.tscn")
const UPHILL_REBOUND_SCENE := preload("res://scenes/mechanisms/uphill_rebound_node.tscn")
const PAINT_SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")

@export var stage_data: StageData

@onready var _camera: Camera3D = %Camera
@onready var _terrain_surface: TerrainSurface = %TerrainSurface
@onready var _terrain_mesh: MeshInstance3D = %TerrainMesh
@onready var _open_play_environment: OpenPlayEnvironment = %OpenPlayEnvironment
@onready var _cannon: CannonController = %Cannon
@onready var _trajectory_preview: TrajectoryPreview = %TrajectoryPreview
@onready var _prediction_scheduler: TrajectoryPredictionScheduler = %TrajectoryPredictionScheduler
@onready var _aim_input: AimInputController = %AimInputController
@onready var _projectile_manager: ProjectileManager = %ProjectileManager
@onready var _paint_system: PaintSystem = %PaintSystem
@onready var _stage_controller: StageController = %StageController
@onready var _wind_controller: WindController = %WindController
@onready var _wind_flag: CannonWindFlag = %CannonWindFlag
@onready var _camera_director: CameraDirector = %CameraDirector
@onready var _hud: HUDController = %HUD
@onready var _mechanism_root: Node3D = %Mechanisms
@onready var _environment_dressing: Node3D = %EnvironmentDressing
@onready var _replay_recorder: ReplayRecorder = %ReplayRecorder
@onready var _replay_presentation: ReplayPresentationController = %ReplayPresentationController
@onready var _agent_api: GameplayAgentApi = %GameplayAgentApi
@onready var _presentation_effects: PresentationEffects = %PresentationEffects
@onready var _debug_overlay: DebugOverlay = %DebugOverlay

var _mechanisms: Array[TerrainGlyphMechanism] = []
var _mechanism_resolver := TerrainMechanismResolver.new()
var _generated_layout: GeneratedStageLayout
var _prepared_layout: GeneratedStageLayout
var _prepared_stage_id: StringName = &""
var _prepared_layout_checksum: int = 0
var _wind_transition_was_active := false


func _ready() -> void:
	assert(stage_data != null, "GameplayScene requires StageData.")
	var game_state := get_node_or_null("/root/GameState")
	var selected_stage := StageCatalog.get_stage(game_state.selected_stage_id if game_state != null else stage_data.stage_id)
	if selected_stage != null:
		stage_data = selected_stage
	if not _prepared_layout_matches_stage():
		push_error("GameplayScene requires a prepared runtime-ready baked layout.")
		return
	if not _build_stage_world():
		return
	_connect_systems()
	_camera_director.configure(_camera, stage_data, _projectile_manager, _terrain_surface, _cannon)
	_trajectory_preview.configure(_cannon)
	_hud.configure(stage_data)
	if not _stage_controller.configure(
		stage_data,
		_generated_layout,
		_cannon,
		_projectile_manager,
		_paint_system,
		_terrain_surface,
		_mechanisms
	):
		push_error("GameplayScene cannot enter briefing without a runtime-ready generated layout.")
		return
	_replay_presentation.configure(
		_replay_recorder,
		_stage_controller,
		_camera_director,
		_wind_controller
	)
	_aim_input.configure(_cannon, _stage_controller, _camera_director)
	if not _prediction_scheduler.configure(
		_cannon,
		_wind_controller,
		_generated_layout.play_bounds.bounds,
		stage_data.wind_profile,
		_generated_layout.terrain_seed
	):
		push_error("GameplayScene could not configure trajectory prediction scheduling.")
		return
	_update_prediction_consumers()
	_replay_recorder.start_attempt(
		stage_data,
		_generated_layout.terrain_seed,
		_generated_layout,
		_wind_controller.schedule_identity()
	)
	_agent_api.configure(
		stage_data,
		_stage_controller,
		_cannon,
		_paint_system,
		_projectile_manager,
		_camera_director,
		_mechanisms,
		_generated_layout,
		_wind_controller
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
		_replay_recorder,
		_generated_layout
	)
	_debug_overlay.mechanism_labels_toggled.connect(_set_mechanism_labels_visible)
	_hud.show_state(_stage_controller.current_state)
	_on_wind_snapshot_changed(_wind_controller.current_snapshot())
	print("Paint Mountain gameplay scene ready in %s." % _stage_controller.state_name())


func generated_layout() -> GeneratedStageLayout:
	return _generated_layout


func prepare_stage(selected_stage: StageData, cached_layout: GeneratedStageLayout) -> void:
	assert(not is_inside_tree(), "Gameplay stage preparation must finish before entering the tree.")
	stage_data = selected_stage
	_prepared_layout = cached_layout
	_prepared_stage_id = selected_stage.stage_id if selected_stage != null else &""
	_prepared_layout_checksum = cached_layout.checksum if cached_layout != null else 0


func terrain_layout_read_only() -> GeneratedStageLayout:
	return _generated_layout


func prediction_compute_count() -> int:
	return _prediction_scheduler.prediction_compute_count()


## Delivery-only frame hold used to capture the real pending-readiness surface
## before the coalesced predictor publishes the latest aim key.
func hold_prediction_refresh_for_delivery(duration_seconds: float = 0.15) -> void:
	_prediction_scheduler.hold_refresh_for_seconds(duration_seconds)


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


func set_pause_overlay_suspended(suspended: bool) -> void:
	_hud.set_pause_overlay_suspended(suspended)


func focus_pause_settings() -> void:
	_hud.focus_pause_settings()


func _build_stage_world() -> bool:
	_terrain_surface.position = stage_data.terrain_center
	assert(stage_data.generation_profile != null, "Gameplay stages require a generation profile.")
	_generated_layout = _prepared_layout.copy_for_runtime() \
			if _prepared_layout_matches_stage() else null
	if not _layout_matches_stage(_generated_layout, stage_data):
		push_error("GameplayScene cannot construct a stage without its prepared baked layout.")
		return false
	_terrain_surface.configure(_generated_layout)
	_open_play_environment.configure(
		_generated_layout.play_bounds,
		stage_data.paint_world_bounds(),
		stage_data.terrain_center.y
	)
	_projectile_manager.configure_terrain(_terrain_surface)
	if stage_data.wind_profile == null or not _wind_controller.configure(
		stage_data.wind_profile,
		_generated_layout.terrain_seed
	):
		push_error("GameplayScene requires a valid stage wind profile.")
		return false
	_projectile_manager.configure_wind(_wind_controller, stage_data.wind_profile)
	_cannon.global_transform = stage_data.cannon_transform
	_wind_flag.configure(_cannon, _wind_controller)
	var paint_material := ShaderMaterial.new()
	paint_material.shader = load("res://src/paint/terrain_paint.gdshader")
	# The mountain must read as a faceted 3D mass against the open sky and quiet
	# apron. Reserve this cooler mid-value range for terrain relief.
	paint_material.set_shader_parameter("rock_color", Color("74839A"))
	paint_material.set_shader_parameter("shadow_tint", Color("46546A"))
	paint_material.set_shader_parameter("support_floor_y", stage_data.terrain_center.y)
	paint_material.set_shader_parameter(
		"support_rear_z",
		stage_data.paint_world_bounds().position.y
	)
	_paint_system.configure(
		stage_data.paint_world_bounds(),
		stage_data.terrain_center.y,
		paint_material,
		stage_data.paint_color,
		_generated_layout,
		PAINT_SURFACE_TUNING
	)
	var top_body := _terrain_surface.get_node("TerrainTopBody") as StaticBody3D
	_paint_system.configure_top_surface_identity(
		top_body.get_rid(),
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID,
		0
	)
	_terrain_mesh.material_override = paint_material
	_environment_dressing.configure(stage_data, _generated_layout)
	_spawn_mechanisms()
	return true


func _prepared_layout_matches_stage() -> bool:
	return _prepared_stage_id == stage_data.stage_id \
			and _prepared_layout != null \
			and _prepared_layout_checksum != 0 \
			and _prepared_layout.checksum == _prepared_layout_checksum \
			and _layout_matches_stage(_prepared_layout, stage_data) \
			and _prepared_layout.is_runtime_ready()


func _layout_matches_stage(layout: GeneratedStageLayout, selected_stage: StageData) -> bool:
	return layout != null and layout.matches_stage_identity(selected_stage)


func _connect_systems() -> void:
	_cannon.aim_changed.connect(_on_aim_changed)
	# StageController owns the complete Fire contract (prediction key, capacity,
	# shots, terminal state, and action lock). Do not let the cannon's partial
	# aim-validity signal overwrite that authoritative HUD decision.
	_stage_controller.fire_readiness_changed.connect(_hud.set_fire_readiness)
	_projectile_manager.radial_paint_mark_ready.connect(_paint_system.queue_radial_paint_mark)
	_projectile_manager.surface_paint_sweep_ready.connect(_paint_system.queue_surface_paint_sweep)
	_projectile_manager.transient_splash_requested.connect(_on_transient_splash_requested)
	_projectile_manager.valid_top_traversed.connect(_on_valid_top_traversed)
	_projectile_manager.valid_top_exited.connect(_mechanism_resolver.clear_projectile)
	_projectile_manager.projectile_motion_state_changed.connect(_on_projectile_motion_state_changed)
	_projectile_manager.projectile_woke.connect(_on_projectile_woke)
	_projectile_manager.projectile_terrain_recovered.connect(_on_projectile_terrain_recovered)
	_projectile_manager.projectile_stopped.connect(_on_projectile_stopped)
	_projectile_manager.resident_activity_changed.connect(_hud.update_resident_activity)
	_paint_system.coverage_changed.connect(_hud.update_coverage)
	_stage_controller.state_changed.connect(_on_state_changed)
	_stage_controller.shots_changed.connect(_hud.update_shots)
	_stage_controller.shot_family_activity_changed.connect(_hud.update_activity)
	_stage_controller.shot_fired.connect(_on_shot_fired)
	_stage_controller.shot_result.connect(_on_shot_result)
	_stage_controller.shot_observation_sealed.connect(_on_shot_observation_sealed)
	_stage_controller.aim_action_accepted.connect(_on_aim_action_accepted)
	_stage_controller.fire_action_accepted.connect(_on_fire_action_accepted)
	_stage_controller.restart_action_accepted.connect(_on_restart_action_accepted)
	_stage_controller.finish_action_accepted.connect(_on_finish_action_accepted)
	_stage_controller.stage_clock_started.connect(func(_duration_ticks: int) -> void: _wind_controller.start())
	_stage_controller.stage_clock_changed.connect(_on_stage_clock_changed)
	_stage_controller.stage_finished.connect(_on_stage_finished)
	_wind_controller.snapshot_changed.connect(_on_wind_snapshot_changed)
	_camera_director.mode_changed.connect(_on_camera_mode_changed)
	_camera_director.interaction_mode_changed.connect(_on_interaction_mode_changed)
	_hud.begin_aiming_requested.connect(func() -> void: _stage_controller.begin_aiming(StageController.ActionOrigin.HUMAN))
	_hud.fire_requested.connect(func() -> void: _aim_input.request_fire())
	_hud.finish_requested.connect(func() -> void: _stage_controller.finish_stage(StageController.ActionOrigin.HUMAN))
	_hud.power_step_requested.connect(_aim_input.adjust_power_button)
	_hud.restart_requested.connect(func() -> void: _stage_controller.restart(false, StageController.ActionOrigin.HUMAN))
	_hud.pause_requested.connect(func() -> void: _stage_controller.toggle_pause(StageController.ActionOrigin.HUMAN))
	_hud.settings_requested.connect(func() -> void: _request_navigation(&"settings"))
	_hud.stage_select_requested.connect(func() -> void: _request_navigation(&"stage_select"))
	_hud.main_menu_requested.connect(func() -> void: _request_navigation(&"main_menu"))
	_hud.next_stage_requested.connect(func() -> void: _request_navigation(&"next_stage"))
	_hud.replay_requested.connect(_start_replay)
	_hud.interaction_mode_requested.connect(_on_interaction_mode_requested)
	_hud.return_to_cannon_requested.connect(func() -> void: _camera_director.return_to_aim_view())
	_hud.replay_speed_requested.connect(_replay_presentation.set_speed)
	_hud.replay_pause_requested.connect(_replay_presentation.set_paused)
	_hud.replay_restart_requested.connect(_replay_presentation.restart_playback)
	_hud.replay_exit_requested.connect(_replay_presentation.exit)
	_replay_presentation.presentation_exited.connect(_on_replay_exited)
	_replay_presentation.active_changed.connect(_hud.set_replay_active)


func _on_aim_changed(yaw: float, elevation: float, power: float) -> void:
	_hud.update_aim(yaw, elevation, power)
	_prediction_scheduler.request_latest()


func _on_transient_splash_requested(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
	_presentation_effects.splash(contact.world_position, clampf(contact.relative_normal_speed / 32.0, 0.7, 1.5))
	_audio_cue(&"impact")
	_camera_director.add_impact_shake(clampf(contact.relative_normal_speed / 80.0, 0.12, 0.42))


func _on_shot_fired(_number: int, _yaw: float, _elevation: float, _power: float) -> void:
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
		var observation := _stage_controller.current_shot_observation()
		_replay_recorder.record_fire(observation.shot_id if observation != null else 0)


func _on_restart_action_accepted(origin: int) -> void:
	_wind_controller.reset()
	_wind_transition_was_active = false
	_mechanism_resolver.clear_all()
	if origin != StageController.ActionOrigin.REPLAY and not _replay_presentation.active:
		_replay_recorder.record_restart()


func _on_finish_action_accepted(origin: int) -> void:
	if origin != StageController.ActionOrigin.REPLAY and not _replay_presentation.active:
		_replay_recorder.record_finish(StageController.FINISH_REASON_MANUAL)


func _on_stage_clock_changed(_elapsed_ticks: int, _remaining_ticks: int) -> void:
	_hud.update_clock(_stage_controller.clock_snapshot())


func _on_wind_snapshot_changed(snapshot: WindSnapshot) -> void:
	_prediction_scheduler.request_latest()
	if snapshot == null:
		return
	var current_projection := _wind_hud_projection(snapshot.acceleration)
	var next_projection := _wind_hud_projection(snapshot.next_acceleration)
	_hud.update_wind(
		snapshot,
		current_projection.screen_direction,
		current_projection.depth_cue,
		next_projection.screen_direction,
		next_projection.depth_cue
	)
	var transition_started := snapshot.is_transitioning() and not _wind_transition_was_active
	_wind_transition_was_active = snapshot.is_transitioning()
	var observation := _live_attempt_observation()
	if transition_started and observation != null:
		observation.record_wind_transition(snapshot)


func _on_stage_finished(result: Dictionary) -> void:
	_wind_controller.stop()
	_mechanism_resolver.clear_all()
	var final_coverage := float(result.get("coverage", 0.0))
	var stars := _stars_for_coverage(final_coverage)
	var game_state := get_node_or_null("/root/GameState")
	var previous_best := float(game_state.best_for(stage_data.stage_id).get("coverage", 0.0)) \
			if game_state != null else 0.0
	_hud.show_coverage_result_snapshot(result, stars, previous_best)
	if _replay_presentation.active:
		return
	_replay_recorder.store_final_result(result)
	_presentation_effects.clear_glint(
		stage_data.terrain_center
				+ Vector3(0.0, float(_generated_layout.metrics.get("maximum_height", 70.0)) + 5.0, 0.0)
	)
	_audio_cue(&"clear")
	if game_state != null:
		var ticks_per_second := maxi(Engine.physics_ticks_per_second, 1)
		game_state.complete_stage(
			stage_data.stage_id,
			final_coverage,
			stars,
			true,
			{
				"elapsed_seconds": float(result.get("elapsed_ticks", 0)) / float(ticks_per_second),
				"shots_used": int(result.get("shots_used", 0)),
				"finish_reason": String(result.get("finish_reason", "")),
			}
		)


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
			_set_mechanism_labels_visible(false)
			Engine.time_scale = 1.0
			_trajectory_preview.visible = _setting_bool("trajectory_preview", true)
			if _trajectory_preview.visible:
				_trajectory_preview.refresh()
			# Pause/resume must preserve whether the player was inspecting the map
			# or locked into aim. All other entries to Aiming start in Aim Lock.
			if previous_state != StageController.State.PAUSED:
				_camera_director.set_mode(CameraDirector.Mode.AIMING)
		StageController.State.FINISHING, StageController.State.RESULT:
			Engine.time_scale = 1.0
			_camera_director.set_mode(CameraDirector.Mode.RESULT)
	_update_prediction_consumers()


func _on_interaction_mode_requested(mode: int) -> void:
	if _replay_presentation.active:
		return
	if _stage_controller.current_state != StageController.State.AIMING:
		return
	_camera_director.set_interaction_mode(mode as CameraDirector.InteractionMode)


func _on_camera_mode_changed(mode: int) -> void:
	var camera_mode := mode as CameraDirector.Mode
	_hud.set_camera_mode(camera_mode)
	var show_preview := _stage_controller.current_state == StageController.State.AIMING \
			and camera_mode == CameraDirector.Mode.AIMING \
			and _setting_bool("trajectory_preview", true)
	_trajectory_preview.visible = show_preview
	if show_preview:
		_trajectory_preview.refresh()
	_update_prediction_consumers()


func _on_interaction_mode_changed(mode: int) -> void:
	_hud.set_interaction_mode(mode as CameraDirector.InteractionMode)
	_update_prediction_consumers()
	if not _replay_presentation.active and not _stage_controller.action_origin_is_locked():
		_replay_recorder.record_camera(mode)


func _update_prediction_consumers() -> void:
	if _prediction_scheduler == null or not _prediction_scheduler.is_node_ready():
		return
	var fire_can_consume := _stage_controller != null \
			and _stage_controller.current_state == StageController.State.AIMING \
			and _camera_director.current_mode == CameraDirector.Mode.AIMING \
			and _camera_director.aim_is_locked() \
			and _cannon.input_enabled \
			and not _stage_controller.action_origin_is_locked()
	_prediction_scheduler.set_consumers_enabled(
		(_trajectory_preview != null and _trajectory_preview.visible) or fire_can_consume
	)


func _spawn_mechanisms() -> void:
	_mechanisms.clear()
	var placements: Array[MechanismPlacement] = _generated_layout.mechanism_placements
	for placement in placements:
		var mechanism_scene: PackedScene
		match placement.mechanism_data.canonical_kind():
			MechanismData.Kind.BURST:
				mechanism_scene = BURST_SCENE
			MechanismData.Kind.SPLITTER:
				mechanism_scene = SPLITTER_SCENE
			MechanismData.Kind.UPHILL_REBOUND:
				mechanism_scene = UPHILL_REBOUND_SCENE
		var mechanism := mechanism_scene.instantiate() as TerrainGlyphMechanism
		mechanism.name = "%s_%s" % [
			MechanismData.Kind.keys()[int(placement.mechanism_data.canonical_kind())].capitalize(),
			String(placement.anchor_id),
		]
		mechanism.set_meta("anchor_id", placement.anchor_id)
		mechanism.data = placement.mechanism_data
		var world_transform := placement.local_transform
		world_transform.origin += stage_data.terrain_center
		mechanism.transform = world_transform
		mechanism.configure(_projectile_manager, _paint_system, _terrain_surface)
		_mechanism_root.add_child(mechanism)
		if mechanism is SplitterNode:
			var route_targets := PackedVector3Array()
			for route_target in placement.splitter_route_targets:
				route_targets.append(stage_data.terrain_center + route_target)
			mechanism.configure_route_targets(route_targets, placement.downstream_tangent)
		elif mechanism is UphillReboundNode:
			mechanism.configure_uphill_tangent(placement.uphill_tangent)
		mechanism.mechanism_activated.connect(_on_mechanism_activated)
		mechanism.mechanism_selected.connect(_on_mechanism_selected)
		_mechanisms.append(mechanism)
	_mechanism_resolver.configure(_terrain_surface)
	for mechanism in _mechanisms:
		_mechanism_resolver.register_glyph(mechanism)

func _on_mechanism_selected(mechanism: TerrainGlyphMechanism) -> void:
	if _stage_controller.current_state == StageController.State.BRIEFING:
		_camera_director.focus_briefing_target(mechanism.global_position)
		_hud.show_mechanism_brief(mechanism.data.kind)


func _on_mechanism_activated(
		mechanism: TerrainGlyphMechanism,
		projectile: PaintProjectile,
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
	var observation := _live_attempt_observation()
	if observation != null and projectile != null:
		observation.record_mechanism_activation(
			projectile.shot_id,
			projectile.spawn_ordinal,
			StringName(mechanism.get_meta("anchor_id", mechanism.name)),
			int(kind)
		)


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


func _on_replay_exited() -> void:
	_replay_recorder.start_attempt(
		stage_data,
		_generated_layout.terrain_seed,
		_generated_layout,
		_wind_controller.schedule_identity()
	)


func _on_valid_top_traversed(
		projectile: PaintProjectile,
		contact: ProjectileContact,
		base_paint_committed: bool
) -> void:
	_mechanism_resolver.resolve_after_base_paint(projectile, contact, base_paint_committed)


func _on_projectile_motion_state_changed(
		projectile: PaintProjectile,
		_previous_state: int,
		current_state: int
) -> void:
	if current_state == PaintProjectile.MotionState.MOVING_AIRBORNE:
		_mechanism_resolver.clear_projectile(projectile)
	var observation := _live_attempt_observation()
	if observation != null and current_state == PaintProjectile.MotionState.RESTING_ON_TERRAIN:
		observation.record_projectile_rest(projectile.shot_id, projectile.spawn_ordinal)


func _on_projectile_woke(
		projectile: PaintProjectile,
		reason: StringName,
		strong_episode_id: int
) -> void:
	var observation := _live_attempt_observation()
	if observation != null:
		observation.record_projectile_wake(
			projectile.shot_id,
			projectile.spawn_ordinal,
			reason,
			strong_episode_id
		)


func _on_projectile_terrain_recovered(
		projectile: PaintProjectile,
		_physics_tick: int,
		_correction_distance: float
) -> void:
	var observation := _live_attempt_observation()
	if observation != null:
		observation.record_terrain_recovery(
			projectile.shot_id,
			projectile.spawn_ordinal,
			&"surface_clearance"
		)


func _on_projectile_stopped(projectile: PaintProjectile, reason: StringName) -> void:
	_mechanism_resolver.clear_projectile(projectile)
	var observation := _live_attempt_observation()
	if observation != null:
		observation.record_projectile_terminal(
			projectile.shot_id,
			projectile.spawn_ordinal,
			reason
		)


func _live_attempt_observation() -> AttemptObservation:
	if _replay_presentation.active or _stage_controller.action_origin_is_locked():
		return null
	return _replay_recorder.current_attempt_observation()


func _wind_hud_projection(world_direction: Vector3) -> Dictionary:
	if world_direction.is_zero_approx() or _camera == null:
		return {
			"screen_direction": Vector2.ZERO,
			"depth_cue": RunStatusCard.DepthCue.NONE,
		}
	var local_direction := _camera.global_basis.inverse() * world_direction.normalized()
	var screen_direction := Vector2(local_direction.x, -local_direction.y)
	var depth_cue := RunStatusCard.DepthCue.NONE
	if screen_direction.length() < 0.35 and absf(local_direction.z) >= 0.35:
		depth_cue = RunStatusCard.DepthCue.INTO_SCREEN \
				if local_direction.z < 0.0 else RunStatusCard.DepthCue.OUT_OF_SCREEN
		screen_direction = Vector2.ZERO
	elif not screen_direction.is_zero_approx():
		screen_direction = screen_direction.normalized()
	return {
		"screen_direction": screen_direction,
		"depth_cue": depth_cue,
	}


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
