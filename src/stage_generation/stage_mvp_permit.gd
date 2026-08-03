class_name StageMvpPermit
extends Resource

## Temporary persisted proof for the one-default-shot Stage 1 MVP. This is not
## an all-target reachability certificate and must never satisfy release gates.

const CONTRACT_VERSION := 4
const MAXIMUM_CENTROID_DISTANCE_METERS := 8.0
const MILLIMETERS_PER_METER := 1000.0
const CHECKSUM_OFFSET := 2166136261
const CHECKSUM_PRIME := 16777619

@export_storage var serialized_contract_version: int = CONTRACT_VERSION
@export_storage var serialized_stage_id: StringName
@export_storage var serialized_profile_version: int = CONTRACT_VERSION
@export_storage var serialized_requested_seed: int = -1
@export_storage var serialized_accepted_seed: int = -1
@export_storage var serialized_height_checksum: int = 0
@export_storage var serialized_target_checksum: int = 0
@export_storage var serialized_placement_checksum: int = 0
@export_storage var serialized_containment_checksum: int = 0
@export_storage var serialized_default_aim_angle_tenths := Vector2i.ZERO
@export_storage var serialized_default_aim_power: int = -1
# Centroid and both hit points are quantized in GeneratedStageLayout-local
# coordinates so the proof binds geometry rather than a presentation transform.
@export_storage var serialized_target_centroid_millimeters := Vector2i.ZERO
@export_storage var serialized_predictor_owner_id: StringName
@export_storage var serialized_predictor_shape_id: StringName
@export_storage var serialized_predictor_body_shape_index: int = -1
@export_storage var serialized_predictor_terrain_cell := Vector2i(-1, -1)
@export_storage var serialized_predictor_terrain_triangle: int = -1
@export_storage var serialized_predictor_point_millimeters := Vector3i.ZERO
@export_storage var serialized_rigidbody_owner_id: StringName
@export_storage var serialized_rigidbody_shape_id: StringName
@export_storage var serialized_rigidbody_body_shape_index: int = -1
@export_storage var serialized_rigidbody_terrain_cell := Vector2i(-1, -1)
@export_storage var serialized_rigidbody_terrain_triangle: int = -1
@export_storage var serialized_rigidbody_point_millimeters := Vector3i.ZERO
@export_storage var serialized_proof_checksum: int = 0

var stage_id: StringName:
	get:
		return serialized_stage_id
var profile_version: int:
	get:
		return serialized_profile_version
var requested_seed: int:
	get:
		return serialized_requested_seed
var accepted_seed: int:
	get:
		return serialized_accepted_seed
var height_checksum: int:
	get:
		return serialized_height_checksum
var target_checksum: int:
	get:
		return serialized_target_checksum
var placement_checksum: int:
	get:
		return serialized_placement_checksum
var containment_checksum: int:
	get:
		return serialized_containment_checksum
var default_aim: AimTuple:
	get:
		return AimTuple.new(
			float(serialized_default_aim_angle_tenths.x) / 10.0,
			float(serialized_default_aim_angle_tenths.y) / 10.0,
			serialized_default_aim_power
		)
var target_centroid_xz: Vector2:
	get:
		return Vector2(serialized_target_centroid_millimeters) / MILLIMETERS_PER_METER
var predictor_point: Vector3:
	get:
		return Vector3(serialized_predictor_point_millimeters) / MILLIMETERS_PER_METER
var rigidbody_point: Vector3:
	get:
		return Vector3(serialized_rigidbody_point_millimeters) / MILLIMETERS_PER_METER


