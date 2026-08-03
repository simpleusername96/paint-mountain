class_name GeneratedStageLayout
extends RefCounted

var profile_id: StringName
var profile_version: int
var layout_version: int
var terrain_seed: int
var accepted_seed: int
var generation_attempt: int
var cell_count: Vector2i
var local_bounds: Rect2
var heights: PackedFloat32Array
var route_graph: GeneratedRouteGraph
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
			and profile_version == StageGenerationContract.CONTRACT_VERSION \
			and layout_version == StageGenerationContract.CONTRACT_VERSION \
			and route_graph != null and route_graph.is_valid()


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


func _height_sample(x: int, z: int) -> float:
	return heights[z * sample_size().x + x]
