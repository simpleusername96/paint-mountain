extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	game_state.unlocked_stages.assign([&"first_descent", &"burst_basin", &"split_ridge"])
	Engine.time_scale = 4.0
	var requested_stage := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			requested_stage = argument.trim_prefix("--stage=")
	var catalog := StageCatalog.all_stages()
	var probe_indices := [0, 9, 19, 29]
	if not requested_stage.is_empty():
		probe_indices = []
		for index in range(catalog.size()):
			if String(catalog[index].stage_id) == requested_stage:
				probe_indices.append(index)
	for stage_index in probe_indices:
		if stage_index < 0 or stage_index >= catalog.size():
			continue
		var stage := catalog[stage_index]
		print("Camera safety fixture started for %s." % stage.stage_id)
		game_state.selected_stage_id = stage.stage_id
		var gameplay := GAMEPLAY_SCENE.instantiate()
		root.add_child(gameplay)
		await physics_frame
		await physics_frame
		var camera: Camera3D = gameplay.get_node("Camera")
		var director: CameraDirector = gameplay.get_node("CameraDirector")
		var terrain: TerrainSurface = gameplay.get_node("TerrainSurface")
		print("Camera safety: briefing fixtures.")
		_assert_true(
			director.current_interaction_mode == CameraDirector.InteractionMode.MAP_INSPECTION,
			"%s briefing must begin in Map Inspection" % stage.stage_id
		)
		for yaw in [-22.0, 0.0, 22.0]:
			for zoom in [-22.0, 28.0]:
				director.set_mode(CameraDirector.Mode.BRIEFING, true)
				director.set_briefing_offsets(yaw, zoom)
				await _sample_camera(camera, director, terrain, 4, "%s briefing %.0f/%.0f" % [stage.stage_id, yaw, zoom])
		for mode in [CameraDirector.Mode.AIMING, CameraDirector.Mode.RESULT]:
			director.set_mode(mode)
			await _sample_camera(camera, director, terrain, 6, "%s bookmark %s" % [stage.stage_id, CameraDirector.Mode.keys()[mode]])
		print("Camera safety: bookmarks complete.")
		for mechanism in gameplay.get_node("Mechanisms").get_children():
			director.set_mode(CameraDirector.Mode.BRIEFING, true)
			_assert_true(director.focus_briefing_target(mechanism.global_position), "mechanism focus must be accepted in briefing")
			await _sample_camera(camera, director, terrain, 6, "%s mechanism %s" % [stage.stage_id, mechanism.name])
		print("Camera safety: mechanism fixtures complete.")
		var center_surface := terrain.world_surface_point(Vector2(stage.terrain_center.x, stage.terrain_center.z))
		var safe_top := director.safe_position_for(center_surface - Vector3.UP * 12.0, center_surface, true)
		_assert_clearance(safe_top, terrain, "%s top fixture" % stage.stage_id)
		var edge_xz := Vector2(stage.terrain_center.x + stage.terrain_size.x * 0.49, stage.terrain_center.z)
		var edge_surface := terrain.world_surface_point(edge_xz)
		var safe_skirt := director.safe_position_for(edge_surface - Vector3.UP * 8.0, edge_surface, true)
		_assert_clearance(safe_skirt, terrain, "%s skirt fixture" % stage.stage_id)
		await _exercise_map_inspection(camera, director, terrain, stage)
		print("Camera safety: map inspection complete.")
		print("Camera safety fixture completed for %s." % stage.stage_id)
		gameplay.queue_free()
		await process_frame
		await process_frame
	Engine.time_scale = 1.0
	game_state.persistence_enabled = true
	if not _failed:
		print("Camera safety checks passed for lifecycle views, map inspection, and terrain fixtures.")
	quit(1 if _failed else 0)


func _exercise_map_inspection(
		camera: Camera3D,
		director: CameraDirector,
		terrain: TerrainSurface,
		stage: StageData
) -> void:
	director.set_mode(CameraDirector.Mode.AIMING, true)
	_assert_true(director.aim_is_locked(), "%s Aiming must begin in Aim Lock" % stage.stage_id)
	_assert_true(
		director.set_interaction_mode(CameraDirector.InteractionMode.MAP_INSPECTION, true),
		"%s must allow Map Inspection during Aiming" % stage.stage_id
	)
	var center := terrain.world_surface_point(Vector2(stage.terrain_center.x, stage.terrain_center.z))
	_assert_true(director.focus_inspection_target(center), "%s terrain focus must be selectable" % stage.stage_id)
	var distance_before := director.inspection_distance()
	_assert_true(director.orbit_inspection(Vector2(80.0, -30.0)), "%s inspection orbit must accept drag" % stage.stage_id)
	_assert_true(director.zoom_inspection(1.0), "%s inspection zoom must accept wheel input" % stage.stage_id)
	_assert_true(director.inspection_distance() < distance_before, "%s wheel up must zoom closer" % stage.stage_id)
	await _sample_camera(camera, director, terrain, 8, "%s map inspection" % stage.stage_id)
	_assert_true(
		director.set_interaction_mode(CameraDirector.InteractionMode.AIM_LOCKED, true),
		"%s must return to Aim Lock" % stage.stage_id
	)
	await _sample_camera(camera, director, terrain, 2, "%s aim lock return" % stage.stage_id)


func _sample_camera(camera: Camera3D, director: CameraDirector, terrain: TerrainSurface, ticks: int, label: String) -> void:
	for _tick in range(ticks):
		await physics_frame
		_assert_clearance(camera.global_position, terrain, label)
		var focus := director.camera_focus_position()
		var surface_focus := terrain.contains_world_xz(Vector2(focus.x, focus.z)) \
				and focus.distance_to(terrain.world_surface_point(Vector2(focus.x, focus.z))) <= 0.3
		_assert_true(director.view_ray_is_clear(camera.global_position, focus, surface_focus), "%s camera ray must not cross terrain" % label)


func _assert_clearance(position: Vector3, terrain: TerrainSurface, label: String) -> void:
	if not terrain.contains_world_xz(Vector2(position.x, position.z)):
		return
	var surface_y := terrain.world_surface_point(Vector2(position.x, position.z)).y
	_assert_true(position.y - surface_y >= 1.5 - 0.001, "%s camera clearance is %.3fm" % [label, position.y - surface_y])


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
