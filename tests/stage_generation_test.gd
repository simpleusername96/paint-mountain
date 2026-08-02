extends SceneTree

const PROFILES: Array[StageGenerationProfile] = [
	preload("res://resources/stage_generation/first_descent_profile.tres"),
	preload("res://resources/stage_generation/burst_basin_profile.tres"),
	preload("res://resources/stage_generation/split_ridge_profile.tres"),
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	for profile_index in range(PROFILES.size()):
		var profile := PROFILES[profile_index]
		_assert_true(profile.is_valid(), "%s must be a valid typed resource" % profile.profile_id)
		var started_at := Time.get_ticks_msec()
		var first := SeededStageGenerator.generate(profile, profile.base_seed)
		var generation_ms := Time.get_ticks_msec() - started_at
		var repeated := SeededStageGenerator.generate(profile, profile.base_seed)
		_assert_true(first != null and first.is_valid(), "%s must produce a validated generated layout" % profile.profile_id)
		_assert_true(repeated != null and repeated.checksum == first.checksum, "%s must reproduce the height-grid checksum" % profile.profile_id)
		_assert_true(generation_ms < 3000, "%s generation must complete under three seconds, observed %d ms" % [profile.profile_id, generation_ms])
		if first == null:
			continue
		_assert_true(first.profile_version == 2, "generated layout must record profile version 2")
		_assert_true(first.heights.size() == 65 * 49, "generated layout must contain 65 x 49 samples")
		_assert_true(first.route_spines.size() == profile_index + 1, "%s must contain its frozen route count" % profile.profile_id)
		_assert_true(int(first.metrics.get("triangles", 0)) == 6144, "generated mesh contract must contain exactly 6,144 triangles")
		_assert_true(int(first.metrics.get("reversals", -1)) >= profile.minimum_reversals, "%s must meet its reversal lower bound" % profile.profile_id)
		_assert_true(int(first.metrics.get("reversals", -1)) <= profile.maximum_reversals, "%s must meet its reversal upper bound" % profile.profile_id)
		_assert_true(float(first.metrics.get("maximum_route_slope", 99.0)) <= 48.0, "route slope must stay within the locked maximum")
		_assert_true(float(first.metrics.get("p95_route_slope", 99.0)) <= 42.0, "95th percentile route slope must stay within the locked maximum")
		_assert_true(float(first.metrics.get("eligible_ratio", 0.0)) >= profile.eligible_ratio_range.x, "%s eligible ratio must meet its lower bound" % profile.profile_id)
		_assert_true(float(first.metrics.get("eligible_ratio", 1.0)) <= profile.eligible_ratio_range.y, "%s eligible ratio must meet its upper bound" % profile.profile_id)
		var mesh := TerrainMeshFactory.build_from_layout(first)
		_assert_true(mesh.get_surface_count() == 1, "generated terrain must be one principal mesh")
		_assert_true(mesh.surface_get_array_len(0) / 3 == 6144, "generated terrain mesh must emit exactly 6,144 triangles")
		if not _failed:
			print("%s generation passed in %d ms: seed=%d attempt=%d checksum=%d metrics=%s" % [
				profile.profile_id, generation_ms, first.accepted_seed, first.generation_attempt, first.checksum, str(first.metrics)
			])
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage generation check failed: %s" % message)
