extends Node3D

signal navigation_requested(destination: StringName)
signal stage_prepared(stage_id: StringName)
signal stage_preparation_failed(stage_id: StringName)

const BURST_SCENE := preload("res://scenes/mechanisms/burst_node.tscn")
const SPLITTER_SCENE := preload("res://scenes/mechanisms/splitter_node.tscn")
const UPHILL_REBOUND_SCENE := preload("res://scenes/mechanisms/uphill_rebound_node.tscn")
const PAINT_SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")
const GAMEPLAY_PACE := preload("res://src/gameplay/gameplay_pace.gd")

@export var stage_data: StageData

@onready var _camera: Camera3D = %Camera
@onready var _terrain_surface: TerrainSurface = %TerrainSurface
@onready var _terrain_mesh: MeshInstance3D = %TerrainMesh
@onready var _open_play_environment: OpenPlayEnvironment = %OpenPlayEnvironment
@onready var _cannon: CannonController = %Cannon
@onready var _trajectory_preview: TrajectoryPreview = %TrajectoryPreview
@onready var _target_preview: TerrainTargetPreview = %TerrainTargetPreview
@onready var _terrain_aim: TerrainAimController = %TerrainAimController
@onready var _prediction_scheduler: TrajectoryPredictionScheduler = %TrajectoryPredictionScheduler
@onready var _aim_input: AimInputController = %AimInputController
@onready var _projectile_manager: ProjectileManager = %ProjectileManager
@onready var _paint_system: PaintSystem = %PaintSystem
@onready var _stage_controller: StageController = %StageController
@onready var _camera_director: CameraDirector = %CameraDirector
@onready var _hud: HUDController = %HUD
@onready var _mechanism_root: Node3D = %Mechanisms
@onready var _environment_dressing: Node3D = %EnvironmentDressing
@onready var _attempt_recorder: AttemptRecorder = %AttemptRecorder
@onready var _agent_api: GameplayAgentApi = %GameplayAgentApi
@onready var _presentation_effects: PresentationEffects = %PresentationEffects
@onready var _debug_overlay: DebugOverlay = %DebugOverlay

var _mechanisms: Array[TerrainGlyphMechanism] = []
var _mechanism_resolver := TerrainMechanismResolver.new()
var _generated_layout: GeneratedStageLayout
var _prepared_layout: GeneratedStageLayout
var _prepared_artifact: StageRuntimeArtifact
var _prepared_stage_id: StringName = &""
var _prepared_layout_checksum: int = 0
var _stage_preparation_complete := false
var _terrain_paint_material: ShaderMaterial
var _stage_presented_requested := true
var _delivery_markers: Dictionary = {}
var _delivery_root_frame_keys: Dictionary = {}
var _delivery_effect_frame_keys: Dictionary = {}


func _ready() -> void:
	GAMEPLAY_PACE.apply_normal()
	RuntimeDeliveryTelemetry.emit_marker(&"gameplay_binding_started", {
		"stage_id": String(stage_data.stage_id) if stage_data != null else "",
	})
	if stage_data == null:
		_fail_stage_preparation("GameplayScene requires StageData.")
		return
	if not _prepared_layout_matches_stage():
		_fail_stage_preparation("GameplayScene requires a prepared runtime-ready baked layout.")
		return
	if not _build_stage_world():
		_fail_stage_preparation("GameplayScene could not bind the prepared stage world.")
		return
	RuntimeDeliveryTelemetry.emit_marker(&"gameplay_world_bound", {
		"stage_id": String(stage_data.stage_id),
	})
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
		_fail_stage_preparation("GameplayScene cannot enter briefing without a runtime-ready generated layout.")
		return
	_stage_controller.set_actions_enabled(_stage_presented_requested)
	_aim_input.configure(_cannon, _stage_controller, _camera_director)
	if not _prediction_scheduler.configure(
		_cannon,
		_generated_layout.play_bounds.bounds
	):
		_fail_stage_preparation("GameplayScene could not configure trajectory prediction scheduling.")
		return
	if not _terrain_aim.configure(
		_camera,
		_terrain_surface,
		_cannon,
		_stage_controller,
		_target_preview
	):
		_fail_stage_preparation("GameplayScene could not configure terrain-targeted aiming.")
		return
	_update_prediction_consumers()
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
		_attempt_recorder,
		_generated_layout
	)
	_debug_overlay.mechanism_labels_toggled.connect(_set_mechanism_labels_visible)
	_hud.show_state(_stage_controller.current_state)
	print("Paint Mountain gameplay scene ready in %s." % _stage_controller.state_name())
	_complete_stage_preparation.call_deferred()