static func create(
		permit_stage_id: StringName,
		permit_profile_version: int,
		permit_requested_seed: int,
		permit_accepted_seed: int,
		permit_height_checksum: int,
		permit_target_checksum: int,
		permit_placement_checksum: int,
		permit_containment_checksum: int,
		permit_default_aim: AimTuple,
		permit_target_centroid_xz: Vector2,
		permit_predictor_identity: TrajectoryHitIdentity,
		permit_predictor_point: Vector3,
		permit_rigidbody_identity: TrajectoryHitIdentity,
		permit_rigidbody_point: Vector3
) -> StageMvpPermit:
	var permit := StageMvpPermit.new()
	permit.serialized_stage_id = permit_stage_id
	permit.serialized_profile_version = permit_profile_version
	permit.serialized_requested_seed = permit_requested_seed
	permit.serialized_accepted_seed = permit_accepted_seed
	permit.serialized_height_checksum = permit_height_checksum
	permit.serialized_target_checksum = permit_target_checksum
	permit.serialized_placement_checksum = permit_placement_checksum
	permit.serialized_containment_checksum = permit_containment_checksum
	if permit_default_aim != null:
		permit.serialized_default_aim_angle_tenths = Vector2i(
			roundi(permit_default_aim.yaw_degrees * 10.0),
			roundi(permit_default_aim.elevation_degrees * 10.0)
		)
		permit.serialized_default_aim_power = permit_default_aim.power_percent
	permit.serialized_target_centroid_millimeters = _quantize_vector2(
		permit_target_centroid_xz
	)
	_install_predictor_hit(permit, permit_predictor_identity, permit_predictor_point)
	_install_rigidbody_hit(permit, permit_rigidbody_identity, permit_rigidbody_point)
	permit.serialized_proof_checksum = permit._compute_proof_checksum()
	return permit


func is_valid() -> bool:
	if serialized_contract_version != CONTRACT_VERSION \
			or String(serialized_stage_id).is_empty() \
			or serialized_profile_version != CONTRACT_VERSION \
			or serialized_requested_seed < 0 or serialized_accepted_seed < 0:
		return false
	if serialized_height_checksum == 0 or serialized_target_checksum == 0 \
			or serialized_placement_checksum == 0 or serialized_containment_checksum == 0 \
			or serialized_proof_checksum == 0 \
			or serialized_proof_checksum != _compute_proof_checksum():
		return false
	var aim := default_aim
	if aim == null or not aim.is_valid():
		return false
	var predictor_identity := predictor_identity()
	var rigidbody_identity := rigidbody_identity()
	if not _is_target_top_identity(predictor_identity) \
			or not _is_target_top_identity(rigidbody_identity):
		return false
	var centroid := target_centroid_xz
	return Vector2(predictor_point.x, predictor_point.z).distance_to(centroid) \
			<= MAXIMUM_CENTROID_DISTANCE_METERS \
			and Vector2(rigidbody_point.x, rigidbody_point.z).distance_to(centroid) \
					<= MAXIMUM_CENTROID_DISTANCE_METERS


func has_same_proof(other: StageMvpPermit) -> bool:
	return other != null and is_valid() and other.is_valid() \
			and serialized_contract_version == other.serialized_contract_version \
			and serialized_stage_id == other.serialized_stage_id \
			and serialized_profile_version == other.serialized_profile_version \
			and serialized_requested_seed == other.serialized_requested_seed \
			and serialized_accepted_seed == other.serialized_accepted_seed \
			and serialized_height_checksum == other.serialized_height_checksum \
			and serialized_target_checksum == other.serialized_target_checksum \
			and serialized_placement_checksum == other.serialized_placement_checksum \
			and serialized_containment_checksum == other.serialized_containment_checksum \
			and serialized_default_aim_angle_tenths \
					== other.serialized_default_aim_angle_tenths \
			and serialized_default_aim_power == other.serialized_default_aim_power \
			and serialized_target_centroid_millimeters \
					== other.serialized_target_centroid_millimeters \
			and predictor_identity().has_same_surface_address(other.predictor_identity()) \
			and serialized_predictor_point_millimeters \
					== other.serialized_predictor_point_millimeters \
			and rigidbody_identity().has_same_surface_address(other.rigidbody_identity()) \
			and serialized_rigidbody_point_millimeters \
					== other.serialized_rigidbody_point_millimeters \
			and serialized_proof_checksum == other.serialized_proof_checksum


func predictor_identity() -> TrajectoryHitIdentity:
	return TrajectoryHitIdentity.new(
		serialized_predictor_owner_id,
		serialized_predictor_shape_id,
		serialized_predictor_body_shape_index,
		serialized_predictor_terrain_cell,
		serialized_predictor_terrain_triangle,
		Vector3(1.0, 0.0, 0.0)
	)


func rigidbody_identity() -> TrajectoryHitIdentity:
	return TrajectoryHitIdentity.new(
		serialized_rigidbody_owner_id,
		serialized_rigidbody_shape_id,
		serialized_rigidbody_body_shape_index,
		serialized_rigidbody_terrain_cell,
		serialized_rigidbody_terrain_triangle,
		Vector3(1.0, 0.0, 0.0)
	)


