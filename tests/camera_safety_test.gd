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
	for stage in StageCatalog.all_stages():
		if not requested_stage.is_empty() and String(stage.stage_id) != requested_stage:
			continue
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
		for yaw in [-22.0, 0.0, 22.0]:
			for zoom in [-22.0, 28.0]:
				director.set_mode(CameraDirector.Mode.BRIEFING, true)
				director.set_briefing_offsets(yaw, zoom)
				await _sample_camera(camera, director, terrain, 4, "%s briefing %.0f/%.0f" % [stage.stage_id, yaw, zoom])
		for mode in [CameraDirector.Mode.AIMING, CameraDirector.Mode.WIDE, CameraDirector.Mode.RESULT, CameraDirector.Mode.CANNON]:
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
		await _exercise_split_follow(gameplay, camera, director, terrain, stage)
		print("Camera safety: split follow complete.")
		print("Camera safety fixture completed for %s." % stage.stage_id)
		gameplay.queue_free()
		await process_frame
		await process_frame
	Engine.time_scale = 1.0
	game_state.persistence_enabled = true
	if not _failed:
		print("Camera safety checks passed for all bookmarks, mechanisms, terrain fixtures, and split framing.")
	quit(1 if _failed else 0)


func _exercise_split_follow(
		gameplay: Node3D,
		camera: Camera3D,
		director: CameraDirector,
		terrain: TerrainSurface,
		stage: StageData
) -> void:
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var positions := [
		stage.terrain_center + Vector3(-78.0, 88.0, 5.0),
		stage.terrain_center + Vector3(78.0, 84.0, 5.0),
		stage.terrain_center + Vector3(0.0, 92.0, -48.0),
	]
	var projectiles: Array[PaintProjectile] = []
	for index in range(3):
		var projectile := manager.spawn_projectile(
			cannon.projectile_data,
			positions[index],
			Vector3(2.0 + index, 0.0, -2.0),
			1
		)
		projectile.freeze = true
		projectile.global_position = positions[index]
		projectiles.append(projectile)
	director.set_mode(CameraDirector.Mode.FOLLOW, true)
	await _sample_camera(camera, director, terrain, 5, "%s split spread" % stage.stage_id)
	_assert_true(director.follow_wide_is_latched(), "%s split spread must latch wide framing" % stage.stage_id)
	for index in range(projectiles.size()):
		projectiles[index].global_position = stage.terrain_center + Vector3(float(index - 1) * 5.0, 88.0, 0.0)
	await _sample_camera(camera, director, terrain, 5, "%s split regroup" % stage.stage_id)
	_assert_true(not director.follow_wide_is_latched(), "%s regrouped children must release below the hysteresis threshold" % stage.stage_id)
	manager.cleanup()


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