func _exit_tree() -> void:
	RuntimeDeliveryTelemetry.emit_marker(&"gameplay_soak_end", {
		"stage_id": String(stage_data.stage_id) if stage_data != null else "",
		"active_projectiles": _projectile_manager.active_count() \
				if _projectile_manager != null else 0,
	})
	GAMEPLAY_PACE.apply_normal()


func generated_layout() -> GeneratedStageLayout:
	return _generated_layout


func prepare_stage(selected_stage: StageData, prepared_source: Variant) -> bool:
	assert(not is_inside_tree(), "Gameplay stage preparation must finish before entering the tree.")
	_stage_preparation_complete = false
	stage_data = selected_stage
	_prepared_artifact = prepared_source as StageRuntimeArtifact
	if selected_stage == null:
		return false
	if _prepared_artifact != null and not _prepared_artifact.is_complete_for(
		selected_stage,
		PAINT_SURFACE_TUNING,
		PaintSystem.MASK_SIZE
	):
		_prepared_artifact = null
		_prepared_layout = null
		return false
	_prepared_layout = _prepared_artifact.runtime_layout \
			if _prepared_artifact != null else prepared_source as GeneratedStageLayout
	_prepared_stage_id = selected_stage.stage_id if selected_stage != null else &""
	_prepared_layout_checksum = _prepared_layout.checksum if _prepared_layout != null else 0
	return _prepared_layout_matches_stage()


func is_stage_prepared() -> bool:
	return _stage_preparation_complete


func prepared_artifact_read_only() -> StageRuntimeArtifact:
	return _prepared_artifact


func set_stage_presented(presented: bool) -> void:
	_stage_presented_requested = presented
	visible = presented
	var hud_layer := get_node_or_null("HUD") as CanvasLayer
	if hud_layer != null:
		hud_layer.visible = presented
	if _stage_controller != null:
		_stage_controller.set_actions_enabled(presented)
	process_mode = Node.PROCESS_MODE_INHERIT if presented else Node.PROCESS_MODE_DISABLED


func terrain_layout_read_only() -> GeneratedStageLayout:
	return _generated_layout


## Delivery-only frame hold used to capture the real pending-preview surface
## before the bounded predictor publishes the latest aim key.
func hold_prediction_refresh_for_delivery(duration_seconds: float = 0.15) -> void:
	_prediction_scheduler.hold_refresh_for_seconds(duration_seconds)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			_stage_controller.toggle_pause(StageController.ActionOrigin.HUMAN)
		KEY_R:
			if event.shift_pressed and stage_data.uses_target_band():
				_stage_controller.restart_new_deal(false, StageController.ActionOrigin.HUMAN)
			else:
				_stage_controller.restart(false, StageController.ActionOrigin.HUMAN)


func set_pause_overlay_suspended(suspended: bool) -> void:
	_hud.set_pause_overlay_suspended(suspended)


func focus_pause_settings() -> void:
	_hud.focus_pause_settings()


