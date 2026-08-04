class_name GeneratedStageLayout
extends RefCounted

const CHECKSUM_OFFSET := 2166136261
const CHECKSUM_PRIME := 16777619

var profile_id: StringName
var profile_version: int
var layout_version: int
var terrain_seed: int
var accepted_seed: int
var generation_attempt: int
var cell_count: Vector2i
var local_bounds: Rect2
var heights: PackedFloat32Array
var top_topology: TerrainTopTopology
var route_graph: GeneratedRouteGraph
var containment: ContainmentSpec
var reachability_certificate: DirectReachabilityCertificate
var generated_default_aim: AimTuple
var metrics: Dictionary = {}
var checksum: int = 0
var mechanism_placements: Array[MechanismPlacement] = []
var decoration_placements: Array[DecorationPlacement] = []
var target_mask: PackedByteArray:
	get:
		return _target_mask.duplicate()
var target_mask_checksum: int:
	get:
		return _target_mask_checksum
var default_aim: AimTuple:
	get:
		if reachability_certificate != null:
			return reachability_certificate.default_aim \
					if reachability_certificate.is_valid() else null
		return generated_default_aim if generated_default_aim != null \
				and generated_default_aim.is_valid() else null

var _target_mask := PackedByteArray()
var _target_mask_checksum: int = 0
var _target_pixel_indices := PackedInt32Array()
var _footprint_cells := PackedByteArray()


func sample_size() -> Vector2i:
	return cell_count + Vector2i.ONE


func is_valid() -> bool:
	var size := sample_size()
	return size.x > 1 and size.y > 1 and heights.size() == size.x * size.y \
			and profile_version == StageGenerationContract.CONTRACT_VERSION \
			and layout_version == StageGenerationContract.CONTRACT_VERSION \
			and has_valid_footprint() \
			and top_topology != null and top_topology.is_valid() \
			and top_topology.matches_height_grid(cell_count, local_bounds, heights) \
			and route_graph != null and route_graph.is_valid() \
			and containment != null and containment.is_valid()


func install_target_mask(bytes: PackedByteArray, mask_checksum: int) -> bool:
	var required_pixel_count := StageGenerationContract.REQUIRED_MASK_SIZE \
			* StageGenerationContract.REQUIRED_MASK_SIZE
	if not _target_mask.is_empty() or bytes.size() != required_pixel_count \
			or mask_checksum == 0 or TargetMaskRasterizer.byte_checksum(bytes) != mask_checksum:
		return false
	_target_mask = bytes.duplicate()
	_target_mask_checksum = mask_checksum
	for pixel_index in range(_target_mask.size()):
		if _target_mask[pixel_index] >= 128:
			_target_pixel_indices.append(pixel_index)
	return true


func install_footprint(cells: PackedByteArray) -> bool:
	if not _footprint_cells.is_empty() or cells.size() != cell_count.x * cell_count.y:
		return false
	var active_count := 0
	for value in cells:
		if value != 0:
			active_count += 1
	if active_count <= 0:
		return false
	_footprint_cells = cells.duplicate()
	return true


func footprint_cells_read_only() -> PackedByteArray:
	return _footprint_cells.duplicate()


func has_valid_footprint() -> bool:
	if _footprint_cells.size() != cell_count.x * cell_count.y:
		return false
	for value in _footprint_cells:
		if value != 0:
			return true
	return false


func has_valid_target_mask() -> bool:
	var required_pixel_count := StageGenerationContract.REQUIRED_MASK_SIZE \
			* StageGenerationContract.REQUIRED_MASK_SIZE
	return _target_mask.size() == required_pixel_count \
			and _target_mask_checksum != 0 \
			and TargetMaskRasterizer.byte_checksum(_target_mask) == _target_mask_checksum


