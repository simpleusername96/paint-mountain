extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	Engine.time_scale = 3.0
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.select_stage(&"first_descent")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await physics_frame
	await physics_frame
	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	_assert(controller.begin_aiming(), "rapid-fire contract requires an aiming board")
	var first := controller.request_fire()
	var second := controller.request_fire()
	var third := controller.request_fire()
	_assert(first and second, "two fire commands must be accepted without waiting for settlement")
	_assert(not third, "third fire must be rejected only at the two-family capacity")
	_assert(controller.shots_remaining == 2, "each accepted family must consume one payload")
	_assert(manager.active_root_count() <= 2, "active root family count must stay bounded")
	var budget := 60 * 30
	while manager.active_count() > 0 and budget > 0:
		await physics_frame
		budget -= 1
	_assert(budget > 0, "rapid-fire families must settle inside the bounded physics window")
	while controller.sealed_shot_observations().size() < 2 and budget > 0:
		await physics_frame
		budget -= 1
	var sealed := controller.sealed_shot_observations()
	_assert(sealed.size() == 2, "each accepted family must seal its own observation")
	if sealed.size() == 2:
		_assert(sealed[0].shot_id == 1 and sealed[1].shot_id == 2, "sealed family observations must retain ordered shot IDs")
	if not _failed:
		print("rapid_fire_contract_test passed: two immediate families accepted, third rejected at capacity, and both settled")
	Engine.time_scale = 1.0
	gameplay.queue_free()
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