func _build_stage_world() -> bool:
	_terrain_surface.position = stage_data.terrain_center
	assert(stage_data.generation_profile != null, "Gameplay stages require a generation profile.")
	_generated_layout = _prepared_artifact.runtime_layout \
			if _prepared_artifact != null else _prepared_layout.copy_for_runtime() \
					if _prepared_layout_matches_stage() else null
	if not _layout_matches_stage(_generated_layout, stage_data):
		push_error("GameplayScene cannot construct a stage without its prepared baked layout.")
		return false
	if not _terrain_surface.configure(
		_generated_layout,
		_prepared_artifact.geometry if _prepared_artifact != null else null,
		_prepared_artifact.playable_local_points \
				if _prepared_artifact != null else PackedVector3Array(),
		_prepared_artifact.presentation_local_points \
				if _prepared_artifact != null else PackedVector3Array()
	):
		return false
	_open_play_environment.configure(
		_generated_layout.play_bounds,
		stage_data.paint_world_bounds(),
		stage_data.terrain_center.y
	)
	_projectile_manager.configure_terrain(_terrain_surface)
	_cannon.global_transform = stage_data.cannon_transform
	var paint_material := ShaderMaterial.new()
	paint_material.shader = load("res://src/paint/terrain_paint.gdshader")
	# The mountain must read as a faceted 3D mass against the open sky and quiet
	# apron. Reserve this cooler mid-value range for terrain relief.
	paint_material.set_shader_parameter("rock_color", Color("94979E"))
	paint_material.set_shader_parameter("shadow_tint", Color("5F6875"))
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
		PAINT_SURFACE_TUNING,
		_prepared_artifact.paint_bootstrap if _prepared_artifact != null else null
	)
	if stage_data.uses_target_band():
		paint_material.set_shader_parameter(&"red_paint_color", stage_data.red_paint_color)
		paint_material.set_shader_parameter(&"green_paint_color", stage_data.green_paint_color)
	var top_body := _terrain_surface.get_node("TerrainTopBody") as StaticBody3D
	_paint_system.configure_top_surface_identity(
		top_body.get_rid(),
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID,
		0
	)
	_projectile_manager.configure_paint_admission(
		_paint_system.queue_radial_paint_mark,
		_paint_system.queue_surface_paint_sweep
	)
	_terrain_mesh.material_override = paint_material
	_terrain_paint_material = paint_material
	var prepared_decorations: Array[DecorationPlacement] = []
	var prepared_decoration_scenes: Dictionary = {}
	if _prepared_artifact != null:
		prepared_decorations = _prepared_artifact.decoration_placements
		prepared_decoration_scenes = _prepared_artifact.decoration_scenes
	_environment_dressing.configure(
		stage_data,
		_generated_layout,
		prepared_decorations,
		prepared_decoration_scenes
	)
	_spawn_mechanisms()
	return true


func _prepared_layout_matches_stage() -> bool:
	return _prepared_stage_id == stage_data.stage_id \
			and _prepared_layout != null \
			and _prepared_layout_checksum != 0 \
			and _prepared_layout.checksum == _prepared_layout_checksum \
			and _layout_matches_stage(_prepared_layout, stage_data) \
			and _prepared_layout.is_runtime_ready()


func _publish_stage_prepared() -> void:
	if _stage_preparation_complete or stage_data == null:
		return
	_stage_preparation_complete = true
	stage_prepared.emit(stage_data.stage_id)


func _complete_stage_preparation() -> void:
	if _stage_preparation_complete or not is_inside_tree():
		return
	RuntimeDeliveryTelemetry.emit_marker(&"gameplay_warmup_started", {
		"stage_id": String(stage_data.stage_id) if stage_data != null else "",
	})
	var warmup := GameplayFirstUseWarmup.new()
	warmup.name = "GameplayFirstUseWarmup"
	add_child(warmup)
	await warmup.run(
		_terrain_mesh.mesh as ArrayMesh,
		_terrain_paint_material,
		_cannon.projectile_data,
		_presentation_effects.warmup_sources()
	)
	if not is_inside_tree():
		return
	if not warmup.is_complete():
		_fail_stage_preparation("Gameplay first-use render warm-up did not complete.")
		return
	RuntimeDeliveryTelemetry.emit_marker(&"gameplay_warmup_complete", {
		"stage_id": String(stage_data.stage_id) if stage_data != null else "",
		"effect_family_count": warmup.warmed_effect_family_count(),
		"projectile_family_count": warmup.warmed_projectile_family_count(),
	})
	warmup.queue_free()
	_publish_stage_prepared()


func _fail_stage_preparation(message: String) -> void:
	push_error(message)
	stage_preparation_failed.emit(stage_data.stage_id if stage_data != null else &"")


func _layout_matches_stage(layout: GeneratedStageLayout, selected_stage: StageData) -> bool:
	return layout != null and layout.matches_stage_identity(selected_stage)


