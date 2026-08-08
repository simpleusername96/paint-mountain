extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")
const LOG_PATH := "user://paint_mountain_phase8_debug_log.json"

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.initialize_from_data(root.get_node("/root/SaveSystem").default_data())
	game_state.select_stage(&"stage_01")
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var manager: ProjectileManager = gameplay.get_node("ProjectileManager")
	var overlay: DebugOverlay = gameplay.get_node("DebugOverlay")
	_assert_true(not overlay.visible, "debug overlay must be disabled by default")
	overlay.set_debug_visible(true)
	_assert_true(overlay.visible, "debug builds must allow F3 overlay visibility")
	_assert_true(_count_buttons(overlay) == 8, "debug overlay must expose the eight current actions")
	_assert_true(_count_texture_rects(overlay) == 4, "debug overlay must expose paint, target, recent, and non-target masks")
	_assert_true(controller.begin_aiming(), "debug log shot must enter aiming")
	var original_aim := AimTuple.canonicalize(
		cannon.yaw_degrees,
		cannon.elevation_degrees,
		cannon.power_percent
	)
	var fractional_power := cannon.power_percent - 0.1 if cannon.power_percent >= 100.0 \
			else cannon.power_percent + 0.1
	var fractional_aim := AimTuple.canonicalize(
		cannon.yaw_degrees,
		cannon.elevation_degrees,
		fractional_power
	)
	_assert_true(original_aim != null and fractional_aim != null,
		"debug bypass proof requires canonical original and fractional aims")
	_assert_true(controller.begin_human_aim_revision(91), "debug bypass proof requires a pending human revision")
	if fractional_aim != null:
		_assert_true(
			controller.set_aim(
				fractional_aim.yaw_degrees,
				fractional_aim.elevation_degrees,
				fractional_aim.power_percent,
				StageController.ActionOrigin.DEBUG
			),
			"debug direct aim must bypass a pending human revision"
		)
		_assert_true(not cannon.human_aim_revision_pending(),
			"debug direct aim must clear the Human-only revision barrier")
	if original_aim != null:
		_assert_true(
			controller.set_aim(
				original_aim.yaw_degrees,
				original_aim.elevation_degrees,
				original_aim.power_percent,
				StageController.ActionOrigin.DEBUG
			),
			"debug shot must restore the generated baseline aim"
		)
	_assert_true(
		controller.request_fire(StageController.ActionOrigin.DEBUG),
		"debug log shot must use the normal Fire admission path"
	)
	_assert_true(
		controller.current_shot_observation() != null \
				and is_equal_approx(
					controller.current_shot_observation().commanded_power,
					original_aim.power_percent if original_aim != null else -1.0
				),
		"debug Fire must launch the restored generated baseline tuple"
	)
	Engine.time_scale = 3.0
	var frame_budget := 60 * 24
	while (manager.active_count() > 0 or controller.sealed_shot_observations().is_empty()) \
			and frame_budget > 0:
		await physics_frame
		frame_budget -= 1
	_assert_true(frame_budget > 0, "debug log shot must settle within the bounded lifetime")
	Engine.time_scale = 1.0
	_assert_true(overlay.export_shot_log(LOG_PATH) == OK, "debug overlay must export a JSON shot log")
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file != null else null
	if file != null:
		file.close()
	_assert_true(parsed is Dictionary, "shot log must be valid JSON")
	if parsed is Dictionary:
		_assert_true(
			parsed.stage_id == "stage_01" \
					and int(parsed.terrain_seed) == StageProgressionData.CANONICAL_TERRAIN_SEED,
			"shot log must contain the canonical stage and fixed terrain seed"
		)
		_assert_true(_has_aim_and_fire(parsed.actions), "shot log must contain ordered aim/fire actions")
		_assert_true(parsed.expected_observations.size() == 1, "shot log must contain the sealed shot outcome")
		if parsed.expected_observations.size() == 1:
			var sealed: Dictionary = parsed.expected_observations[0]
			var source_observation := controller.last_sealed_shot_observation()
			_assert_true(int(sealed.schema_version) == 6, "debug export must contain schema-6 observations")
			_assert_true(
				source_observation != null \
						and int(sealed.final_paint_mask_checksum) \
								== source_observation.final_paint_mask_checksum \
						and source_observation.final_paint_mask_checksum != 0,
				"debug export checksum must match its authoritative sealed observation"
			)
		_assert_true(parsed.has("mechanisms") and parsed.has("exported_state"), "shot log must contain activations snapshot and outcome state")
	await process_frame
	_assert_true("LAST DRAIN TICK" in overlay._metrics.text and "MASK CHECKSUM" in overlay._metrics.text, "debug metrics must expose paint drain and checksum facts")
	if FileAccess.file_exists(LOG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LOG_PATH))
	if not _failed:
		print("Phase 8 debug checks passed: hidden default, 8 actions, Human-revision bypass, drain/checksum metrics, and complete JSON shot log.")
	game_state.persistence_enabled = true
	gameplay.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _count_buttons(node: Node) -> int:
	var result := 1 if node is Button else 0
	for child in node.get_children():
		result += _count_buttons(child)
	return result


func _count_texture_rects(node: Node) -> int:
	var result := 1 if node is TextureRect else 0
	for child in node.get_children():
		result += _count_texture_rects(child)
	return result


func _has_aim_and_fire(actions: Array) -> bool:
	var has_aim := false
	var has_fire := false
	for action in actions:
		has_aim = has_aim or String(action.get("kind", "")) == "aim"
		has_fire = has_fire or String(action.get("kind", "")) == "fire"
	return has_aim and has_fire


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
