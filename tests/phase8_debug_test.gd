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
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	_assert_true(not overlay.visible, "debug overlay must be disabled by default")
	overlay.set_debug_visible(true)
	_assert_true(overlay.visible, "debug builds must allow F3 overlay visibility")
	_assert_true(_count_buttons(overlay) == 9, "debug overlay must expose the nine current actions")
	_assert_true(_count_texture_rects(overlay) == 4, "debug overlay must expose paint, target, recent, and non-target masks")
	_assert_true(controller.begin_aiming(), "debug log shot must enter aiming")
	# The generated default aim is already admitted by the refreshed trajectory;
	# changing it here would intentionally invalidate Fire until the next frame.
	_assert_true(
		controller.request_fire(StageController.ActionOrigin.DEBUG),
		"debug log shot must use the normal Fire admission path"
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
			_assert_true(int(sealed.schema_version) == 6, "debug export must contain schema-6 observations")
			_assert_true(int(sealed.final_paint_mask_checksum) == paint.paint_mask_checksum(), "debug export checksum must match PaintSystem")
		_assert_true(parsed.has("mechanisms") and parsed.has("exported_state"), "shot log must contain activations snapshot and outcome state")
	await process_frame
	_assert_true("LAST DRAIN TICK" in overlay._metrics.text and "MASK CHECKSUM" in overlay._metrics.text, "debug metrics must expose paint drain and checksum facts")
	if FileAccess.file_exists(LOG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LOG_PATH))
	if not _failed:
		print("Phase 8 debug checks passed: hidden default, 9 actions, drain/checksum metrics, and complete JSON shot log.")
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