func _connect_systems() -> void:
	_cannon.aim_changed.connect(_on_aim_changed)
	# StageController owns the complete Fire contract (prediction key, capacity,
	# shots, and terminal state). Do not let the cannon's partial
	# aim-validity signal overwrite that authoritative HUD decision.
	_stage_controller.fire_readiness_changed.connect(_hud.set_fire_readiness)
	_stage_controller.deal_changed.connect(_on_deal_changed)
	_stage_controller.score_changed.connect(_hud.update_target_score)
	_stage_controller.finish_readiness_changed.connect(_hud.set_finish_readiness)
	_projectile_manager.transient_splash_requested.connect(_on_transient_splash_requested)
	_projectile_manager.ball_effect_triggered.connect(_on_ball_effect_triggered)
	_projectile_manager.valid_top_traversed.connect(_on_valid_top_traversed)
	_projectile_manager.valid_top_exited.connect(_mechanism_resolver.clear_projectile)
	_projectile_manager.projectile_motion_state_changed.connect(_on_projectile_motion_state_changed)
	_projectile_manager.projectile_woke.connect(_on_projectile_woke)
	_projectile_manager.projectile_terrain_recovered.connect(_on_projectile_terrain_recovered)
	_projectile_manager.projectile_stopped.connect(_on_projectile_stopped)
	_projectile_manager.projectile_spawned.connect(_on_delivery_projectile_spawned)
	_paint_system.coverage_changed.connect(_hud.update_coverage)
	_stage_controller.state_changed.connect(_on_state_changed)
	_stage_controller.shots_changed.connect(_hud.update_shots)
	_stage_controller.shot_fired.connect(_on_shot_fired)
	_stage_controller.shot_observation_sealed.connect(_on_shot_observation_sealed)
	_stage_controller.aim_action_accepted.connect(_on_aim_action_accepted)
	_stage_controller.fire_action_accepted.connect(_on_fire_action_accepted)
	_stage_controller.restart_action_accepted.connect(_on_restart_action_accepted)
	_stage_controller.finish_action_accepted.connect(_on_finish_action_accepted)
	_stage_controller.stage_clock_changed.connect(_on_stage_clock_changed)
	_stage_controller.stage_finished.connect(_on_stage_finished)
	_camera_director.mode_changed.connect(_on_camera_mode_changed)
	_camera_director.interaction_mode_changed.connect(_on_interaction_mode_changed)
	_hud.begin_aiming_requested.connect(func() -> void: _stage_controller.begin_aiming(StageController.ActionOrigin.HUMAN))
	_hud.fire_requested.connect(func() -> void: _aim_input.request_fire())
	_hud.finish_requested.connect(func() -> void: _stage_controller.finish_stage(StageController.ActionOrigin.HUMAN))
	_hud.power_step_requested.connect(_aim_input.adjust_power_button)
	_hud.angle_step_requested.connect(_aim_input.adjust_elevation_button)
	_hud.restart_requested.connect(func() -> void: _stage_controller.restart(false, StageController.ActionOrigin.HUMAN))
	_hud.new_deal_requested.connect(func() -> void: _stage_controller.restart_new_deal(false, StageController.ActionOrigin.HUMAN))
	_hud.pause_requested.connect(func() -> void: _stage_controller.toggle_pause(StageController.ActionOrigin.HUMAN))
	_hud.settings_requested.connect(func() -> void: _request_navigation(&"settings"))
	_hud.stage_select_requested.connect(func() -> void: _request_navigation(&"stage_select"))
	_hud.main_menu_requested.connect(func() -> void: _request_navigation(&"main_menu"))
	_hud.next_stage_requested.connect(func() -> void: _request_navigation(&"next_stage"))
	_hud.interaction_mode_requested.connect(_on_interaction_mode_requested)
	_hud.return_to_cannon_requested.connect(func() -> void: _camera_director.return_to_aim_view())
	_aim_input.aim_interaction_changed.connect(
		_prediction_scheduler.set_aim_interaction_active
	)
	_aim_input.target_pointer_requested.connect(_terrain_aim.queue_pointer_target)
	_aim_input.elevation_step_requested.connect(_terrain_aim.request_elevation_delta)
	_aim_input.power_step_requested.connect(_terrain_aim.request_power_delta)


func _on_aim_changed(yaw: float, elevation: float, power: float) -> void:
	_hud.update_aim(yaw, elevation, power)
	_prediction_scheduler.request_latest()


