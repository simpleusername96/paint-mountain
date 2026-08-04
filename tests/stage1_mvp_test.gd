extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const MINIMUM_TOP_CONTACT_SECONDS := 0.75
const MINIMUM_SURFACE_PATH_METERS := 25.0

var _failed := false
var _event_sequence := 0


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.physics_ticks_per_second = 60
	Engine.time_scale = 2.0
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	_assert_true(game_state.select_stage(&"first_descent"), "Stage 1 must be selectable from clean data")

	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	var layout: GeneratedStageLayout = gameplay.generated_layout()
	var stage: StageData = controller.stage_data
	_assert_true(layout != null and layout.is_runtime_ready(), "Stage 1 must construct from a runtime-ready layout")
	_assert_true(
		stage != null and stage.stage_version == 5,
		"Stage 1 must use the accepted generation-v5 contract"
	)
	var default_aim := layout.default_aim
	_assert_true(default_aim != null and default_aim.is_valid(), "Stage 1 must expose a valid admitted default aim")
	var initial_layout_identity := _layout_identity(layout)
	var initial_blank_checksum := paint.paint_mask_checksum()

	var observed := {
		"first_contact": null,
		"sweeps": [],
		"sweep_ticks": {},
		"surface_path": 0.0,
		"applied_count": 0,
		"last_drain_tick": -1,
		"last_drain_sequence": -1,
		"sealed_sequence": -1,
		"shot_result_sequence": -1,
		"states": [],
	}
	manager.projectile_contact_reported.connect(
		func(projectile: PaintProjectile, contact: ProjectileContact) -> void:
			if projectile.spawn_ordinal == 0 and observed.first_contact == null:
				observed.first_contact = contact
	)
	manager.surface_paint_sweep_ready.connect(
		func(command: SurfacePaintSweep) -> void:
			if command.spawn_ordinal != 0 \
					or command.contact_owner_id != TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
					or command.contact_shape_id != TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID:
				return
			observed.sweeps.append(command)
			observed.sweep_ticks[command.physics_tick] = true
			observed.surface_path += command.from_point.distance_to(command.to_point)
	)
	paint.paint_command_applied.connect(
		func(_command, _written: int, _newly_painted: int) -> void:
			observed.applied_count += 1
	)
	paint.paint_commands_drained.connect(
		func(last_drained_tick: int, _count: int, _checksum: int) -> void:
			observed.last_drain_tick = last_drained_tick
			observed.last_drain_sequence = _next_event_sequence()
	)
	controller.shot_observation_sealed.connect(
		func(_observation: ShotObservation) -> void:
			observed.sealed_sequence = _next_event_sequence()
	)
	controller.state_changed.connect(
		func(state: int, _previous: int) -> void:
			observed.states.append(state)
			if state == StageController.State.SHOT_RESULT:
				observed.shot_result_sequence = _next_event_sequence()
	)

	_assert_true(controller.current_state == StageController.State.BRIEFING, "Stage 1 must begin in briefing")
	_assert_true(controller.begin_aiming(), "Stage 1 must accept the canonical begin-aiming action")
	_assert_true(
		controller.set_aim(
			default_aim.yaw_degrees,
			default_aim.elevation_degrees,
			float(default_aim.power_percent)
		),
		"Stage 1 must accept its canonical yaw/elevation/power tuple"
	)
	_assert_true(controller.request_fire(), "Stage 1 must fire its admitted default aim")
	var initial_projectiles := manager.active_projectiles()
	_assert_true(
		initial_projectiles.size() == 1 and initial_projectiles[0].spawn_ordinal == 0,
		"one accepted Fire action must create exactly one ordinal-zero physical paintball"
	)

	var frame_budget := 60 * 26
	while controller.current_state not in [
		StageController.State.AIMING,
		StageController.State.STAGE_CLEAR,
		StageController.State.STAGE_FAILED,
	] and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	_assert_true(frame_budget > 0, "the default Stage 1 shot must reach a bounded decision state")

	var first_contact: ProjectileContact = observed.first_contact
	_assert_true(first_contact != null, "the default Stage 1 shot must report a real physical contact")
	if first_contact != null:
		_assert_true(
			first_contact.contact_owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID \
					and first_contact.contact_shape_id == TrajectoryHitIdentity.TERRAIN_TOP_SHAPE_ID,
			"the default shot's first physical contact must be the stable visible terrain top"
		)
		_assert_true(first_contact.collider_rid.is_valid(), "the first top contact must retain its real collider RID")

	var contact_seconds := _contact_duration_seconds(observed.sweep_ticks)
	_assert_true(
		contact_seconds + 0.0001 >= MINIMUM_TOP_CONTACT_SECONDS,
		"the default paintball must remain on target top for at least %.2f s; got %.3f s" % [
			MINIMUM_TOP_CONTACT_SECONDS, contact_seconds,
		]
	)
	_assert_true(
		float(observed.surface_path) + 0.0001 >= MINIMUM_SURFACE_PATH_METERS,
		"the default paintball must traverse at least %.1f m on the target; got %.3f m" % [
			MINIMUM_SURFACE_PATH_METERS, float(observed.surface_path),
		]
	)
	var centerline := _centerline_evidence(observed.sweeps, paint, stage.paint_world_bounds())
	_assert_true(int(centerline.samples) > 0, "the real sweep path must sample painted terrain texels")
	_assert_true(
		int(centerline.unpainted_samples) == 0,
		"every sampled terrain centerline texel must cross the authoritative paint threshold"
	)
	_assert_true(int(centerline.target_samples) > 0, "the real sweep path must sample target centerline texels")
	_assert_true(
		int(centerline.unpainted_target_samples) == 0,
		"every sampled target centerline texel must cross the authoritative paint threshold"
	)
	_assert_true(paint.coverage_percent() > 0.0, "the physical surface path must increase authoritative coverage")
	var shader_source := FileAccess.get_file_as_string("res://src/paint/terrain_paint.gdshader")
	_assert_true(
		shader_source.contains("texture(paint_mask, UV).r * paintable_surface"),
		"visible paint must use the traversed top surface while target classification remains score-only"
	)
	_assert_true(manager.active_count() == 0, "the shot decision must leave no active projectile")
	_assert_true(manager.pending_intent_count() == 0, "the shot decision must leave no paint intent awaiting canonicalization")
	_assert_true(paint.pending_work_count() == 0, "the shot decision must leave no paint command awaiting drain")
	_assert_true(
		observed.states.has(StageController.State.PAINT_SETTLING) \
				and observed.states.has(StageController.State.SHOT_RESULT),
		"the shot must pass through paint settlement and shot result"
	)
	_assert_true(
		int(observed.last_drain_sequence) >= 0 \
				and int(observed.sealed_sequence) > int(observed.last_drain_sequence) \
				and int(observed.shot_result_sequence) > int(observed.sealed_sequence),
		"the final paint drain must precede observation sealing and SHOT_RESULT"
	)
	var sealed := controller.last_sealed_shot_observation()
	_assert_true(sealed != null and sealed.is_sealed, "the resolved shot must expose one sealed schema-4 observation")
	if sealed != null:
		_assert_true(sealed.schema_version == ShotObservation.SCHEMA_VERSION, "the MVP shot must use the current observation schema")
		_assert_true(sealed.paint_command_count == int(observed.applied_count), "sealed command count must match PaintSystem applications")
		_assert_true(sealed.paint_command_rejection_count == 0, "the admitted MVP shot must not lose any authoritative paint command")
		_assert_true(sealed.final_drain_tick == paint.last_drained_physics_tick(), "sealed drain tick must match PaintSystem")
		_assert_true(sealed.final_paint_mask_checksum == paint.paint_mask_checksum(), "sealed checksum must match the authoritative mask")
		_assert_true(sealed.coverage_after == paint.coverage_percent(), "sealed coverage must match the authoritative mask")
		_assert_true(sealed.penetration_guard_count == 0, "the admitted shot must not pass through terrain")

	var settled_coverage := paint.coverage_percent()
	_assert_true(controller.restart(false), "Restart must be accepted from the Stage 1 decision state")
	_assert_true(controller.current_state == StageController.State.AIMING, "Restart(false) must return directly to aiming")
	_assert_true(controller.shots_remaining == stage.maximum_shots, "Restart must refill the Stage 1 shot count")
	_assert_true(is_zero_approx(paint.coverage_percent()), "Restart must clear authoritative coverage")
	_assert_true(paint.paint_mask_checksum() == initial_blank_checksum, "Restart must restore the identical blank paint mask")
	_assert_true(manager.active_count() == 0 and manager.pending_intent_count() == 0, "Restart must leave no projectile work")
	_assert_true(paint.pending_work_count() == 0, "Restart must leave no queued paint work")
	_assert_true(_layout_identity(gameplay.generated_layout()) == initial_layout_identity, "Restart must preserve the deterministic Stage 1 layout identity")
	_assert_true(
		is_equal_approx(cannon.yaw_degrees, default_aim.yaw_degrees) \
				and is_equal_approx(cannon.elevation_degrees, default_aim.elevation_degrees) \
				and is_equal_approx(cannon.power_percent, float(default_aim.power_percent)),
		"Restart must reapply the same admitted default aim"
	)

	if not _failed:
		print(
			"Stage 1 MVP passed: first terrain/top contact, %.3f s contact, %.3f m path, %d sweeps, %.4f%% coverage, drain-before-result, deterministic restart." % [
				contact_seconds,
				float(observed.surface_path),
				observed.sweeps.size(),
				settled_coverage,
			]
		)
	Engine.time_scale = 1.0
	paused = false
	game_state.persistence_enabled = true
	gameplay.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _centerline_evidence(sweeps: Array, paint: PaintSystem, world_bounds: Rect2) -> Dictionary:
	var paint_bytes := paint.paint_bytes_read_only()
	var target_bytes := paint.target_bytes_read_only()
	var threshold := 128
	var samples := 0
	var unpainted_samples := 0
	var target_samples := 0
	var unpainted_target_samples := 0
	var sample_spacing := minf(
		world_bounds.size.x / float(PaintSystem.MASK_SIZE),
		world_bounds.size.y / float(PaintSystem.MASK_SIZE)
	) * 0.5
	for command: SurfacePaintSweep in sweeps:
		var distance := command.from_point.distance_to(command.to_point)
		var steps := maxi(1, ceili(distance / maxf(sample_spacing, 0.05)))
		for step in range(steps + 1):
			var point := command.from_point.lerp(command.to_point, float(step) / float(steps))
			var uv := (Vector2(point.x, point.z) - world_bounds.position) / world_bounds.size
			if uv.x < 0.0 or uv.x >= 1.0 or uv.y < 0.0 or uv.y >= 1.0:
				continue
			var pixel := Vector2i(
				clampi(floori(uv.x * PaintSystem.MASK_SIZE), 0, PaintSystem.MASK_SIZE - 1),
				clampi(floori(uv.y * PaintSystem.MASK_SIZE), 0, PaintSystem.MASK_SIZE - 1)
			)
			var index := pixel.y * PaintSystem.MASK_SIZE + pixel.x
			samples += 1
			if paint_bytes[index] < threshold:
				unpainted_samples += 1
			if target_bytes[index] < threshold:
				continue
			target_samples += 1
			if paint_bytes[index] < threshold:
				unpainted_target_samples += 1
	return {
		"samples": samples,
		"unpainted_samples": unpainted_samples,
		"target_samples": target_samples,
		"unpainted_target_samples": unpainted_target_samples,
	}


func _contact_duration_seconds(ticks: Dictionary) -> float:
	return float(ticks.size()) / 60.0


func _layout_identity(layout: GeneratedStageLayout) -> Dictionary:
	return {
		"requested_seed": layout.terrain_seed,
		"accepted_seed": layout.accepted_seed,
		"height_checksum": layout.checksum,
		"target_checksum": layout.target_mask_checksum,
		"placement_checksum": layout.placement_checksum(),
		"containment_checksum": layout.containment.checksum(),
		"default_aim": String(layout.default_aim.stable_key()),
	}


func _next_event_sequence() -> int:
	_event_sequence += 1
	return _event_sequence


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("Stage 1 MVP check failed: %s" % message)
	_failed = true
