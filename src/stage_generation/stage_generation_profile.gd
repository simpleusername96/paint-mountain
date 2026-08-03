class_name StageGenerationProfile
extends Resource

@export_category("Identity")
@export var profile_id: StringName = &"first_descent_v3"
@export_range(1, 99, 1) var profile_version: int = 3
@export var base_seed: int = 845479992
@export var fallback_seed: int = 1820876501

@export_category("Grid")
@export var cell_count := Vector2i(72, 48)
@export var local_bounds := Rect2(Vector2(-90.0, -60.0), Vector2(180.0, 120.0))
@export_range(1.0, 100.0, 0.5) var nominal_peak: float = 72.0
@export var accepted_height_range := Vector2(68.0, 78.0)

@export_category("Route difficulty")
@export var routes: Array[StageRouteProfile] = []
@export_range(0.0, 20.0, 0.5) var bank_height: float = 5.0
@export var eligible_ratio_range := Vector2(0.30, 0.68)

@export_category("Mountain lobes")
@export_range(1, 8, 1) var lobe_count: int = 3
@export var lobe_x_radius_range := Vector2(48.0, 62.0)
@export var lobe_z_radius_range := Vector2(34.0, 46.0)
@export var lobe_peak_multiplier_range := Vector2(0.86, 1.0)
@export_range(0.1, 20.0, 0.1) var smooth_max_k: float = 6.0
@export_range(0.0, 5.0, 0.1) var noise_amplitude: float = 1.2
@export var station_x_jitter_range := Vector2(-1.5, 1.5)


func is_valid() -> bool:
	if profile_version != 3 or cell_count != Vector2i(72, 48):
		return false
	if local_bounds.size != Vector2(180.0, 120.0) or routes.is_empty():
		return false
	if accepted_height_range.x > accepted_height_range.y:
		return false
	if eligible_ratio_range.x > eligible_ratio_range.y:
		return false
	if lobe_count <= 0 or smooth_max_k <= 0.0 or bank_height < 0.0:
		return false
	if lobe_x_radius_range.x <= 0.0 or lobe_x_radius_range.x > lobe_x_radius_range.y:
		return false
	if lobe_z_radius_range.x <= 0.0 or lobe_z_radius_range.x > lobe_z_radius_range.y:
		return false
	if lobe_peak_multiplier_range.x <= 0.0 or lobe_peak_multiplier_range.x > lobe_peak_multiplier_range.y:
		return false
	if station_x_jitter_range.x > station_x_jitter_range.y:
		return false
	for route in routes:
		if route == null or not route.is_valid():
			return false
	return true