func _on_transient_splash_requested(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	_presentation_effects.splash(contact.world_position, clampf(contact.relative_normal_speed / 32.0, 0.7, 1.5))
	if is_instance_valid(projectile):
		RuntimeDeliveryTelemetry.emit_for_shot(&"splash_requested", projectile.shot_id, {
			"spawn_ordinal": projectile.spawn_ordinal,
			"effect_id": "splash",
		})
		_queue_effect_frame_marker(projectile.shot_id, projectile.spawn_ordinal, &"splash")
	_audio_cue(&"impact")
	_camera_director.add_impact_shake(clampf(contact.relative_normal_speed / 80.0, 0.12, 0.42))


func _on_shot_fired(_number: int, _yaw: float, _elevation: float, _power: float) -> void:
	_presentation_effects.muzzle_flash(_cannon.get_muzzle_position())
	var observation := _stage_controller.current_shot_observation()
	if observation != null:
		var root_spawn_ordinal := _root_spawn_ordinal(observation.shot_id)
		RuntimeDeliveryTelemetry.emit_for_shot(&"muzzle_flash_requested", observation.shot_id, {
			"spawn_ordinal": root_spawn_ordinal,
			"effect_id": "muzzle_flash",
		})
		_queue_effect_frame_marker(
			observation.shot_id,
			root_spawn_ordinal,
			&"muzzle_flash"
		)
	_audio_cue(&"fire")


func _on_shot_observation_sealed(observation: ShotObservation) -> void:
	_attempt_recorder.record_shot_observation(observation)


func _on_aim_action_accepted(yaw: float, elevation: float, power: float, _origin: int) -> void:
	_attempt_recorder.record_aim(yaw, elevation, power)


func _on_fire_action_accepted(_origin: int) -> void:
	_attempt_recorder.record_aim(
		_cannon.yaw_degrees,
		_cannon.elevation_degrees,
		_cannon.power_percent
	)
	var observation := _stage_controller.current_shot_observation()
	if observation != null:
		if stage_data.uses_target_band():
			_attempt_recorder.record_ball_fire(
				observation.shot_id,
				observation.ball_kind,
				observation.paint_channel
			)
		else:
			_attempt_recorder.record_fire(observation.shot_id)


func _on_restart_action_accepted(_origin: int) -> void:
	_delivery_root_frame_keys.clear()
	_delivery_effect_frame_keys.clear()
	_mechanism_resolver.clear_all()
	_terrain_aim.reset_for_restart()
	_attempt_recorder.start_attempt(
		stage_data,
		_generated_layout.terrain_seed,
		_stage_controller.deal_seed(),
		_stage_controller.attempt_deal_snapshot()
	)


func _on_finish_action_accepted(_origin: int) -> void:
	_attempt_recorder.record_finish(StageController.FINISH_REASON_MANUAL)


func _on_stage_clock_changed(_elapsed_ticks: int, _remaining_ticks: int) -> void:
	_hud.update_clock(_stage_controller.clock_snapshot())


func _on_stage_finished(result: Dictionary) -> void:
	_mechanism_resolver.clear_all()
	_attempt_recorder.store_final_result(result)
	if stage_data.uses_target_band():
		_hud.show_target_band_result_snapshot(result)
		if bool(result.get("cleared", false)):
			_presentation_effects.clear_glint(
				stage_data.terrain_center
					+ Vector3(0.0, float(_generated_layout.metrics.get("maximum_height", 70.0)) + 5.0, 0.0)
			)
			_audio_cue(&"clear")
			var target_game_state := get_node_or_null("/root/GameState")
			if target_game_state != null:
				target_game_state.complete_target_band_stage(stage_data.stage_id, result, true)
		return
	var final_coverage := float(result.get("coverage", 0.0))
	var stars := _stars_for_coverage(final_coverage)
	var game_state := get_node_or_null("/root/GameState")
	var previous_best := float(game_state.best_for(stage_data.stage_id).get("coverage", 0.0)) \
			if game_state != null else 0.0
	_hud.show_coverage_result_snapshot(result, stars, previous_best)
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
	match state:
		StageController.State.BRIEFING:
			GAMEPLAY_PACE.apply_normal()
			_set_mechanism_labels_visible(false)
			_trajectory_preview.visible = false
			_camera_director.set_mode(CameraDirector.Mode.BRIEFING)
		StageController.State.AIMING:
			_set_mechanism_labels_visible(false)
			GAMEPLAY_PACE.apply_active()
			_trajectory_preview.visible = _setting_bool("trajectory_preview", true)
			if _trajectory_preview.visible:
				_trajectory_preview.refresh()
			# Pause/resume must preserve whether the player was inspecting the map
			# or locked into aim. All other entries to Aiming start in Aim Lock.
			if previous_state != StageController.State.PAUSED:
				_camera_director.set_mode(CameraDirector.Mode.AIMING)
		StageController.State.PAUSED:
			GAMEPLAY_PACE.apply_normal()
		StageController.State.FINISHING, StageController.State.RESULT:
			GAMEPLAY_PACE.apply_normal()
			_camera_director.set_mode(CameraDirector.Mode.RESULT)
	# Camera mode and interaction signals must settle before the HUD chooses its
	# focus target. Otherwise its Aiming entry can retain the briefing map button
	# for one input turn and reject an untouched first Space press.
	_hud.show_state(state)
	_update_prediction_consumers()


func _on_interaction_mode_requested(mode: int) -> void:
	if _stage_controller.current_state != StageController.State.AIMING:
		return
	_camera_director.set_interaction_mode(mode as CameraDirector.InteractionMode)


func _on_camera_mode_changed(mode: int) -> void:
	var camera_mode := mode as CameraDirector.Mode
	if camera_mode == CameraDirector.Mode.AIMING:
		_delivery_marker_once(&"aim_view_visible")
	_hud.set_camera_mode(camera_mode)
	var show_preview := _stage_controller.current_state == StageController.State.AIMING \
			and camera_mode == CameraDirector.Mode.AIMING \
			and _setting_bool("trajectory_preview", true)
	_trajectory_preview.visible = show_preview
	if show_preview:
		_trajectory_preview.refresh()
		_prediction_scheduler.request_latest(true)
	_update_prediction_consumers()


func _on_interaction_mode_changed(mode: int) -> void:
	_hud.set_interaction_mode(mode as CameraDirector.InteractionMode)
	_update_prediction_consumers()


func _update_prediction_consumers() -> void:
	if _prediction_scheduler == null or not _prediction_scheduler.is_node_ready():
		return
	var fire_can_consume := _stage_controller != null \
			and _stage_controller.current_state == StageController.State.AIMING \
			and _camera_director.current_mode == CameraDirector.Mode.AIMING \
			and _camera_director.aim_is_locked() \
			and _cannon.input_enabled
	_prediction_scheduler.set_consumers_enabled(
		(_trajectory_preview != null and _trajectory_preview.visible) or fire_can_consume
	)


func _spawn_mechanisms() -> void:
	_mechanisms.clear()
	_mechanism_resolver.configure(_terrain_surface)
	if stage_data.uses_target_band():
		return
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
		_mechanisms.append(mechanism)
	for mechanism in _mechanisms:
		_mechanism_resolver.register_glyph(mechanism)


func _on_deal_changed(
		_visible_tokens: Array[Dictionary],
		_queue_cursor: int,
		_deal_seed: int
) -> void:
	var tokens := _stage_controller.visible_queue_tokens_for_hud()
	_hud.update_queue(tokens)
	var current_token: BallToken = tokens[0] if not tokens.is_empty() else null
	var current_kind := current_token.kind if current_token != null else BallKind.Value.STANDARD
	_trajectory_preview.set_ball_kind(current_kind)
	_prediction_scheduler.set_context_discriminator(
		current_token.stable_key() if current_token != null else &"legacy"
	)

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


func _on_ball_effect_triggered(
		projectile: PaintProjectile,
		effect_id: StringName,
		position: Vector3
) -> void:
	_stage_controller.record_ball_effect(projectile, effect_id)
	var attempt := _live_attempt_observation()
	if attempt != null and is_instance_valid(projectile):
		attempt.record_ball_effect(
			projectile.shot_id,
			projectile.spawn_ordinal,
			effect_id
		)
	_agent_api.notify_event(&"ball_effect_triggered", {
		"effect_id": String(effect_id),
		"shot_id": projectile.shot_id if is_instance_valid(projectile) else 0,
		"spawn_ordinal": projectile.spawn_ordinal if is_instance_valid(projectile) else -1,
		"channel": projectile.paint_channel if is_instance_valid(projectile) else -1,
		"position": position,
	})
	match effect_id:
		&"impact_burst":
			_presentation_effects.impact_burst(position)
			_audio_cue(&"impact_burst")
			_camera_director.add_impact_shake(0.30)
		&"apex_split":
			_presentation_effects.apex_split(position)
			_audio_cue(&"apex_split")
			_camera_director.add_impact_shake(0.12)
		_:
			push_warning("Unknown intrinsic ball effect: %s" % String(effect_id))
			return
	RuntimeDeliveryTelemetry.emit_for_shot(&"effect_requested", projectile.shot_id, {
		"spawn_ordinal": projectile.spawn_ordinal,
		"effect_id": String(effect_id),
	})
	_queue_effect_frame_marker(projectile.shot_id, projectile.spawn_ordinal, effect_id)


func _set_mechanism_labels_visible(visible: bool) -> void:
	for mechanism in _mechanisms:
		mechanism.set_label_visible(visible)


func _stars_for_coverage(coverage: float) -> int:
	var stars := 0
	for threshold in [stage_data.star_thresholds.x, stage_data.star_thresholds.y, stage_data.star_thresholds.z]:
		if coverage + 0.0001 >= threshold:
			stars += 1
	return stars


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
		reason: StringName
) -> void:
	var observation := _live_attempt_observation()
	if observation != null:
		observation.record_projectile_wake(
			projectile.shot_id,
			projectile.spawn_ordinal,
			reason
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


func _on_delivery_projectile_spawned(projectile: PaintProjectile) -> void:
	if not is_instance_valid(projectile) or projectile.split_generation != 0:
		return
	var key := "%d:%d" % [projectile.shot_id, projectile.spawn_ordinal]
	if _delivery_root_frame_keys.has(key):
		return
	_delivery_root_frame_keys[key] = true
	_report_root_frame_presented.call_deferred(
		projectile.get_instance_id(),
		projectile.shot_id,
		projectile.spawn_ordinal
	)


func _report_root_frame_presented(
		projectile_instance_id: int,
		shot_id: int,
		spawn_ordinal: int
) -> void:
	var frame_boundary := await _delivery_frame_boundary()
	if frame_boundary.is_empty() or not is_instance_id_valid(projectile_instance_id):
		return
	RuntimeDeliveryTelemetry.emit_for_shot(&"root_frame_presented", shot_id, {
		"spawn_ordinal": spawn_ordinal,
		"frame_boundary": frame_boundary,
	})


func _queue_effect_frame_marker(
		shot_id: int,
		spawn_ordinal: int,
		effect_id: StringName
) -> void:
	var key := "%d:%d:%s" % [shot_id, spawn_ordinal, String(effect_id)]
	if _delivery_effect_frame_keys.has(key):
		return
	_delivery_effect_frame_keys[key] = true
	_report_effect_frame_presented.call_deferred(
		shot_id,
		spawn_ordinal,
		effect_id
	)


func _report_effect_frame_presented(
		shot_id: int,
		spawn_ordinal: int,
		effect_id: StringName
) -> void:
	var frame_boundary := await _delivery_frame_boundary()
	if frame_boundary.is_empty():
		return
	RuntimeDeliveryTelemetry.emit_for_shot(&"effect_frame_presented", shot_id, {
		"spawn_ordinal": spawn_ordinal,
		"effect_id": String(effect_id),
		"frame_boundary": frame_boundary,
	})


func _delivery_frame_boundary() -> String:
	if DisplayServer.get_name() == "headless":
		if not RuntimeDeliveryTelemetry.test_observer_enabled():
			return ""
		await get_tree().process_frame
		return "test_process_frame"
	await RenderingServer.frame_post_draw
	return "frame_post_draw"


func _root_spawn_ordinal(shot_id: int) -> int:
	for projectile in _projectile_manager.active_projectiles():
		if is_instance_valid(projectile) and projectile.shot_id == shot_id \
				and projectile.split_generation == 0:
			return projectile.spawn_ordinal
	return -1


func _delivery_marker_once(marker: StringName) -> void:
	if _delivery_markers.has(marker):
		return
	_delivery_markers[marker] = true
	RuntimeDeliveryTelemetry.emit_marker(marker, {
		"stage_id": String(stage_data.stage_id) if stage_data != null else "",
		"active_projectiles": _projectile_manager.active_count() \
				if _projectile_manager != null else 0,
	})


func _live_attempt_observation() -> AttemptObservation:
	return _attempt_recorder.current_observation()


func _request_navigation(destination: StringName) -> void:
	navigation_requested.emit(destination)


func _audio_cue(cue: StringName) -> void:
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.play_cue(cue)


func _setting_bool(key: String, fallback: bool) -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return bool(game_state.settings.get(key, fallback)) if game_state != null else fallback