func is_certified() -> bool:
	if not is_valid() or not has_valid_target_mask() \
			or reachability_certificate == null or not reachability_certificate.is_valid():
		return false
	return reachability_certificate.stage_id == StringName(String(profile_id).trim_suffix("_v5")) \
			and reachability_certificate.profile_version == profile_version \
			and reachability_certificate.requested_seed == terrain_seed \
			and reachability_certificate.accepted_seed == accepted_seed \
			and reachability_certificate.height_checksum == checksum \
			and reachability_certificate.target_checksum == _target_mask_checksum \
			and reachability_certificate.placement_checksum == placement_checksum() \
			and reachability_certificate.containment_checksum == containment.checksum() \
			and reachability_certificate.reachable_target_checksum \
					== reachable_target_checksum(
						reachability_certificate.target_witness_indices
					) \
			and default_aim != null and default_aim.is_valid()


func is_runtime_ready() -> bool:
	return is_valid() and has_valid_target_mask() \
			and default_aim != null and default_aim.is_valid()


func target_centroid_local_xz() -> Vector2:
	if not has_valid_target_mask() or _target_pixel_indices.is_empty():
		return Vector2(INF, INF)
	var sum := Vector2.ZERO
	var mask_size := StageGenerationContract.REQUIRED_MASK_SIZE
	for pixel_index in _target_pixel_indices:
		var pixel := Vector2i(pixel_index % mask_size, pixel_index / mask_size)
		var normalized := Vector2(
			(float(pixel.x) + 0.5) / float(mask_size),
			(float(pixel.y) + 0.5) / float(mask_size)
		)
		sum += local_bounds.position + normalized * local_bounds.size
	return sum / float(_target_pixel_indices.size())


func is_target_local_xz(local_xz: Vector2) -> bool:
	if not has_valid_target_mask() or not local_bounds.has_point(local_xz):
		return false
	var normalized := (local_xz - local_bounds.position) / local_bounds.size
	var mask_size := StageGenerationContract.REQUIRED_MASK_SIZE
	var pixel := Vector2i(
		clampi(floori(normalized.x * mask_size), 0, mask_size - 1),
		clampi(floori(normalized.y * mask_size), 0, mask_size - 1)
	)
	return _target_mask[pixel.y * mask_size + pixel.x] >= 128


func placement_checksum() -> int:
	var hash := CHECKSUM_OFFSET
	hash = _hash_int(hash, mechanism_placements.size())
	for placement in mechanism_placements:
		if placement == null or placement.mechanism_data == null:
			return 0
		hash = _hash_int(hash, int(placement.mechanism_data.kind))
		hash = _hash_int(hash, placement.route_index)
		hash = _hash_int(hash, int(placement.route_role))
		hash = _hash_int(hash, roundi(placement.route_t * 1000000.0))
		for component in [
			placement.local_transform.origin.x,
			placement.local_transform.origin.y,
			placement.local_transform.origin.z,
			placement.downstream_tangent.x,
			placement.downstream_tangent.y,
			placement.downstream_tangent.z,
		]:
			hash = _hash_int(hash, roundi(float(component) * 1000.0))
	return hash


func reachable_target_checksum(target_witness_indices: PackedInt32Array) -> int:
	if target_witness_indices.size() != _target_pixel_indices.size():
		return 0
	var hash := CHECKSUM_OFFSET
	for target_index in range(_target_pixel_indices.size()):
		hash = _hash_int(hash, _target_pixel_indices[target_index])
		hash = _hash_int(hash, target_witness_indices[target_index])
	return hash


func height_at_local(local_x: float, local_z: float) -> float:
	return top_topology.height_at_local(local_x, local_z) if top_topology != null else 0.0


func normal_at_local(local_x: float, local_z: float) -> Vector3:
	return top_topology.normal_at_local(local_x, local_z) if top_topology != null else Vector3.UP


func surface_sample_at_local(local_x: float, local_z: float, clamp_to_bounds: bool = true) -> Dictionary:
	return top_topology.surface_sample_at_local(local_x, local_z, clamp_to_bounds) \
			if top_topology != null else {}


static func _hash_int(hash: int, value: int) -> int:
	for shift in [0, 8, 16, 24]:
		hash = hash ^ ((value >> shift) & 0xff)
		hash = int((hash * CHECKSUM_PRIME) & 0xffffffff)
	return hash
