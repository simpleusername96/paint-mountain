class_name DirectReachabilityCertificate
extends RefCounted

const CONTRACT_VERSION := 4

var stage_id: StringName:
	get:
		return _stage_id
var profile_version: int:
	get:
		return _profile_version
var requested_seed: int:
	get:
		return _requested_seed
var accepted_seed: int:
	get:
		return _accepted_seed
var witnesses: Array[AimTuple]:
	get:
		return _witnesses.duplicate()
var target_witness_indices: PackedInt32Array:
	get:
		return _target_witness_indices.duplicate()
var minimum_distance_margins: PackedFloat32Array:
	get:
		return _minimum_distance_margins.duplicate()
var minimum_range_margins: PackedFloat32Array:
	get:
		return _minimum_range_margins.duplicate()
var default_aim: AimTuple:
	get:
		return _default_aim
var reachable_target_checksum: int:
	get:
		return _reachable_target_checksum

var _stage_id: StringName
var _profile_version: int
var _requested_seed: int
var _accepted_seed: int
var _witnesses: Array[AimTuple] = []
var _target_witness_indices: PackedInt32Array
var _minimum_distance_margins: PackedFloat32Array
var _minimum_range_margins: PackedFloat32Array
var _default_aim: AimTuple
var _reachable_target_checksum: int


func _init(
		certificate_stage_id: StringName = &"",
		certificate_profile_version: int = CONTRACT_VERSION,
		certificate_requested_seed: int = -1,
		certificate_accepted_seed: int = -1,
		certificate_witnesses: Array[AimTuple] = [],
		certificate_target_witness_indices: PackedInt32Array = PackedInt32Array(),
		certificate_minimum_distance_margins: PackedFloat32Array = PackedFloat32Array(),
		certificate_minimum_range_margins: PackedFloat32Array = PackedFloat32Array(),
		certificate_default_aim: AimTuple = null,
		certificate_reachable_target_checksum: int = 0
) -> void:
	_stage_id = certificate_stage_id
	_profile_version = certificate_profile_version
	_requested_seed = certificate_requested_seed
	_accepted_seed = certificate_accepted_seed
	for witness in certificate_witnesses:
		_witnesses.append(witness)
	_target_witness_indices = certificate_target_witness_indices.duplicate()
	_minimum_distance_margins = certificate_minimum_distance_margins.duplicate()
	_minimum_range_margins = certificate_minimum_range_margins.duplicate()
	_default_aim = certificate_default_aim
	_reachable_target_checksum = certificate_reachable_target_checksum


func is_valid() -> bool:
	if String(_stage_id).is_empty() or _profile_version != CONTRACT_VERSION \
			or _requested_seed < 0 or _accepted_seed < 0 \
			or _witnesses.is_empty() or _target_witness_indices.is_empty() \
			or _default_aim == null or not _default_aim.is_valid() \
			or _reachable_target_checksum == 0:
		return false
	if _minimum_distance_margins.size() != _witnesses.size() \
			or _minimum_range_margins.size() != _witnesses.size():
		return false
	var default_is_witness := false
	var witness_keys: Dictionary = {}
	for index in range(_witnesses.size()):
		var witness := _witnesses[index]
		if witness == null or not witness.is_valid() \
				or not is_finite(_minimum_distance_margins[index]) \
				or not is_finite(_minimum_range_margins[index]) \
				or _minimum_distance_margins[index] < 0.0 \
				or _minimum_range_margins[index] < 0.0:
			return false
		if witness_keys.has(witness.stable_key()):
			return false
		witness_keys[witness.stable_key()] = true
		default_is_witness = default_is_witness or witness.is_equal_to(_default_aim)
	if not default_is_witness:
		return false
	for witness_index in _target_witness_indices:
		if witness_index < 0 or witness_index >= _witnesses.size():
			return false
	return true
