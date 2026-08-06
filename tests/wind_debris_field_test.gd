extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var game_state := root.get_node("/root/GameState")
	var defaults: Dictionary = root.get_node("/root/SaveSystem").default_data()
	game_state.initialize_from_data(defaults)
	game_state.persistence_enabled = false
	game_state.select_stage(&"stage_01")
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	_assert_true(gameplay != null, "wind debris requires the baked Stage 01 gameplay layout")
	if gameplay == null:
		_finish(game_state)
		return
	root.add_child(gameplay)
	var terrain: TerrainSurface = gameplay.get_node("TerrainSurface")
	var wind: WindController = gameplay.get_node("WindController")
	var debris: WindDebrisField = gameplay.get_node("WindDebrisField")
	var leaves := debris.get_node_or_null("WindLeaves") as MultiMeshInstance3D
	_assert_true(leaves != null and leaves.multimesh != null, "debris must own one visual multimesh")
	if leaves == null or leaves.multimesh == null:
		gameplay.queue_free()
		await process_frame
		_finish(game_state)
		return
	var multimesh := leaves.multimesh
	_assert_true(
		multimesh.instance_count >= 36 and multimesh.instance_count <= 60,
		"Stage 01 debris count must stay within the 36-60 visual-density contract"
	)
	_assert_true(
		debris.get_child_count() == 1 \
				and debris.find_children("*", "CollisionObject3D", true, false).is_empty() \
				and debris.find_child("PaintSystem", true, false) == null,
		"debris must keep visual-only responsibility without collision or paint children"
	)
	_assert_true(wind.current_snapshot() != null, "baked Stage 01 must configure wind before debris")
	var initial_positions := debris.instance_positions_read_only()
	_assert_true(
		initial_positions.size() == multimesh.instance_count,
		"every multimesh visual instance must retain one sampled visual position"
	)
	for position in initial_positions:
		_assert_true(
			terrain.contains_world_xz(Vector2(position.x, position.z)),
			"every debris instance must begin above playable TerrainSurface XZ"
		)
	var snapshot_before := wind.current_snapshot()
	var elapsed_before := wind.elapsed_ticks()
	wind.start()
	for _tick in range(8):
		wind._physics_process(1.0 / 60.0)
		debris._physics_process(1.0 / 60.0)
	var snapshot_after := wind.current_snapshot()
	_assert_true(
		wind.elapsed_ticks() == elapsed_before + 8 and snapshot_after != null \
				and snapshot_after.physics_tick == snapshot_before.physics_tick + 8,
		"normal debris motion must observe the unchanged WindController physics snapshot cadence"
	)
	var direction := snapshot_before.push_direction()
	var found_windward_non_wrapped_motion := false
	var final_positions := debris.instance_positions_read_only()
	for index in range(multimesh.instance_count):
		var final_position := final_positions[index]
		_assert_true(
			terrain.contains_world_xz(Vector2(final_position.x, final_position.z)),
			"debris movement must remain above playable TerrainSurface XZ"
		)
		var displacement := final_position - initial_positions[index]
		if Vector2(displacement.x, displacement.z).length() < 1.0 \
				and displacement.dot(direction) > 0.02:
			found_windward_non_wrapped_motion = true
	_assert_true(
		found_windward_non_wrapped_motion,
		"at least one non-wrapped debris instance must move in the current wind push direction"
	)
	var snapshot_before_reduced_motion := wind.current_snapshot()
	var elapsed_before_reduced_motion := wind.elapsed_ticks()
	game_state.update_setting(&"reduced_motion", true, false)
	_assert_true(not debris.visible, "reduced motion must hide only the debris visual")
	for _tick in range(3):
		wind._physics_process(1.0 / 60.0)
		debris._physics_process(1.0 / 60.0)
	var snapshot_after_reduced_motion := wind.current_snapshot()
	_assert_true(
		wind.elapsed_ticks() == elapsed_before_reduced_motion + 3 \
				and snapshot_after_reduced_motion.physics_tick == snapshot_before_reduced_motion.physics_tick + 3,
		"reduced motion must not pause or alter WindController physics snapshots"
	)
	gameplay.queue_free()
	_finish(game_state)


func _finish(game_state: Node) -> void:
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	game_state.persistence_enabled = true
	if not _failed:
		print("Wind debris checks passed: density, playable placement, windward motion, and reduced-motion isolation.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Wind debris check failed: %s" % message)
