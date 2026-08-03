class_name GeneratedStageLayout
extends RefCounted

var profile_id: StringName
var profile_version: int
var terrain_seed: int
var accepted_seed: int
var generation_attempt: int
var cell_count: Vector2i
var local_bounds: Rect2
var heights: PackedFloat32Array
var route_spines: Array[PackedVector3Array] = []
var route_widths: PackedFloat32Array
var route_roles: PackedInt32Array
var route_reversal_counts: PackedInt32Array
var route_shelf_positions: PackedFloat32Array
var route_shelf_radii: PackedFloat32Array
var metrics: Dictionary = {}
var checksum: int = 0
var eligible_mask: PackedByteArray
var eligible_mask_checksum: int = 0
var mechanism_placements: Array[MechanismPlacement] = []
var decoration_placements: Array[DecorationPlacement] = []


func sample_size() -> Vector2i:
	return cell_count + Vector2i.ONE


func is_valid() -> bool:
	var size := sample_size()
	return size.x > 1 and size.y > 1 and heights.size() == size.x * size.y \
			and route_spines.size() == route_widths.size() \
			and route_spines.size() == route_roles.size() \
			and route_spines.size() == route_shelf_positions.size() \
			and route_spines.size() == route_shelf_radii.size() \
			and not route_spines.is_empty()


func height_at_local(local_x: float, local_z: float) -> float:
	if heights.is_empty():
		return 0.0
	var normalized := Vector2(
		clampf((local_x - local_bounds.position.x) / local_bounds.size.x, 0.0, 1.0),
		clampf((local_z - local_bounds.position.y) / local_bounds.size.y, 0.0, 1.0)
	)
	var sample_max := sample_size() - Vector2i.ONE
	var grid_position := normalized * Vector2(sample_max)
	var x0 := mini(floori(grid_position.x), sample_max.x)
	var z0 := mini(floori(grid_position.y), sample_max.y)
	var x1 := mini(x0 + 1, sample_max.x)
	var z1 := mini(z0 + 1, sample_max.y)
	var tx := grid_position.x - float(x0)
	var tz := grid_position.y - float(z0)
	var top := lerpf(_height_sample(x0, z0), _height_sample(x1, z0), tx)
	var bottom := lerpf(_height_sample(x0, z1), _height_sample(x1, z1), tx)
	return lerpf(top, bottom, tz)


func normal_at_local(local_x: float, local_z: float) -> Vector3:
	var step_x := local_bounds.size.x / float(cell_count.x)
	var step_z := local_bounds.size.y / float(cell_count.y)
	var left := height_at_local(local_x - step_x, local_z)
	var right := height_at_local(local_x + step_x, local_z)
	var back := height_at_local(local_x, local_z - step_z)
	var front := height_at_local(local_x, local_z + step_z)
	return Vector3(left - right, 2.0 * step_x, back - front).normalized()


func route_position(route_index: int, normalized_position: float) -> Vector3:
	if route_index < 0 or route_index >= route_spines.size():
		return Vector3.ZERO
	var route := route_spines[route_index]
	if route.is_empty():
		return Vector3.ZERO
	if route.size() == 1:
		return route[0]
	var scaled := clampf(normalized_position, 0.0, 1.0) * float(route.size() - 1)
	var first := mini(floori(scaled), route.size() - 1)
	var second := mini(first + 1, route.size() - 1)
	return route[first].lerp(route[second], scaled - float(first))


func route_distance(local_x: float, local_z: float) -> Dictionary:
	var best_distance := INF
	var best_route := -1
	for route_index in range(route_spines.size()):
		var distance := absf(local_x - _route_x_at_z(route_spines[route_index], local_z))
		if distance < best_distance:
			best_distance = distance
			best_route = route_index
	return {"distance": best_distance, "route_index": best_route}


func _height_sample(x: int, z: int) -> float:
	return heights[z * sample_size().x + x]


func _route_x_at_z(route: PackedVector3Array, local_z: float) -> float:
	if local_z <= route[0].z:
		return route[0].x
	for index in range(route.size() - 1):
		var start := route[index]
		var finish := route[index + 1]
		if local_z <= finish.z:
			var t := smoothstep(0.0, 1.0, inverse_lerp(start.z, finish.z, local_z))
			return lerpf(start.x, finish.x, t)
	return route[route.size() - 1].x
