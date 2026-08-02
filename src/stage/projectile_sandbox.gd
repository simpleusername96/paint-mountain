extends Node3D

@onready var _camera: Camera3D = %Camera
@onready var _mountain_mesh: MeshInstance3D = %MountainMesh
@onready var _mountain_collision: CollisionShape3D = %MountainCollision
@onready var _cannon: CannonController = %Cannon
@onready var _trajectory_preview: TrajectoryPreview = %TrajectoryPreview
@onready var _projectile_manager: ProjectileManager = %ProjectileManager
@onready var _angle_value: Label = %AngleValue
@onready var _power_value: Label = %PowerValue
@onready var _status_value: Label = %StatusValue


func _ready() -> void:
	var mountain := TerrainMeshFactory.build(0)
	_mountain_mesh.mesh = mountain
	_mountain_collision.shape = mountain.create_trimesh_shape()
	_camera.look_at(Vector3(0.0, 25.0, -102.0), Vector3.UP)
	_cannon.aim_changed.connect(_on_aim_changed)
	_cannon.fire_requested.connect(_on_fire_requested)
	_projectile_manager.all_projectiles_settled.connect(_on_all_projectiles_settled)
	_trajectory_preview.configure(_cannon)
	_on_aim_changed(_cannon.yaw_degrees, _cannon.elevation_degrees, _cannon.power_percent)
	print("Paint Mountain Phase 2 projectile sandbox ready.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_tree().quit()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_projectile_manager.cleanup()


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