static func _install_predictor_hit(
		permit: StageMvpPermit,
		identity: TrajectoryHitIdentity,
		point: Vector3
) -> void:
	if identity == null:
		return
	permit.serialized_predictor_owner_id = identity.contact_owner_id
	permit.serialized_predictor_shape_id = identity.contact_shape_id
	permit.serialized_predictor_body_shape_index = identity.body_shape_index
	permit.serialized_predictor_terrain_cell = identity.terrain_cell
	permit.serialized_predictor_terrain_triangle = identity.terrain_triangle
	permit.serialized_predictor_point_millimeters = _quantize_vector3(point)


static func _install_rigidbody_hit(
		permit: StageMvpPermit,
		identity: TrajectoryHitIdentity,
		point: Vector3
) -> void:
	if identity == null:
		return
	permit.serialized_rigidbody_owner_id = identity.contact_owner_id
	permit.serialized_rigidbody_shape_id = identity.contact_shape_id
	permit.serialized_rigidbody_body_shape_index = identity.body_shape_index
	permit.serialized_rigidbody_terrain_cell = identity.terrain_cell
	permit.serialized_rigidbody_terrain_triangle = identity.terrain_triangle
	permit.serialized_rigidbody_point_millimeters = _quantize_vector3(point)


static func _is_target_top_identity(identity: TrajectoryHitIdentity) -> bool:
	return identity != null and identity.is_valid() \
			and identity.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
			and identity.contact_shape_id == TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID


static func _quantize_vector2(value: Vector2) -> Vector2i:
	if not value.is_finite():
		return Vector2i(0x7fffffff, 0x7fffffff)
	return Vector2i(
		roundi(value.x * MILLIMETERS_PER_METER),
		roundi(value.y * MILLIMETERS_PER_METER)
	)


static func _quantize_vector3(value: Vector3) -> Vector3i:
	if not value.is_finite():
		return Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
	return Vector3i(
		roundi(value.x * MILLIMETERS_PER_METER),
		roundi(value.y * MILLIMETERS_PER_METER),
		roundi(value.z * MILLIMETERS_PER_METER)
	)


func _compute_proof_checksum() -> int:
	# This integrity field binds the produced aim to the exact predictor and
	# rigid-body witnesses. Runtime still validates those witnesses against the
	# reconstructed layout; the checksum prevents an aim-only resource edit from
	# borrowing evidence produced for a different shot.
	var fields := PackedStringArray([
		str(serialized_contract_version),
		String(serialized_stage_id),
		str(serialized_profile_version),
		str(serialized_requested_seed),
		str(serialized_accepted_seed),
		str(serialized_height_checksum),
		str(serialized_target_checksum),
		str(serialized_placement_checksum),
		str(serialized_containment_checksum),
		str(serialized_default_aim_angle_tenths.x),
		str(serialized_default_aim_angle_tenths.y),
		str(serialized_default_aim_power),
		str(serialized_target_centroid_millimeters.x),
		str(serialized_target_centroid_millimeters.y),
		String(serialized_predictor_owner_id),
		String(serialized_predictor_shape_id),
		str(serialized_predictor_body_shape_index),
		str(serialized_predictor_terrain_cell.x),
		str(serialized_predictor_terrain_cell.y),
		str(serialized_predictor_terrain_triangle),
		str(serialized_predictor_point_millimeters.x),
		str(serialized_predictor_point_millimeters.y),
		str(serialized_predictor_point_millimeters.z),
		String(serialized_rigidbody_owner_id),
		String(serialized_rigidbody_shape_id),
		str(serialized_rigidbody_body_shape_index),
		str(serialized_rigidbody_terrain_cell.x),
		str(serialized_rigidbody_terrain_cell.y),
		str(serialized_rigidbody_terrain_triangle),
		str(serialized_rigidbody_point_millimeters.x),
		str(serialized_rigidbody_point_millimeters.y),
		str(serialized_rigidbody_point_millimeters.z),
	])
	var checksum := CHECKSUM_OFFSET
	for byte in "\u001f".join(fields).to_utf8_buffer():
		checksum = checksum ^ int(byte)
		checksum = int((checksum * CHECKSUM_PRIME) & 0xffffffff)
	return checksum
