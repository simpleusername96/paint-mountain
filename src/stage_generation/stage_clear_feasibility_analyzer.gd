class_name StageClearFeasibilityAnalyzer
extends RefCounted

## Pure-data catalog certifier. No scene, physics space, projectile, controller,
## or mutable paint owner is instantiated here.

const DEAL_SAMPLE_COUNT := 16
const BALLISTIC_SAMPLE_COUNT := 17
const TARGET_THRESHOLD := 128
const NEIGHBORS := [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


static func build(
	stage: StageData,
	baked: BakedStageLayoutData
) -> StageClearFeasibilityCertificate:
	if stage == null or baked == null or not stage.has_valid_rule_contract() \
			or baked.payload_sha256 != StageLayoutBakeCodec.payload_sha256(baked):
		return null
	var layout := StageLayoutBakeCodec.hydrate(baked, stage)
	if layout == null or not layout.is_runtime_ready():
		return null
	var mask := layout.target_mask
	var target_pixels := _target_pixel_indices(mask)
	var component_count := _component_count(mask, StageGenerationContract.REQUIRED_MASK_SIZE)
	if target_pixels.is_empty() or component_count != 1:
		return null
	var ballistic := _ballistic_target_evidence(stage, layout, target_pixels)
	if not bool(ballistic.get("valid", false)):
		return null
	var score_witness := _score_domain_witness(stage, layout, target_pixels)
	if score_witness.is_empty():
		return null
	var deal_evidence := _deal_evidence(stage)
	if not bool(deal_evidence.get("valid", false)):
		return null

	var certificate := StageClearFeasibilityCertificate.new()
	certificate.stage_id = stage.stage_id
	certificate.stage_number = stage.stage_number
	certificate.layout_payload_sha256 = baked.payload_sha256
	certificate.target_checksum = baked.target_checksum
	certificate.target_surface_area_checksum = baked.target_surface_area_checksum
	certificate.target_pixel_count = target_pixels.size()
	certificate.target_component_count = component_count
	certificate.ballistic_target_count = int(ballistic.target_count)
	certificate.ballistic_sample_count = int(ballistic.sample_count)
	certificate.ballistic_contract_checksum = String(ballistic.contract_checksum)
	certificate.ballistic_minimum_yaw_margin_degrees = float(ballistic.yaw_margin)
	certificate.ballistic_minimum_perpendicular_margin = float(ballistic.perpendicular_margin)
	certificate.ballistic_minimum_range_margin = float(ballistic.range_margin)
	certificate.ballistic_minimum_height_margin = float(ballistic.height_margin)
	certificate.score_witness_red_percent = float(score_witness.red_percent)
	certificate.score_witness_green_percent = float(score_witness.green_percent)
	certificate.score_witness = float(score_witness.score)
	certificate.target_min = stage.target_band.target_min
	certificate.target_max = stage.target_band.target_max
	certificate.required_color_ids = _required_color_ids(stage)
	certificate.required_ball_kind_ids = _required_kind_ids(stage)
	certificate.deal_seed_first = stage.default_deal_seed
	certificate.deal_count = DEAL_SAMPLE_COUNT
	certificate.deal_checksum = String(deal_evidence.checksum)
	certificate.maximum_minimum_cover_shots = int(deal_evidence.maximum_cover_shots)
	certificate.rule_checksum = _rule_checksum(stage)
	certificate.capability_checksum = _capability_checksum(stage)
	certificate.seal()
	return certificate if certificate.is_valid() else null


static func matches(
	stored: StageClearFeasibilityCertificate,
	stage: StageData,
	baked: BakedStageLayoutData
) -> bool:
	if stored == null or not stored.is_valid():
		return false
	var rebuilt := build(stage, baked)
	return rebuilt != null and rebuilt.descriptor() == stored.descriptor()


static func mismatch_summary(
	stored: StageClearFeasibilityCertificate,
	stage: StageData,
	baked: BakedStageLayoutData
) -> String:
	if stored == null:
		return "certificate is null"
	var rebuilt := build(stage, baked)
	if rebuilt == null:
		return "current immutable inputs do not admit a certificate"
	var stored_parts := stored.descriptor(false).split("|")
	var rebuilt_parts := rebuilt.descriptor(false).split("|")
	for index in range(mini(stored_parts.size(), rebuilt_parts.size())):
		if stored_parts[index] != rebuilt_parts[index]:
			return "descriptor field %d differs: stored=%s rebuilt=%s; seal=%s/%s" % [
				index, stored_parts[index], rebuilt_parts[index],
				stored.certificate_sha256, stored.calculated_sha256(),
			]
	if not stored.is_valid():
		return "descriptor inputs match but stored seal is invalid: stored=%s calculated=%s" % [
			stored.certificate_sha256, stored.calculated_sha256(),
		]
	return "descriptor size differs: stored=%d rebuilt=%d" % [
		stored_parts.size(), rebuilt_parts.size(),
	]


static func _target_pixel_indices(mask: PackedByteArray) -> PackedInt32Array:
	var result := PackedInt32Array()
	for index in range(mask.size()):
		if mask[index] >= TARGET_THRESHOLD:
			result.append(index)
	return result


static func _component_count(mask: PackedByteArray, mask_size: int) -> int:
	if mask.size() != mask_size * mask_size:
		return 0
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var count := 0
	for seed in range(mask.size()):
		if mask[seed] < TARGET_THRESHOLD or visited[seed] != 0:
			continue
		count += 1
		var queue := PackedInt32Array([seed])
		visited[seed] = 1
		var cursor := 0
		while cursor < queue.size():
			var current := queue[cursor]
			cursor += 1
			var point := Vector2i(current % mask_size, current / mask_size)
			for offset_variant in NEIGHBORS:
				var offset := offset_variant as Vector2i
				var neighbor: Vector2i = point + offset
				if neighbor.x < 0 or neighbor.x >= mask_size \
						or neighbor.y < 0 or neighbor.y >= mask_size:
					continue
				var neighbor_index: int = neighbor.y * mask_size + neighbor.x
				if mask[neighbor_index] >= TARGET_THRESHOLD and visited[neighbor_index] == 0:
					visited[neighbor_index] = 1
					queue.append(neighbor_index)
	return count


static func _ballistic_target_evidence(
	stage: StageData,
	layout: GeneratedStageLayout,
	target_pixels: PackedInt32Array
) -> Dictionary:
	var constraint := ProjectileRangeConstraint.new(stage)
	if not constraint.is_valid():
		return {"valid": false}
	var mask_size := StageGenerationContract.REQUIRED_MASK_SIZE
	var sample_pixels := _evenly_spaced_pixels(target_pixels, BALLISTIC_SAMPLE_COUNT)
	for pixel_index in sample_pixels:
		var pixel := Vector2i(pixel_index % mask_size, pixel_index / mask_size)
		var normalized := Vector2(
			(float(pixel.x) + 0.5) / float(mask_size),
			(float(pixel.y) + 0.5) / float(mask_size)
		)
		var local_xz := layout.local_bounds.position + normalized * layout.local_bounds.size
		var sample := layout.top_topology.surface_sample_at_local(local_xz.x, local_xz.y, false)
		if sample.is_empty() or not bool(constraint.evaluate_local_surface(
			sample.point as Vector3, sample.normal as Vector3
		).get("valid", false)):
			return {"valid": false}
	var metrics := constraint.target_metrics()
	return {
		"valid": int(metrics.ballistic_target_count) == sample_pixels.size(),
		# TargetMaskRasterizer admits or rejects the complete target mask through
		# this same versioned constraint before a baked payload can exist.
		"target_count": target_pixels.size(),
		"sample_count": sample_pixels.size(),
		"contract_checksum": _ballistic_contract_checksum(stage),
		"yaw_margin": float(metrics.ballistic_minimum_yaw_margin_degrees),
		"perpendicular_margin": float(metrics.ballistic_minimum_perpendicular_margin),
		"range_margin": float(metrics.ballistic_minimum_range_margin),
		"height_margin": float(metrics.ballistic_minimum_height_margin),
	}


static func _evenly_spaced_pixels(
	target_pixels: PackedInt32Array,
	requested_count: int
) -> PackedInt32Array:
	var result := PackedInt32Array()
	var count := mini(requested_count, target_pixels.size())
	for index in range(count):
		var source_index := roundi(
			float(index) * float(target_pixels.size() - 1) / float(maxi(count - 1, 1))
		)
		var pixel_index := target_pixels[source_index]
		if result.is_empty() or result[-1] != pixel_index:
			result.append(pixel_index)
	return result


static func _score_domain_witness(
	stage: StageData,
	layout: GeneratedStageLayout,
	target_pixels: PackedInt32Array
) -> Dictionary:
	var projected_area := TargetSurfaceCoverage.projected_texel_area(
		layout.local_bounds, StageGenerationContract.REQUIRED_MASK_SIZE
	)
	# Surface area is never smaller than its XZ projection, so one projected
	# texel is a conservative positive lower bound for the two-color witness.
	var minimum_percent := projected_area / layout.total_target_surface_area * 100.0
	if target_pixels.is_empty() or not is_finite(minimum_percent) \
			or minimum_percent <= 0.0:
		return {}
	var center := stage.target_band.center()
	var red := minimum_percent
	var green := minimum_percent
	var rule := stage.color_score_rule
	if rule.red_weight == 1 and rule.green_weight == 1:
		red = maxf(minimum_percent, center * 0.5)
		green = center - red
	elif rule.red_weight == 1:
		green = minimum_percent
		red = center + green
	elif rule.green_weight == 1:
		red = minimum_percent
		green = center + red
	else:
		return {}
	var coverage := PaintCoverageSnapshot.new(red, green, red + green)
	if not coverage.is_valid():
		return {}
	var score := rule.score(coverage)
	return {
		"red_percent": red,
		"green_percent": green,
		"score": score,
	} if stage.target_band.contains(score) else {}


static func _deal_evidence(stage: StageData) -> Dictionary:
	var feed := PackedByteArray()
	var maximum_cover_shots := 0
	for seed_offset in range(DEAL_SAMPLE_COUNT):
		var seed := stage.default_deal_seed + seed_offset
		var deal := BallDealGenerator.generate(
			stage.stage_id, seed, stage.maximum_shots, stage.ball_deal_profile
		)
		if not BallDealGenerator.is_valid_deal(
			deal, stage.maximum_shots, stage.ball_deal_profile
		):
			return {"valid": false}
		var cover_shots := _minimum_cover_shots(stage, deal)
		if cover_shots <= 0:
			return {"valid": false}
		maximum_cover_shots = maxi(maximum_cover_shots, cover_shots)
		_append_i64(feed, seed)
		for token in deal:
			_append_i64(feed, token.kind)
			_append_i64(feed, token.channel)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(feed)
	return {
		"valid": true,
		"checksum": context.finish().hex_encode(),
		"maximum_cover_shots": maximum_cover_shots,
	}


static func _minimum_cover_shots(stage: StageData, deal: Array[BallToken]) -> int:
	var required_colors := [PaintChannel.Value.RED, PaintChannel.Value.GREEN]
	var required_kinds := stage.required_ball_kinds_for_clear
	for selected_count in range(1, deal.size() + 1):
		for mask in range(1, 1 << deal.size()):
			if _bit_count(mask) != selected_count:
				continue
			var colors := {}
			var kinds := {}
			for index in range(deal.size()):
				if (mask & (1 << index)) == 0:
					continue
				var token := deal[index]
				colors[token.channel] = true
				if BallKind.target_paint_contributor_count(token.kind) > 0:
					kinds[token.kind] = true
			var complete := true
			for channel in required_colors:
				complete = complete and colors.has(channel)
			for kind in required_kinds:
				complete = complete and kinds.has(kind)
			if complete:
				return selected_count
	return -1


static func _bit_count(value: int) -> int:
	var remaining := value
	var count := 0
	while remaining > 0:
		count += remaining & 1
		remaining >>= 1
	return count


static func _required_color_ids(stage: StageData) -> Array[StringName]:
	var result: Array[StringName] = []
	if stage.require_both_paint_channels_for_clear:
		result.assign([&"red", &"green"])
	return result


static func _required_kind_ids(stage: StageData) -> Array[StringName]:
	var result: Array[StringName] = []
	for kind in stage.required_ball_kinds_for_clear:
		result.append(BallKind.stable_id(kind))
	return result


static func _rule_checksum(stage: StageData) -> String:
	return _sha256("|".join([
		String(stage.stage_id), str(stage.maximum_shots),
		str(stage.color_score_rule.red_weight), str(stage.color_score_rule.green_weight),
		"%.6f" % stage.target_band.target_min, "%.6f" % stage.target_band.target_max,
		str(stage.ball_deal_profile.allowed_kinds), str(stage.ball_deal_profile.required_kinds),
		str(stage.require_both_paint_channels_for_clear),
		str(stage.required_ball_kinds_for_clear), str(stage.default_deal_seed),
	]))


static func _capability_checksum(stage: StageData) -> String:
	var parts: Array[String] = []
	for kind in stage.ball_deal_profile.allowed_kinds:
		var capability := BallKind.target_paint_capability_id(kind)
		var contributor_count := BallKind.target_paint_contributor_count(kind)
		if String(capability).is_empty() or contributor_count <= 0:
			return ""
		parts.append("%s:%s:%d" % [BallKind.stable_id(kind), capability, contributor_count])
	return _sha256("|".join(parts))


static func _ballistic_contract_checksum(stage: StageData) -> String:
	var projectile := ProjectileRangeConstraint.DEFAULT_PROJECTILE_DATA
	return _sha256("|".join([
		str(StageGenerationContract.CONTRACT_VERSION),
		str(StageGenerationContract.REQUIRED_MASK_SIZE),
		str(stage.cannon_transform), str(stage.terrain_center),
		"%.6f" % projectile.radius,
		"%.6f" % projectile.minimum_launch_speed,
		"%.6f" % projectile.maximum_launch_speed,
		"%.6f" % projectile.linear_damp,
		"%.6f" % ProjectileRangeConstraint.RANGE_SAMPLE_METERS,
		"%.6f" % ProjectileRangeConstraint.RANGE_TOLERANCE_METERS,
		"%.6f" % ProjectileRangeConstraint.HEIGHT_TOLERANCE_METERS,
		"%.6f" % AimTuple.MINIMUM_YAW_DEGREES,
		"%.6f" % AimTuple.MAXIMUM_YAW_DEGREES,
		"%.6f" % AimTuple.MINIMUM_ELEVATION_DEGREES,
		"%.6f" % AimTuple.MAXIMUM_ELEVATION_DEGREES,
	]))


static func _sha256(value: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()


static func _append_i64(feed: PackedByteArray, value: int) -> void:
	for shift in range(0, 64, 8):
		feed.append((value >> shift) & 0xff)
