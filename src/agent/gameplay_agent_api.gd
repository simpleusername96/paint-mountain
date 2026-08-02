class_name GameplayAgentApi
extends Node

signal gameplay_event(event_name: StringName, payload: Dictionary)

var _stage_data: StageData
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
		mechanisms: Array[GimmickBase]
) -> void:
	_stage_data = stage_data
	_stage_controller = stage_controller
	_cannon = cannon
	_paint_system = paint_system
	_projectile_manager = projectile_manager
	_camera_director = camera_director
	_mechanisms = mechanisms
	_stage_controller.shot_fired.connect(_on_shot_fired)
	_stage_controller.shot_result.connect(_on_shot_result)
	_stage_controller.stage_cleared.connect(func(coverage: float, _shots: int) -> void: gameplay_event.emit(&"stage_cleared", {"coverage": coverage}))
	_stage_controller.stage_failed.connect(func(coverage: float, missing: float) -> void: gameplay_event.emit(&"stage_failed", {"coverage": coverage, "missing": missing}))
	_projectile_manager.projectile_impact.connect(func(_projectile: PaintProjectile, position: Vector3, speed: float) -> void: gameplay_event.emit(&"projectile_impacted", {"position": position, "speed": speed}))


func get_observation() -> Dictionary:
	var mechanism_states: Array[Dictionary] = []
	for mechanism in _mechanisms:
		mechanism_states.append(mechanism.state_snapshot())
	return {
		"stage_id": String(_stage_data.stage_id),
		"target_coverage": _stage_data.target_coverage,
		"current_coverage": _paint_system.coverage_percent(),
		"shots_remaining": _stage_controller.shots_remaining,
		"cannon": {
			"yaw": _cannon.yaw_degrees,
			"elevation": _cannon.elevation_degrees,
			"power": _cannon.power_percent,
		},
		"terrain_bounds": _stage_data.stage_bounds,
		"terrain_height_grid": _height_grid(13, 9),
		"mechanisms": mechanism_states,
		"previous_shot": _previous_shot.duplicate(true),
		"active_projectiles": _projectile_manager.active_count(),
		"ready_for_action": _stage_controller.current_state == StageController.State.AIMING,
	}


func set_aim(yaw: float, elevation: float, power: float) -> bool:
	if _stage_controller.current_state != StageController.State.AIMING:
		return false
	_cannon.set_aim(yaw, elevation, power)
	return true


func fire() -> bool:
	return _stage_controller.request_fire()


func restart() -> void:
	_stage_controller.restart(false)


func change_camera(mode: CameraDirector.Mode) -> bool:
	if _stage_controller.current_state not in [StageController.State.BRIEFING, StageController.State.AIMING, StageController.State.PROJECTILE_IN_FLIGHT]:
		return false
	_camera_director.set_mode(mode)
	return true


func start_next_stage() -> bool:
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


func _on_shot_result(gain: float, total: float) -> void:
	_previous_shot["coverage_gain"] = gain
	_previous_shot["total_coverage"] = total
	gameplay_event.emit(&"shot_settled", _previous_shot.duplicate(true))


func _height_grid(columns: int, rows: int) -> Array[PackedFloat32Array]:
	var grid: Array[PackedFloat32Array] = []
	for row in range(rows):
		var values := PackedFloat32Array()
		var local_z := lerpf(-_stage_data.terrain_size.y * 0.5, _stage_data.terrain_size.y * 0.5, float(row) / float(rows - 1))
		for column in range(columns):
			var local_x := lerpf(-_stage_data.terrain_size.x * 0.5, _stage_data.terrain_size.x * 0.5, float(column) / float(columns - 1))
			values.append(TerrainMeshFactory.height_at(_stage_data.terrain_variant, local_x, local_z))
		grid.append(values)
	return grid
