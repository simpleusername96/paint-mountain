class_name GameplayAgentApi
extends Node

signal gameplay_event(event_name: StringName, payload: Dictionary)

var _stage_data: StageData
var _generated_layout: GeneratedStageLayout
var _stage_controller: StageController
var _cannon: CannonController
var _paint_system: PaintSystem
var _projectile_manager: ProjectileManager
var _camera_director: CameraDirector
var _mechanisms: Array[GimmickBase] = []
var _previous_shot: Dictionary = {}


func configure(
		stage_data: StageData,
		stage_controller: StageController,
		cannon: CannonController,
		paint_system: PaintSystem,
	projectile_manager: ProjectileManager,
	camera_director: CameraDirector,
	mechanisms: Array[GimmickBase],
	generated_layout: GeneratedStageLayout = null
) -> void:
	_stage_data = stage_data
	_generated_layout = generated_layout
	_stage_controller = stage_controller
	_cannon = cannon
	_paint_system = paint_system
	_projectile_manager = projectile_manager
	_camera_director = camera_director
	_mechanisms = mechanisms
	_stage_controller.shot_fired.connect(_on_shot_fired)
	_stage_controller.shot_observation_sealed.connect(_on_shot_observation_sealed)
	_stage_controller.stage_cleared.connect(func(coverage: float, _shots: int) -> void: gameplay_event.emit(&"stage_cleared", {"coverage": coverage}))
	_stage_controller.stage_failed.connect(func(coverage: float, missing: float) -> void: gameplay_event.emit(&"stage_failed", {"coverage": coverage, "missing": missing}))
	_projectile_manager.projectile_contact_reported.connect(func(projectile: PaintProjectile, contact: ProjectileContact) -> void: gameplay_event.emit(&"projectile_impacted", {
		"spawn_ordinal": projectile.spawn_ordinal,
		"position": contact.world_position,
		"normal": contact.normal,
		"speed": contact.relative_normal_speed,
		"impulse": contact.impulse,
		"impulse_was_measured": contact.impulse_was_measured,
		"contact_owner_id": String(contact.contact_owner_id),
		"contact_shape_id": String(contact.contact_shape_id),
		"local_shape_index": contact.local_shape_index,
		"collider_shape_index": contact.collider_shape_index,
		"physics_tick": contact.physics_tick,
		"source_event_index": contact.source_event_index,
	}))


func get_observation() -> Dictionary:
	var mechanism_states: Array[Dictionary] = []
	for mechanism in _mechanisms:
		mechanism_states.append(mechanism.state_snapshot())
	return {
		"schema_version": ShotObservation.SCHEMA_VERSION,
		"stage_id": String(_stage_data.stage_id),
		"terrain_seed": _generated_layout.terrain_seed if _generated_layout != null else _stage_data.stage_number * 1000 + _stage_data.stage_version,
		"accepted_seed": _generated_layout.accepted_seed if _generated_layout != null else 0,
		"height_grid_checksum": _generated_layout.checksum if _generated_layout != null else 0,
		"layout": _layout_metadata(),
		"target_coverage": _stage_data.target_coverage,
		"current_coverage": _paint_system.coverage_percent(),
		"paint": {
			"pending_command_count": _paint_system.pending_work_count(),
			"last_drained_tick": _paint_system.last_drained_physics_tick(),
			"mask_checksum": _paint_system.paint_mask_checksum(),
		},
		"shots_remaining": _stage_controller.shots_remaining,
		"cannon": {
			"yaw": _cannon.yaw_degrees,
			"elevation": _cannon.elevation_degrees,
			"power": _cannon.power_percent,
		},
		"terrain_bounds": (
			_generated_layout.containment.containment_bounds
			if _generated_layout != null and _generated_layout.containment != null
			else AABB()
		),
		"terrain_height_grid": _height_grid(13, 9),
		"mechanisms": mechanism_states,
		"previous_shot": _previous_shot.duplicate(true),
		"active_projectiles": _projectile_manager.active_count(),
		"ready_for_action": _stage_controller.current_state == StageController.State.AIMING,
	}


func set_aim(yaw: float, elevation: float, power: float) -> bool:
	return _stage_controller.set_aim(yaw, elevation, power, StageController.ActionOrigin.AGENT)


func fire() -> bool:
	return _stage_controller.request_fire(StageController.ActionOrigin.AGENT)


func restart() -> void:
	_stage_controller.restart(false, StageController.ActionOrigin.AGENT)


func change_camera(mode: CameraDirector.Mode) -> bool:
	if _stage_controller.action_origin_is_locked():
		return false
	if _stage_controller.current_state not in [StageController.State.BRIEFING, StageController.State.AIMING, StageController.State.PROJECTILE_IN_FLIGHT]:
		return false
	_camera_director.set_mode(mode)
	return true


func start_next_stage() -> bool:
	if _stage_controller.action_origin_is_locked():
		return false
	var next_id := StageCatalog.next_stage_id(_stage_data.stage_id)
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or next_id.is_empty() or not game_state.select_stage(next_id):
		return false
	gameplay_event.emit(&"next_stage_requested", {"stage_id": String(next_id)})
	return true


func notify_event(event_name: StringName, payload: Dictionary = {}) -> void:
	gameplay_event.emit(event_name, payload.duplicate(true))


func _on_shot_fired(order: int, yaw: float, elevation: float, power: float) -> void:
	_previous_shot = {"order": order, "yaw": yaw, "elevation": elevation, "power": power, "coverage_gain": 0.0}
	gameplay_event.emit(&"shot_started", _previous_shot.duplicate(true))


func _on_shot_observation_sealed(observation: ShotObservation) -> void:
	_previous_shot = observation.to_dictionary()
	gameplay_event.emit(&"shot_settled", _previous_shot.duplicate(true))


func _height_grid(columns: int, rows: int) -> Array[PackedFloat32Array]:
	var grid: Array[PackedFloat32Array] = []
	for row in range(rows):
		var values := PackedFloat32Array()
		var local_z := lerpf(-_stage_data.terrain_size.y * 0.5, _stage_data.terrain_size.y * 0.5, float(row) / float(rows - 1))
		for column in range(columns):
			var local_x := lerpf(-_stage_data.terrain_size.x * 0.5, _stage_data.terrain_size.x * 0.5, float(column) / float(columns - 1))
			values.append(
				_generated_layout.height_at_local(local_x, local_z)
				if _generated_layout != null
				else 0.0
			)
		grid.append(values)
	return grid


func _layout_metadata() -> Dictionary:
	if _generated_layout == null:
		return {}
	var certificate := _generated_layout.reachability_certificate
	var default_aim := _generated_layout.default_aim
	return {
		"profile_id": String(_generated_layout.profile_id),
		"profile_version": _generated_layout.profile_version,
		"target_mask_checksum": _generated_layout.target_mask_checksum,
		"reachability_checksum": (
			certificate.reachable_target_checksum
			if certificate != null and certificate.is_valid()
			else 0
		),
		"containment_checksum": (
			_generated_layout.containment.checksum()
			if _generated_layout.containment != null
			else 0
		),
		"placement_checksum": _generated_layout.placement_checksum(),
		"generated_default_aim": {
			"yaw": default_aim.yaw_degrees,
			"elevation": default_aim.elevation_degrees,
			"power": default_aim.power_percent,
		} if default_aim != null else {},
	}
