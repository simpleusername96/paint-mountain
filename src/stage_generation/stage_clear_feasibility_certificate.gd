class_name StageClearFeasibilityCertificate
extends Resource

## Immutable, pure-data evidence that a stage's rule, target, and finite deals
## admit a logical clear. It does not claim exact rigid-body replay or balance.

const SCHEMA_VERSION := 1

@export_storage var schema_version := SCHEMA_VERSION
@export_storage var catalog_version := StageGenerationContract.CONTRACT_VERSION
@export_storage var stage_id: StringName
@export_storage var stage_number := 0
@export_storage var layout_payload_sha256 := ""
@export_storage var target_checksum := 0
@export_storage var target_surface_area_checksum := 0
@export_storage var target_pixel_count := 0
@export_storage var target_component_count := 0
@export_storage var ballistic_target_count := 0
@export_storage var ballistic_sample_count := 0
@export_storage var ballistic_contract_checksum := ""
@export_storage var ballistic_minimum_yaw_margin_degrees := 0.0
@export_storage var ballistic_minimum_perpendicular_margin := 0.0
@export_storage var ballistic_minimum_range_margin := 0.0
@export_storage var ballistic_minimum_height_margin := 0.0
@export_storage var score_witness_red_percent := 0.0
@export_storage var score_witness_green_percent := 0.0
@export_storage var score_witness := 0.0
@export_storage var target_min := 0.0
@export_storage var target_max := 0.0
@export_storage var required_color_ids: Array[StringName] = []
@export_storage var required_ball_kind_ids: Array[StringName] = []
@export_storage var deal_seed_first := 0
@export_storage var deal_count := 0
@export_storage var deal_checksum := ""
@export_storage var maximum_minimum_cover_shots := 0
@export_storage var rule_checksum := ""
@export_storage var capability_checksum := ""
@export_storage var certificate_sha256 := ""


func seal() -> void:
	certificate_sha256 = calculated_sha256()


func is_valid() -> bool:
	return schema_version == SCHEMA_VERSION \
			and catalog_version == StageGenerationContract.CONTRACT_VERSION \
			and not String(stage_id).is_empty() and stage_number >= 1 and stage_number <= 30 \
			and not layout_payload_sha256.is_empty() \
			and target_checksum != 0 and target_surface_area_checksum != 0 \
			and target_pixel_count > 0 and target_component_count == 1 \
			and ballistic_target_count == target_pixel_count \
			and ballistic_sample_count >= 3 and ballistic_sample_count <= target_pixel_count \
			and not ballistic_contract_checksum.is_empty() \
			and _margins_are_valid() and _score_witness_is_valid() \
			and deal_seed_first > 0 and deal_count == 16 \
			and not deal_checksum.is_empty() \
			and maximum_minimum_cover_shots > 0 \
			and not rule_checksum.is_empty() and not capability_checksum.is_empty() \
			and not certificate_sha256.is_empty() \
			and certificate_sha256 == calculated_sha256()


func calculated_sha256() -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(descriptor(false).to_utf8_buffer())
	return context.finish().hex_encode()


func descriptor(include_seal: bool = true) -> String:
	var values := [
		str(schema_version), str(catalog_version), String(stage_id), str(stage_number),
		layout_payload_sha256, str(target_checksum), str(target_surface_area_checksum),
		str(target_pixel_count), str(target_component_count), str(ballistic_target_count),
		str(ballistic_sample_count), ballistic_contract_checksum,
		# Resource text serialization may round a float by a few millionths.
		# Millimetre/0.001-point precision is finer than any authored rule or
		# ballistic tolerance while keeping the content seal reload-stable.
		"%.3f" % ballistic_minimum_yaw_margin_degrees,
		"%.3f" % ballistic_minimum_perpendicular_margin,
		"%.3f" % ballistic_minimum_range_margin,
		"%.3f" % ballistic_minimum_height_margin,
		"%.3f" % score_witness_red_percent,
		"%.3f" % score_witness_green_percent,
		"%.3f" % score_witness,
		"%.3f" % target_min, "%.3f" % target_max,
		str(required_color_ids), str(required_ball_kind_ids),
		str(deal_seed_first), str(deal_count), deal_checksum,
		str(maximum_minimum_cover_shots), rule_checksum, capability_checksum,
	]
	if include_seal:
		values.append(certificate_sha256)
	return "|".join(values)


func _margins_are_valid() -> bool:
	return is_finite(ballistic_minimum_yaw_margin_degrees) \
			and is_finite(ballistic_minimum_perpendicular_margin) \
			and is_finite(ballistic_minimum_range_margin) \
			and is_finite(ballistic_minimum_height_margin) \
			and ballistic_minimum_yaw_margin_degrees >= 0.0 \
			and ballistic_minimum_perpendicular_margin >= 0.0 \
			and ballistic_minimum_range_margin >= 0.0 \
			and ballistic_minimum_height_margin >= 0.0


func _score_witness_is_valid() -> bool:
	return is_finite(score_witness_red_percent) \
			and is_finite(score_witness_green_percent) and is_finite(score_witness) \
			and score_witness_red_percent > 0.0 and score_witness_green_percent > 0.0 \
			and score_witness_red_percent + score_witness_green_percent <= 100.0 \
			and is_finite(target_min) and is_finite(target_max) and target_min < target_max \
			and score_witness >= target_min and score_witness <= target_max
