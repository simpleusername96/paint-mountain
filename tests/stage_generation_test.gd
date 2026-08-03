extends SceneTree

const STAGES: Array[StageData] = [
	preload("res://resources/stages/first_descent.tres"),
	preload("res://resources/stages/burst_basin.tres"),
	preload("res://resources/stages/split_ridge.tres"),
]
var _expected_roles: Array[PackedInt32Array] = [
	PackedInt32Array([StageRouteProfile.Role.PRIMARY]),
	PackedInt32Array([StageRouteProfile.Role.PRIMARY, StageRouteProfile.Role.PRIMARY]),
	PackedInt32Array([StageRouteProfile.Role.SAFE, StageRouteProfile.Role.SPLITTER, StageRouteProfile.Role.BUMPER]),
]
var _expected_reversals: Array[PackedInt32Array] = [
	PackedInt32Array([0]),
	PackedInt32Array([2, 2]),
	PackedInt32Array([2, 4, 4]),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var selected_stage := int(_argument_value("stage", "0"))
	var seed_mode := _argument_value("seed", "both")
	var stage_indices := range(STAGES.size()) if selected_stage == 0 else range(selected_stage - 1, selected_stage)
	for stage_index in stage_indices:
		var stage := STAGES[stage_index]
		var profile := stage.generation_profile
		_assert_true(stage.stage_version == 3, "%s StageData version must be 3" % stage.stage_id)
		_assert_true(profile != null and profile.is_valid(), "%s generation profile must be valid" % stage.stage_id)
		_assert_true(profile.profile_version == 3, "%s profile version must be 3" % stage.stage_id)
		_assert_true(profile.cell_count == Vector2i(72, 48), "%s grid must be 72 x 48 cells" % stage.stage_id)
		_assert_true(_profile_has_no_control_points(stage), "%s production profile must not contain control_points" % stage.stage_id)
		if seed_mode == "both" or seed_mode == "base":
			_run_seed_case(stage_index, stage, profile.base_seed, "base")
		if seed_mode == "both" or seed_mode == "fallback":
			_run_seed_case(stage_index, stage, profile.fallback_seed, "fallback-request")
	quit(1 if _failed else 0)


func _argument_value(key: String, fallback: String) -> String:
	var prefix := "--%s=" % key
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback


func _run_seed_case(stage_index: int, stage: StageData, requested_seed: int, label: String) -> void:
	var started := Time.get_ticks_msec()
	var first := SeededStageGenerator.generate(stage.generation_profile, requested_seed, stage)
	var repeated := SeededStageGenerator.generate(stage.generation_profile, requested_seed, stage)
	var elapsed_ms := Time.get_ticks_msec() - started
	_assert_true(first != null, "%s %s seed must generate" % [stage.stage_id, label])
	_assert_true(repeated != null, "%s repeated %s seed must generate" % [stage.stage_id, label])
	if first == null or repeated == null:
		return

	_assert_layout_contract(stage_index, stage, requested_seed, first)
	_assert_true(first.terrain_seed == requested_seed, "%s must record requested seed" % stage.stage_id)
	_assert_true(first.accepted_seed == repeated.accepted_seed, "%s accepted seed must repeat" % stage.stage_id)
	_assert_true(first.generation_attempt == repeated.generation_attempt, "%s accepted attempt must repeat" % stage.stage_id)
	_assert_true(first.checksum == repeated.checksum, "%s height checksum must repeat" % stage.stage_id)
	_assert_true(first.eligible_mask_checksum == repeated.eligible_mask_checksum, "%s eligible-mask checksum must repeat" % stage.stage_id)
	_assert_true(first.route_roles == repeated.route_roles, "%s route roles must repeat" % stage.stage_id)
	_assert_true(first.route_reversal_counts == repeated.route_reversal_counts, "%s reversal metrics must repeat" % stage.stage_id)
	_assert_placements_repeat(stage, first, repeated)
	_assert_decorations_repeat(stage, first, repeated)
	print("%s %s: requested=%d accepted=%d attempt=%d checksums=%d/%d ratio=%.6f elapsed_ms=%d" % [
		stage.stage_id, label, requested_seed, first.accepted_seed, first.generation_attempt,
		first.checksum, first.eligible_mask_checksum,
		float(first.metrics.get("eligible_ratio_after_exclusions", -1.0)), elapsed_ms,
	])


func _assert_layout_contract(stage_index: int, stage: StageData, requested_seed: int, layout: GeneratedStageLayout) -> void:
	var profile := stage.generation_profile
	_assert_true(layout.is_valid(), "%s layout must satisfy its typed shape contract" % stage.stage_id)
	_assert_true(layout.profile_version == 3, "%s layout must record profile version 3" % stage.stage_id)
	_assert_true(layout.cell_count == Vector2i(72, 48), "%s layout grid must be 72 x 48" % stage.stage_id)
	_assert_true(layout.heights.size() == 73 * 49, "%s layout must contain 73 x 49 samples" % stage.stage_id)
	_assert_true(layout.route_roles == _expected_roles[stage_index], "%s route roles must match the frozen profile" % stage.stage_id)
	_assert_true(layout.route_reversal_counts == _expected_reversals[stage_index], "%s route reversals must match the frozen progression" % stage.stage_id)
	_assert_true(int(layout.metrics.get("top_triangles", 0)) == 6912, "%s top mesh must contain 6,912 triangles" % stage.stage_id)
	_assert_true(float(layout.metrics.get("maximum_route_slope", INF)) <= 58.0, "%s maximum route slope must be <= 58 degrees" % stage.stage_id)
	_assert_true(float(layout.metrics.get("p95_route_slope", INF)) <= 50.0, "%s p95 route slope must be <= 50 degrees" % stage.stage_id)
	var maximum_height := float(layout.metrics.get("maximum_height", -INF))
	_assert_true(maximum_height >= profile.accepted_height_range.x and maximum_height <= profile.accepted_height_range.y, "%s maximum height must stay in profile range" % stage.stage_id)
	var eligible_ratio := float(layout.metrics.get("eligible_ratio_after_exclusions", -1.0))
	_assert_true(eligible_ratio >= profile.eligible_ratio_range.x and eligible_ratio <= profile.eligible_ratio_range.y, "%s eligible ratio must stay in profile range" % stage.stage_id)
	_assert_true(layout.eligible_mask.size() == 512 * 512, "%s eligible mask must be 512 x 512" % stage.stage_id)
	_assert_true(layout.eligible_mask_checksum != 0, "%s eligible mask checksum must be populated" % stage.stage_id)
	_assert_true(_accepted_seed_belongs_to_sequence(profile, requested_seed, layout), "%s accepted seed must belong to the 32 attempts or pinned fallback" % stage.stage_id)
	for route in layout.route_spines:
		var realized_start := layout.height_at_local(route[0].x, route[0].z)
		var realized_end := layout.height_at_local(route[-1].x, route[-1].z)
		_assert_true(realized_start - realized_end >= 30.0, "%s every realized route must descend at least 30 m net" % stage.stage_id)
	_assert_edges_are_zero(stage, layout)


func _accepted_seed_belongs_to_sequence(profile: StageGenerationProfile, requested_seed: int, layout: GeneratedStageLayout) -> bool:
	if layout.generation_attempt == -1:
		return layout.accepted_seed == profile.fallback_seed
	if layout.generation_attempt < 0 or layout.generation_attempt >= 32:
		return false
	return layout.accepted_seed == int((requested_seed + layout.generation_attempt * 7919) & 0x7fffffff)


func _assert_edges_are_zero(stage: StageData, layout: GeneratedStageLayout) -> void:
	var size := layout.sample_size()
	for x in range(size.x):
		_assert_true(layout.heights[x] <= 0.01, "%s north edge must reach the shell base" % stage.stage_id)
		_assert_true(layout.heights[(size.y - 1) * size.x + x] <= 0.01, "%s south edge must reach the shell base" % stage.stage_id)
	for z in range(size.y):
		_assert_true(layout.heights[z * size.x] <= 0.01, "%s west edge must reach the shell base" % stage.stage_id)
		_assert_true(layout.heights[z * size.x + size.x - 1] <= 0.01, "%s east edge must reach the shell base" % stage.stage_id)


func _assert_placements_repeat(stage: StageData, first: GeneratedStageLayout, repeated: GeneratedStageLayout) -> void:
	_assert_true(first.mechanism_placements.size() == stage.mechanism_loadout.size(), "%s mechanism loadout must be fully placed" % stage.stage_id)
	_assert_true(repeated.mechanism_placements.size() == first.mechanism_placements.size(), "%s placement count must repeat" % stage.stage_id)
	for index in range(first.mechanism_placements.size()):
		var a := first.mechanism_placements[index]
		var b := repeated.mechanism_placements[index]
		_assert_true(a.route_index == b.route_index and a.route_role == b.route_role, "%s placement ownership must repeat" % stage.stage_id)
		_assert_true(a.local_transform.is_equal_approx(b.local_transform), "%s placement transform must repeat" % stage.stage_id)
		_assert_true(a.downstream_tangent.is_equal_approx(b.downstream_tangent), "%s placement tangent must repeat" % stage.stage_id)


func _assert_decorations_repeat(stage: StageData, first: GeneratedStageLayout, repeated: GeneratedStageLayout) -> void:
	var expected_count: int = [10, 14, 18][stage.stage_number - 1]
	_assert_true(first.decoration_placements.size() == expected_count, "%s decoration count must match" % stage.stage_id)
	_assert_true(repeated.decoration_placements.size() == expected_count, "%s repeated decoration count must match" % stage.stage_id)
	for index in range(mini(first.decoration_placements.size(), repeated.decoration_placements.size())):
		var a := first.decoration_placements[index]
		var b := repeated.decoration_placements[index]
		_assert_true(a.model_id == b.model_id and a.local_xz.is_equal_approx(b.local_xz), "%s decoration placement must repeat" % stage.stage_id)
		_assert_true(is_equal_approx(a.yaw_degrees, b.yaw_degrees) and is_equal_approx(a.uniform_scale, b.uniform_scale), "%s decoration transform must repeat" % stage.stage_id)


func _profile_has_no_control_points(stage: StageData) -> bool:
	var path := stage.generation_profile.resource_path
	var file := FileAccess.open(path, FileAccess.READ)
	return file != null and not file.get_as_text().contains("control_points")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage generation check failed: %s" % message)
