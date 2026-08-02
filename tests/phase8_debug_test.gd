extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const LOG_PATH := "user://paint_mountain_phase8_debug_log.json"

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	root.get_node("/root/GameState").persistence_enabled = false
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller: StageController = gameplay.get_node("StageController")
	var cannon: CannonController = gameplay.get_node("Cannon")
	var overlay: DebugOverlay = gameplay.get_node("DebugOverlay")
	var paint: PaintSystem = gameplay.get_node("PaintSystem")
	_assert_true(not overlay.visible, "debug overlay must be disabled by default")
	overlay.set_debug_visible(true)
	_assert_true(overlay.visible, "debug builds must allow F3 overlay visibility")
	_assert_true(_count_buttons(overlay) == 10, "debug overlay must expose all ten required actions")
	_assert_true(_count_texture_rects(overlay) == 4, "debug overlay must expose paint, eligible, recent, and excluded masks")
	_assert_true(controller.begin_aiming(), "debug log shot must enter aiming")
	cannon.set_aim(0.0, 38.0, 68.0)
	_assert_true(controller.request_fire(), "debug log shot must use the normal fire path")
	Engine.time_scale = 3.0
	var frame_budget := 60 * 24
	while controller.current_state != StageController.State.AIMING and frame_budget > 0:
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
		_assert_true(parsed.stage_id == "first_descent" and int(parsed.physics_seed) > 0, "shot log must contain stage and seed")
		_assert_true(parsed.shots.size() == 1 and parsed.shots[0].has("yaw") and parsed.shots[0].has("elevation") and parsed.shots[0].has("power"), "shot log must contain ordered aim inputs")
		_assert_true(_has_event(parsed.events, "shot_settled"), "shot log must contain coverage gain and settlement")
		_assert_true(parsed.has("mechanisms") and parsed.has("exported_state"), "shot log must contain activations snapshot and outcome state")
	var flow_before := paint.flow_simulation_enabled
	paint.flow_simulation_enabled = not flow_before
	_assert_true(paint.flow_simulation_enabled != flow_before, "paint-flow debug toggle must be independent of paint authority")
	paint.flow_simulation_enabled = flow_before
	if FileAccess.file_exists(LOG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LOG_PATH))
	if not _failed:
		print("Phase 8 debug checks passed: hidden default, 10 actions, live metrics, and complete JSON shot log.")
	root.get_node("/root/GameState").persistence_enabled = true
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


func _has_event(events: Array, event_name: String) -> bool:
	for event in events:
		if event.get("name", "") == event_name:
			return event.payload.has("gain") and event.payload.has("total")
	return false


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
