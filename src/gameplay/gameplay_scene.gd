extends Node3D

@export var stage_data: StageData

@onready var _camera: Camera3D = %Camera
@onready var _mountain: Node3D = %Mountain
@onready var _mountain_mesh: MeshInstance3D = %MountainMesh
@onready var _mountain_collision: CollisionShape3D = %MountainCollision
@onready var _cannon: CannonController = %Cannon
@onready var _trajectory_preview: TrajectoryPreview = %TrajectoryPreview
@onready var _projectile_manager: ProjectileManager = %ProjectileManager
@onready var _paint_system: PaintSystem = %PaintSystem
@onready var _stage_controller: StageController = %StageController
@onready var _camera_director: CameraDirector = %CameraDirector
@onready var _hud: HUDController = %HUD

var _shot_has_impacted: bool = false


func _ready() -> void:
	assert(stage_data != null, "GameplayScene requires StageData.")
	_build_stage_world()
	_connect_systems()
	_camera_director.configure(_camera, stage_data, _projectile_manager)
	_trajectory_preview.configure(_cannon)
	_hud.configure(stage_data)
	_stage_controller.configure(stage_data, _cannon, _projectile_manager, _paint_system)
	_hud.show_state(_stage_controller.current_state)
	print("Paint Mountain gameplay scene ready in %s." % _stage_controller.state_name())


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_R:
			_stage_controller.restart(false)
		KEY_TAB:
			if _stage_controller.current_state == StageController.State.AIMING:
				_stage_controller.enter_briefing()
			elif _stage_controller.current_state == StageController.State.BRIEFING:
				_stage_controller.begin_aiming()
		KEY_ESCAPE:
			_stage_controller.toggle_pause()


func _build_stage_world() -> void:
	_mountain.position = stage_data.terrain_center
	var mountain_mesh := TerrainMeshFactory.build(stage_data.terrain_variant)
	_mountain_mesh.mesh = mountain_mesh
	_mountain_collision.shape = mountain_mesh.create_trimesh_shape()
	_cannon.global_transform = stage_data.cannon_transform
	_projectile_manager.stage_bounds = stage_data.stage_bounds
	var paint_material := ShaderMaterial.new()
	paint_material.shader = load("res://src/paint/terrain_paint.gdshader")
	_paint_system.configure(
		stage_data.terrain_variant,
		stage_data.paint_world_bounds(),
		stage_data.terrain_center.y,
		paint_material,
		stage_data.paint_color
	)
	_mountain_mesh.material_override = paint_material


func _connect_systems() -> void:
	_cannon.aim_changed.connect(_hud.update_aim)
	_cannon.fire_requested.connect(func(_origin: Vector3, _velocity: Vector3) -> void: _stage_controller.request_fire())
	_projectile_manager.paint_deposit_requested.connect(_on_paint_deposit_requested)
	_projectile_manager.projectile_impact.connect(_on_projectile_impact)
	_paint_system.coverage_changed.connect(_hud.update_coverage)
	_stage_controller.state_changed.connect(_on_state_changed)
	_stage_controller.shots_changed.connect(_hud.update_shots)
	_stage_controller.shot_fired.connect(_on_shot_fired)
	_stage_controller.shot_result.connect(_hud.show_shot_result)
	_stage_controller.stage_cleared.connect(_on_stage_cleared)
	_stage_controller.stage_failed.connect(_on_stage_failed)
	_hud.begin_aiming_requested.connect(func() -> void: _stage_controller.begin_aiming())
	_hud.fire_requested.connect(func() -> void: _stage_controller.request_fire())
	_hud.restart_requested.connect(func() -> void: _stage_controller.restart(false))
	_hud.pause_requested.connect(func() -> void: _stage_controller.toggle_pause())
	_hud.camera_mode_requested.connect(_on_camera_mode_requested)
	_hud.simulation_speed_requested.connect(_on_simulation_speed_requested)


func _on_paint_deposit_requested(
		_projectile: PaintProjectile,
		kind: StringName,
		world_position: Vector3,
		radius: float,
		amount: float,
		allow_flow: bool
) -> void:
	_paint_system.queue_stamp(kind, world_position, radius, amount, allow_flow)


func _on_projectile_impact(_projectile: PaintProjectile, _position: Vector3, _speed: float) -> void:
	_shot_has_impacted = true


func _on_shot_fired(_number: int, _yaw: float, _elevation: float, _power: float) -> void:
	_shot_has_impacted = false
	Engine.time_scale = 1.0


func _on_state_changed(current_state: int, _previous_state: int) -> void:
	var state := current_state as StageController.State
	_hud.show_state(state)
	match state:
		StageController.State.BRIEFING:
			_trajectory_preview.visible = false
			_camera_director.set_mode(CameraDirector.Mode.BRIEFING)
		StageController.State.AIMING:
			Engine.time_scale = 1.0
			_trajectory_preview.visible = true
			_trajectory_preview.refresh()
			_camera_director.set_mode(CameraDirector.Mode.AIMING)
		StageController.State.PROJECTILE_IN_FLIGHT:
			_trajectory_preview.visible = false
			_camera_director.set_mode(CameraDirector.Mode.FOLLOW)
		StageController.State.PAINT_SETTLING, StageController.State.SHOT_RESULT:
			Engine.time_scale = 1.0
			_camera_director.set_mode(CameraDirector.Mode.WIDE)
		StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED:
			Engine.time_scale = 1.0
			_camera_director.set_mode(CameraDirector.Mode.RESULT)


func _on_stage_cleared(final_coverage: float, shots_used: int) -> void:
	_hud.show_clear(final_coverage, shots_used)


func _on_stage_failed(final_coverage: float, missing: float) -> void:
	_hud.show_failure(final_coverage, missing)


func _on_camera_mode_requested(mode: int) -> void:
	if _stage_controller.current_state not in [
		StageController.State.PROJECTILE_IN_FLIGHT,
		StageController.State.PAINT_SETTLING,
		StageController.State.SHOT_RESULT,
	]:
		return
	_camera_director.set_mode(mode as CameraDirector.Mode)


func _on_simulation_speed_requested(speed: float) -> void:
	if _stage_controller.current_state == StageController.State.PROJECTILE_IN_FLIGHT and _shot_has_impacted:
		Engine.time_scale = clampf(speed, 1.0, 2.0)
