extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const FIXTURE_PATH := "user://paint_mountain_phase8_replay.json"

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mode := "replay"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
	if mode == "cleanup":
		var absolute_path := ProjectSettings.globalize_path(FIXTURE_PATH)
		if FileAccess.file_exists(absolute_path):
			DirAccess.remove_absolute(absolute_path)
		print("Phase 8 replay fixture cleaned.")
		quit(0)
		return
	root.get_node("/root/GameState").persistence_enabled = false
	root.get_node("/root/GameState").initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var projectiles: ProjectileManager = gameplay.get_node("ProjectileManager")
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	var recorder: ReplayRecorder = gameplay.get_node("ReplayRecorder")
	var presentation: ReplayPresentationController = gameplay.get_node("ReplayPresentationController")
	var first_impact := {"set": false, "position": Vector3.ZERO}
	projectiles.projectile_contact_reported.connect(func(_projectile: PaintProjectile, contact: ProjectileContact) -> void:
		if not first_impact.set:
			first_impact.set = true
			first_impact.position = contact.world_position
	)
	if mode == "record":
		controller.begin_aiming()
		controller.set_aim(0.0, 38.0, 68.0)
		controller.request_fire()
		await _wait_for_settlement(controller)
		var observation := controller.last_sealed_shot_observation()
		var fixture := {
			"attempt": recorder.export_attempt(),
			"coverage": observation.coverage_after,
			"impact": [observation.first_contact.world_position.x, observation.first_contact.world_position.y, observation.first_contact.world_position.z],
			"mechanism_kinds": Array(observation.mechanism_activation_kinds),
			"result_state": controller.current_state,
		}
		var file := FileAccess.open(FIXTURE_PATH, FileAccess.WRITE)
		if file == null:
			_failed = true
		else:
			file.store_string(JSON.stringify(fixture, "\t"))
			file.close()
		print("Phase 8 replay baseline recorded at %.4f%%." % paint.coverage_percent())
	else:
		var file := FileAccess.open(FIXTURE_PATH, FileAccess.READ)
		var fixture = JSON.parse_string(file.get_as_text()) if file != null else null
		if file != null:
			file.close()
		if not fixture is Dictionary or not recorder.load_attempt(fixture.attempt):
			_failed = true
		else:
			gameplay._start_replay()
			var start_budget := 120
			while controller.current_state == StageController.State.AIMING and start_budget > 0:
				await physics_frame
				start_budget -= 1
			_assert_true(start_budget > 0, "replay must dispatch its recorded fire action")
			await _wait_for_settlement(controller)
			var replay_observation := controller.last_sealed_shot_observation()
			if replay_observation == null:
				_failed = true
				push_error("fresh-process replay must produce a sealed observation")
				Engine.time_scale = 1.0
				gameplay.queue_free()
				await process_frame
				quit(1)
				return
			var expected_impact := Vector3(float(fixture.impact[0]), float(fixture.impact[1]), float(fixture.impact[2]))
			var impact_delta: float = replay_observation.first_contact.world_position.distance_to(expected_impact)
			var coverage_delta: float = absf(replay_observation.coverage_after - float(fixture.coverage))
			_assert_true(first_impact.set and impact_delta <= 0.5, "fresh-process replay first impact must stay within 0.5m")
			_assert_true(coverage_delta <= 0.1, "fresh-process replay coverage must stay within 0.1 percentage points")
			_assert_true(Array(replay_observation.mechanism_activation_kinds) == fixture.mechanism_kinds, "fresh-process replay mechanism order must match exactly")
			_assert_true(controller.current_state == int(fixture.result_state), "fresh-process replay final state must match")
			_assert_true(presentation.active, "replay input lock must remain active until explicit exit")
			print("Phase 8 replay passed across a fresh process: impact Δ %.5fm, coverage Δ %.5f%%." % [impact_delta, coverage_delta])
	Engine.time_scale = 1.0
	root.get_node("/root/GameState").persistence_enabled = true
	gameplay.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _wait_for_settlement(controller: StageController) -> void:
	var frame_budget := 60 * 24
	while controller.current_state not in [StageController.State.AIMING, StageController.State.STAGE_CLEAR, StageController.State.STAGE_FAILED] and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	_assert_true(frame_budget > 0, "replay shot must settle inside its bounded lifetime")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
