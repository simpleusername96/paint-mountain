extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.selected_stage_id = &"stage_01"
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var camera := gameplay.get_node("Camera") as Camera3D
	var director := gameplay.get_node("CameraDirector") as CameraDirector
	var terrain := gameplay.get_node("TerrainSurface") as TerrainSurface
	var cannon := gameplay.get_node("Cannon") as CannonController
	director.set_mode(CameraDirector.Mode.AIMING, true)
	var cannon_transform := cannon.global_transform
	_assert_true(director.set_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION, true), "Map Inspection must be available from Aim View")
	var stage := StageCatalog.get_stage(&"stage_01")
	var focus := terrain.world_surface_point(Vector2(stage.terrain_center.x, stage.terrain_center.z))
	_assert_true(director.focus_inspection_target(focus), "stable terrain focus must be accepted")
	var landmark := focus + Vector3.FORWARD * 24.0
	var before := camera.unproject_position(landmark)
	var pitch_before := director._inspection_pitch_radians
	_assert_true(director.orbit_inspection(Vector2(-80.0, 0.0)), "right-to-left Map drag must orbit")
	director._apply_inspection_orbit(true)
	var after := camera.unproject_position(landmark)
	_assert_true(after.x > before.x, "right-to-left Map drag must move a landmark right with the direct-grab convention")
	_assert_true(is_equal_approx(director._inspection_pitch_radians, pitch_before), "horizontal Map drag must not change pitch")
	var vertical_landmark := focus + Vector3.UP * 12.0
	var vertical_before := camera.unproject_position(vertical_landmark)
	var vertical_pitch_before := director._inspection_pitch_radians
	_assert_true(director.orbit_inspection(Vector2(0.0, -60.0)), "bottom-to-top Map drag must orbit")
	director._apply_inspection_orbit(true)
	var vertical_after := camera.unproject_position(vertical_landmark)
	_assert_true(
		vertical_after.y < vertical_before.y,
		"bottom-to-top Map drag must move an elevated landmark up with the direct-grab convention"
	)
	_assert_true(
		director._inspection_pitch_radians < vertical_pitch_before,
		"bottom-to-top Map drag must lower the camera pitch instead of applying the reversed sign"
	)
	var solve_count_before := director.safety_solve_count()
	var changed_ticks := 0
	var prior_transform := camera.global_transform
	for _step in range(12):
		director.orbit_inspection(Vector2(-2.0, 1.0))
		await physics_frame
		await process_frame
		if not camera.global_transform.is_equal_approx(prior_transform):
			changed_ticks += 1
		prior_transform = camera.global_transform
	_assert_true(
		director.safety_solve_count() - solve_count_before >= 10,
		"dirty Map camera safety must resolve near the fixed 60 Hz cadence instead of 15 Hz"
	)
	_assert_true(changed_ticks >= 10, "sustained Map drag must update the rendered camera on consecutive ticks")
	_assert_true(cannon.global_transform.is_equal_approx(cannon_transform), "Map inspection must not change committed cannon aim")
	gameplay.queue_free()
	await process_frame
	game_state.persistence_enabled = true
	if not _failed:
		print("Map Inspection passed: direct horizontal/vertical drag, 60 Hz safety targets, and unchanged aim.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
