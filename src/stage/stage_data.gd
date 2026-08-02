class_name StageData
extends Resource

@export_category("Identity")
@export var stage_id: StringName = &"first_descent"
@export var stage_version: int = 1
@export var display_name: String = "FIRST DESCENT"
@export var stage_number: int = 1

@export_category("Rules")
@export_range(0.01, 100.0, 0.01) var target_coverage: float = 0.25
@export_range(1, 12, 1) var maximum_shots: int = 4
@export var paint_color: Color = Color(0.03, 0.38, 1.0, 1.0)
@export var star_thresholds := Vector3(0.25, 0.4, 0.6)
@export_multiline var objective: String = "Paint the broad descent and let gravity extend each route."

@export_category("World")
@export_range(0, 2, 1) var terrain_variant: int = 0
@export var terrain_center := Vector3(0.0, -2.0, -112.0)
@export var terrain_size := Vector2(180.0, 120.0)
@export var cannon_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 5.0))
@export var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))

@export_category("Camera Bookmarks")
@export var briefing_camera_position := Vector3(92.0, 62.0, 24.0)
@export var briefing_camera_target := Vector3(0.0, 24.0, -112.0)
@export var aiming_camera_position := Vector3(5.0, 3.2, 18.0)
@export var aiming_camera_target := Vector3(0.0, 18.0, -102.0)
@export var wide_camera_position := Vector3(82.0, 52.0, 8.0)
@export var wide_camera_target := Vector3(0.0, 22.0, -112.0)
@export var result_camera_position := Vector3(-78.0, 50.0, 4.0)
@export var result_camera_target := Vector3(0.0, 22.0, -112.0)


func paint_world_bounds() -> Rect2:
	return Rect2(
		Vector2(terrain_center.x - terrain_size.x * 0.5, terrain_center.z - terrain_size.y * 0.5),
		terrain_size
	)
