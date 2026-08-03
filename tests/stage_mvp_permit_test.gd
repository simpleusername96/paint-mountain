extends SceneTree

const FIXTURE_FACTORY := preload("res://tests/support/terrain_test_fixture_factory.gd")
const ROUNDTRIP_PATH := "user://paint_mountain_stage_mvp_permit_test.tres"

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var layout: GeneratedStageLayout = FIXTURE_FACTORY.build_layout(
		FIXTURE_FACTORY.Kind.FLAT
	)
	layout.checksum = 0x12345678
	var target_mask := PackedByteArray()
	target_mask.resize(
		StageGenerationContract.REQUIRED_MASK_SIZE \
				* StageGenerationContract.REQUIRED_MASK_SIZE
	)
	target_mask.fill(255)
	assert(layout.install_target_mask(
		target_mask,
		TargetMaskRasterizer.byte_checksum(target_mask)
	))
	var centroid := layout.target_centroid_local_xz()
	var sample := layout.surface_sample_at_local(centroid.x, centroid.y, false)
	var point: Vector3 = sample.point
	var identity := TrajectoryHitIdentity.terrain_top(
		TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID,
		0,
		sample.cell,
		int(sample.triangle),
		sample.barycentric
	)
	var permit := StageMvpPermit.create(
		&"terrain_test_fixture",
		StageGenerationContract.CONTRACT_VERSION,
		layout.terrain_seed,
		layout.accepted_seed,
		layout.checksum,
		layout.target_mask_checksum,
		layout.placement_checksum(),
		layout.containment.checksum(),
		AimTuple.new(0.0, 38.0, 68),
		centroid,
		identity,
		point,
		identity,
		point
	)
	_assert_true(permit.is_valid(), "a complete one-shot terrain-top proof must be valid")
	layout.mvp_permit = permit
	_assert_true(layout.is_mvp_playable(), "a matching permit must admit the MVP layout")
	_assert_true(not layout.is_certified(), "an MVP permit must never claim full certification")
	_assert_true(
		layout.default_aim.is_equal_to(AimTuple.new(0.0, 38.0, 68)),
		"permit admission must hand off its canonical default aim"
	)

	var save_error := ResourceSaver.save(permit, ROUNDTRIP_PATH)
	_assert_true(save_error == OK, "the typed MVP permit must persist as a Resource")
	var roundtrip := ResourceLoader.load(
		ROUNDTRIP_PATH,
		"StageMvpPermit",
		ResourceLoader.CACHE_MODE_REPLACE
	) as StageMvpPermit
	_assert_true(roundtrip != null and roundtrip.is_valid(), "persisted primitive proof fields must round-trip")
	if roundtrip != null:
		layout.mvp_permit = roundtrip
		_assert_true(layout.is_mvp_playable(), "the round-tripped proof must match the same layout")
	_assert_stale_mutations_fail_closed(layout)

	var invalid_full := DirectReachabilityCertificate.new()
	layout.reachability_certificate = invalid_full
	_assert_true(
		not layout.is_mvp_playable(),
		"a present stale full certificate must not silently fall back to the permit"
	)
	layout.reachability_certificate = null
	_assert_true(layout.is_mvp_playable(), "removing the stale full proof must restore permit admission")

	var absolute_path := ProjectSettings.globalize_path(ROUNDTRIP_PATH)
	if FileAccess.file_exists(ROUNDTRIP_PATH):
		DirAccess.remove_absolute(absolute_path)
	if not _failed:
		print("Stage MVP permit checks passed: persisted one-shot proof admits runtime only and fails closed on stale identities.")
	quit(1 if _failed else 0)


func _assert_stale_mutations_fail_closed(layout: GeneratedStageLayout) -> void:
	var permit := layout.mvp_permit
	var original_aim := permit.serialized_default_aim_angle_tenths
	permit.serialized_default_aim_angle_tenths = original_aim + Vector2i(10, 0)
	_assert_true(
		not permit.is_valid() and not layout.is_mvp_playable(),
		"an aim-only substitution must not borrow hit evidence produced for another shot"
	)
	permit.serialized_default_aim_angle_tenths = original_aim

	var original_height := permit.serialized_height_checksum
	permit.serialized_height_checksum = original_height ^ 1
	_assert_true(not layout.is_mvp_playable(), "a changed height checksum must reject the permit")
	permit.serialized_height_checksum = original_height

	var original_target := permit.serialized_target_checksum
	permit.serialized_target_checksum = original_target ^ 1
	_assert_true(not layout.is_mvp_playable(), "a changed target checksum must reject the permit")
	permit.serialized_target_checksum = original_target

	var original_placement := permit.serialized_placement_checksum
	permit.serialized_placement_checksum = original_placement ^ 1
	_assert_true(not layout.is_mvp_playable(), "a changed placement checksum must reject the permit")
	permit.serialized_placement_checksum = original_placement

	var original_containment := permit.serialized_containment_checksum
	permit.serialized_containment_checksum = original_containment ^ 1
	_assert_true(not layout.is_mvp_playable(), "a changed containment checksum must reject the permit")
	permit.serialized_containment_checksum = original_containment

	var original_centroid := permit.serialized_target_centroid_millimeters
	var changed_centroid := original_centroid + Vector2i(2, 0)
	permit.serialized_target_centroid_millimeters = changed_centroid
	_assert_true(not layout.is_mvp_playable(), "a changed target centroid must reject the permit")
	permit.serialized_target_centroid_millimeters = original_centroid

	var original_point := permit.serialized_predictor_point_millimeters
	var changed_point := original_point + Vector3i(9000, 0, 0)
	permit.serialized_predictor_point_millimeters = changed_point
	_assert_true(not permit.is_valid(), "a predictor hit farther than 8 m from the centroid must be invalid")
	permit.serialized_predictor_point_millimeters = original_point

	var original_owner := permit.serialized_rigidbody_owner_id
	permit.serialized_rigidbody_owner_id = ContainmentSpec.BACKSTOP_OWNER_ID
	_assert_true(not permit.is_valid(), "a non-terrain first rigid-body hit must be invalid")
	permit.serialized_rigidbody_owner_id = original_owner

	var original_layout_checksum := layout.checksum
	layout.checksum = original_layout_checksum ^ 1
	_assert_true(not layout.is_mvp_playable(), "mutating the rebuilt layout must reject the persisted permit")
	layout.checksum = original_layout_checksum
	_assert_true(layout.is_mvp_playable(), "restoring all bound identities must restore MVP admission")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("Stage MVP permit check failed: %s" % message)
	_failed = true
