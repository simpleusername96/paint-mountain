class_name StageGenerationProfile
extends Resource

@export_category("Identity")
@export var profile_id: StringName = &"first_descent_v2"
@export_range(1, 99, 1) var profile_version: int = 2
@export var base_seed: int = 845479992
@export var fallback_seed: int = 1820876501

@export_category("Grid")
@export var cell_count := Vector2i(64, 48)
@export var local_bounds := Rect2(Vector2(-90.0, -60.0), Vector2(180.0, 120.0))
@export_range(1.0, 100.0, 0.5) var nominal_peak: float = 72.0
@export var accepted_height_range := Vector2(64.0, 76.0)

@export_category("Route difficulty")
@export var routes: Array[StageRouteProfile] = []
@export_range(0, 12, 1) var minimum_reversals: int = 0
@export_range(0, 12, 1) var maximum_reversals: int = 1
@export var eligible_ratio_range := Vector2(0.14, 0.22)
@export var shelf_route_indices: PackedInt32Array = PackedInt32Array()
@export var shelf_route_positions: PackedFloat32Array = PackedFloat32Array()
@export var shelf_radii: PackedFloat32Array = PackedFloat32Array()

@export_category("Seeded variation")
@export_range(0.0, 12.0, 0.25) var route_x_jitter: float = 5.0
@export_range(0.0, 5.0, 0.25) var route_height_jitter: float = 1.5
@export_range(0.0, 12.0, 0.25) var shoulder_amplitude: float = 5.0
@export_range(0.0, 5.0, 0.1) var noise_amplitude: float = 1.2


func is_valid() -> bool:
	if profile_version != 2 or cell_count != Vector2i(64, 48):
		return false
	if local_bounds.size != Vector2(180.0, 120.0) or routes.is_empty():
		return false
	if accepted_height_range.x > accepted_height_range.y:
		return false
	if eligible_ratio_range.x > eligible_ratio_range.y:
		return false
	if shelf_route_indices.size() != shelf_route_positions.size() or shelf_route_indices.size() != shelf_radii.size():
		return false
	for route in routes:
		if route == null or not route.is_valid():
			return false
	return true
