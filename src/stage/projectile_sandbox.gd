extends Node3D

const STAGE := preload("res://resources/stages/first_descent.tres")

@onready var _camera: Camera3D = %Camera
@onready var _terrain_surface: TerrainSurface = %TerrainSurface
@onready var _terrain_mesh: MeshInstance3D = %TerrainMesh
@onready var _cannon: CannonController = %Cannon
@onready var _trajectory_preview: TrajectoryPreview = %TrajectoryPreview
@onready var _projectile_manager: ProjectileManager = %ProjectileManager
@onready var _paint_system: PaintSystem = %PaintSystem
@onready var _angle_value: Label = %AngleValue
@onready var _power_value: Label = %PowerValue
@onready var _status_value: Label = %StatusValue
@onready var _coverage_value: Label = %CoverageValue
@onready var _paint_debug: Control = %PaintDebug
@onready var _paint_debug_texture: TextureRect = %PaintDebugTexture
@onready var _eligible_debug_texture: TextureRect = %EligibleDebugTexture
@onready var _recent_debug_texture: TextureRect = %RecentDebugTexture


func _ready() -> void:
	var layout := SeededStageGenerator.generate(STAGE.generation_profile, STAGE.terrain_seed, STAGE)
	assert(layout != null, "Projectile sandbox requires the validated First Descent layout.")
	_terrain_surface.position = STAGE.terrain_center
	_terrain_surface.configure(layout)
	var paint_material := ShaderMaterial.new()
	paint_material.shader = load("res://src/paint/terrain_paint.gdshader")
	_paint_system.configure(STAGE.paint_world_bounds(), STAGE.terrain_center.y, paint_material, STAGE.paint_color, layout)
	_terrain_mesh.material_override = paint_material
	_camera.look_at(Vector3(0.0, 25.0, -102.0), Vector3.UP)
	_cannon.aim_changed.connect(_on_aim_changed)
	_cannon.fire_requested.connect(_on_fire_requested)
	_projectile_manager.all_projectiles_settled.connect(_on_all_projectiles_settled)
	_projectile_manager.paint_deposit_requested.connect(_on_paint_deposit_requested)
	_paint_system.coverage_changed.connect(_on_coverage_changed)
	_paint_debug_texture.texture = _paint_system.paint_texture()
	_eligible_debug_texture.texture = _paint_system.eligible_texture()
	_recent_debug_texture.texture = _paint_system.recent_texture()
	_trajectory_preview.configure(_cannon)
	_on_aim_changed(_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent)
	print("Paint Mountain Phase 2 projectile sandbox ready.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_tree().quit()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_projectile_manager.cleanup()
		_paint_system.clear()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		_paint_debug.visible = not _paint_debug.visible


func _on_aim_changed(_yaw: float, elevation: float, power: float) -> void:
	_angle_value.text = "%d°" % roundi(elevation)
	_power_value.text = "%d%%" % roundi(power)


func _on_fire_requested(origin: Vector3, velocity: Vector3) -> void:
	if _projectile_manager.active_count() > 0:
		return
	var projectile := _projectile_manager.spawn_projectile(_cannon.projectile_data, origin, velocity)
	if projectile == null:
		return
	_cannon.input_enabled = false
	_trajectory_preview.visible = false
	_status_value.text = "PROJECTILE IN FLIGHT"


func _on_all_projectiles_settled() -> void:
	_cannon.input_enabled = true
	_trajectory_preview.visible = true
	_trajectory_preview.refresh()
	_status_value.text = "AIM MODE · READY"


func _on_paint_deposit_requested(
		_projectile: PaintProjectile,
		kind: StringName,
		world_position: Vector3,
		radius: float,
		amount: float,
		allow_flow: bool
) -> void:
	_paint_system.queue_stamp(kind, world_position, radius, amount, allow_flow)


func _on_coverage_changed(coverage: float) -> void:
	_coverage_value.text = "%05.2f%%" % coverage
