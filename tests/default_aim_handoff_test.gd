extends SceneTree

const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const TERRAIN_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	# This exactly matches CannonController's pre-ready values and guards the
	# otherwise silent first-entry handoff when no numeric aim value changes.
	var expected_default := Vector3(0.0, 38.0, 68.0)
	var layout := _build_certified_layout(AimTuple.new(
		expected_default.x,
		expected_default.y,
		roundi(expected_default.z)
	))
	_assert_certificate_mutations_fail_closed(layout)
	var stage := StageData.new()
	stage.stage_id = &"terrain_test_fixture"
	stage.maximum_shots = 4
	stage.reachability_certificate = layout.reachability_certificate

	var test_root := Node3D.new()
	root.add_child(test_root)
	var controller := StageController.new()
	var cannon := CANNON_SCENE.instantiate() as CannonController
	var manager := ProjectileManager.new()
	var paint := PaintSystem.new()
	var terrain := TERRAIN_SCENE.instantiate() as TerrainSurface
	var observed_aims: Array[Vector3] = []
	test_root.add_child(cannon)
	test_root.add_child(manager)
	test_root.add_child(paint)
	test_root.add_child(terrain)
	test_root.add_child(controller)
	cannon.aim_changed.connect(func(yaw: float, elevation: float, power: float) -> void:
		observed_aims.append(Vector3(yaw, elevation, power))
	)

	_assert_true(
		controller.configure(stage, layout, cannon, manager, paint, terrain),
		"a certified layout must configure the stage controller"
	)
	_assert_true(
		controller.current_state == StageController.State.BRIEFING,
		"first configure must finish in BRIEFING"
	)
	_assert_aim(cannon, expected_default, "first configure")
	_assert_true(
		manager.stage_bounds == layout.containment.containment_bounds,
		"projectile bounds must come from GeneratedStageLayout.containment"
	)
	cannon.set_aim(-20.0, 20.0, 20.0)
	_assert_true(controller.restart(false), "aiming restart must succeed")
	_assert_true(
		controller.current_state == StageController.State.AIMING,
		"retry restart must finish in AIMING"
	)
	_assert_aim(cannon, expected_default, "AIMING restart")

	cannon.set_aim(25.0, 45.0, 90.0)
	_assert_true(controller.restart(true), "briefing restart must succeed")
	_assert_true(
		controller.current_state == StageController.State.BRIEFING,
		"stage-entry restart must finish in BRIEFING"
	)
	_assert_aim(cannon, expected_default, "BRIEFING restart")
	_assert_true(
		observed_aims.count(expected_default) == 3,
		"each first-entry/restart application must publish the accepted cannon aim"
	)

	if not _failed:
		print("Default-aim handoff checks passed: certified layout owns first entry and both restart destinations.")
	test_root.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _build_certified_layout(default_aim: AimTuple) -> GeneratedStageLayout:
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FLAT)
	layout.checksum = 0x12345678
	var target_mask := PackedByteArray()
	target_mask.resize(StageGenerationContract.REQUIRED_MASK_SIZE * StageGenerationContract.REQUIRED_MASK_SIZE)
	target_mask.fill(255)
	var target_checksum := TargetMaskRasterizer.byte_checksum(target_mask)
	assert(layout.install_target_mask(target_mask, target_checksum))
	var target_witness_indices := PackedInt32Array()
	target_witness_indices.resize(target_mask.size())
	target_witness_indices.fill(0)
	layout.reachability_certificate = DirectReachabilityCertificate.create(
		&"terrain_test_fixture",
		StageGenerationContract.CONTRACT_VERSION,
		layout.terrain_seed,
		layout.accepted_seed,
		layout.checksum,
		target_checksum,
		layout.placement_checksum(),
		layout.containment.checksum(),
		layout.reachable_target_checksum(target_witness_indices),
		0x30405060,
		0x40506070,
		PackedInt32Array([
			roundi(default_aim.yaw_degrees * 10.0),
			roundi(default_aim.elevation_degrees * 10.0),
		]),
		PackedInt32Array([default_aim.power_percent]),
		target_witness_indices,
		PackedFloat32Array([0.25]),
		PackedFloat32Array([1.0]),
		0
	)
	assert(layout.is_certified())
	return layout


func _assert_certificate_mutations_fail_closed(layout: GeneratedStageLayout) -> void:
	var certificate := layout.reachability_certificate
	var original_height_checksum := layout.checksum
	layout.checksum = original_height_checksum ^ 1
	_assert_true(not layout.is_certified(), "a changed generated height checksum must reject the certificate")
	layout.checksum = original_height_checksum

	var original_placement_checksum := certificate.serialized_placement_checksum
	certificate.serialized_placement_checksum = original_placement_checksum ^ 1
	_assert_true(not layout.is_certified(), "a changed placement checksum must reject the certificate")
	certificate.serialized_placement_checksum = original_placement_checksum
	layout.mechanism_placements.append(MechanismPlacement.new())
	_assert_true(not layout.is_certified(), "a changed generated mechanism placement must reject the certificate")
	layout.mechanism_placements.clear()

	var original_reachable_checksum := certificate.serialized_reachable_target_checksum
	certificate.serialized_reachable_target_checksum = original_reachable_checksum ^ 1
	_assert_true(not layout.is_certified(), "a changed target-assignment checksum must reject the certificate")
	certificate.serialized_reachable_target_checksum = original_reachable_checksum

	var original_predictor_checksum := certificate.serialized_predictor_reachability_checksum
	certificate.serialized_predictor_reachability_checksum = 0
	_assert_true(not layout.is_certified(), "a missing predictor proof checksum must reject the certificate")
	certificate.serialized_predictor_reachability_checksum = original_predictor_checksum

	var original_rigidbody_checksum := certificate.serialized_rigidbody_reachability_checksum
	certificate.serialized_rigidbody_reachability_checksum = 0
	_assert_true(not layout.is_certified(), "a missing rigid-body proof checksum must reject the certificate")
	certificate.serialized_rigidbody_reachability_checksum = original_rigidbody_checksum

	var original_assignments := certificate.serialized_target_witness_indices
	certificate.serialized_target_witness_indices = PackedInt32Array([0])
	_assert_true(not layout.is_certified(), "a truncated target assignment must reject the certificate")
	certificate.serialized_target_witness_indices = original_assignments
	_assert_true(layout.is_certified(), "restoring every immutable identity must restore certification")


func _assert_aim(cannon: CannonController, expected: Vector3, context: String) -> void:
	_assert_true(
		is_equal_approx(cannon.yaw_degrees, expected.x)
				and is_equal_approx(cannon.elevation_degrees, expected.y)
				and is_equal_approx(cannon.power_percent, expected.z),
		"%s must apply exact certificate aim %.1f/%.1f/%.0f; got %.1f/%.1f/%.0f" % [
			context,
			expected.x,
			expected.y,
			expected.z,
			cannon.yaw_degrees,
			cannon.elevation_degrees,
			cannon.power_percent,
		]
	)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
