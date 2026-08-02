extends SceneTree

const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const BURST_DATA := preload("res://resources/mechanisms/burst_node.tres")
const SPLITTER_DATA := preload("res://resources/mechanisms/splitter_node.tres")
const BUMPER_DATA := preload("res://resources/mechanisms/bumper_node.tres")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var test_root := Node3D.new()
	root.add_child(test_root)
	var manager := ProjectileManager.new()
	test_root.add_child(manager)
	var paint_system := PaintSystem.new()
	test_root.add_child(paint_system)
	paint_system.configure(
		0,
		Rect2(Vector2(-90.0, -172.0), Vector2(180.0, 120.0)),
		-2.0,
		null
	)

	var summit_y := -2.0 + TerrainMeshFactory.height_at(0, 0.0, 0.0)
	var burst := BurstNode.new()
	burst.data = BURST_DATA
	burst.position = Vector3(0.0, summit_y + 0.8, -112.0)
	burst.configure(manager, paint_system)
	test_root.add_child(burst)
	var burst_projectile := manager.spawn_projectile(PROJECTILE_DATA, burst.position, Vector3.ZERO)
	_assert_true(burst.activate(burst_projectile), "charged Burst must accept its first physical projectile")
	var burst_coverage := paint_system.coverage_percent()
	_assert_true(burst_coverage > 0.0, "Burst must paint the authoritative mask")
	_assert_true(not burst.activate(burst_projectile), "one projectile must not duplicate a Burst activation")
	_assert_true(burst.is_spent(), "one-charge Burst must expose its spent state")
	burst.reset_state()
	_assert_true(not burst.is_spent() and burst.remaining_charges == 1, "restart contract must restore Burst charge")
	manager.cleanup()
	paint_system.clear()
	manager.spawn_projectile(PROJECTILE_DATA, burst.position + Vector3(0.0, 0.0, 6.0), Vector3(0.0, 0.0, -24.0))
	for _frame in range(40):
		if burst.is_spent():
			break
		await physics_frame
	_assert_true(burst.is_spent(), "Burst must activate from a physical Area collision")
	_assert_true(paint_system.coverage_percent() > 0.0, "physical Burst collision must paint the authoritative mask")
	manager.cleanup()

	var splitter := SplitterNode.new()
	splitter.data = SPLITTER_DATA
	splitter.configure(manager, paint_system)
	test_root.add_child(splitter)
	var parent := manager.spawn_projectile(PROJECTILE_DATA, Vector3(0.0, 8.0, 0.0), Vector3(0.0, 4.0, -28.0))
	var parent_payload := parent.remaining_payload
	_assert_true(splitter.activate(parent), "eligible parent must activate Splitter")
	var children := manager.active_projectiles()
	_assert_true(children.size() == 3, "Splitter must consume one parent and create exactly three children")
	var total_child_payload := 0.0
	for child in children:
		total_child_payload += child.remaining_payload
		_assert_true(child.split_generation == 1, "every Splitter child must be marked generation one")
		_assert_true(not splitter.can_activate(child), "generation-one children must not split recursively")
	_assert_true(total_child_payload <= parent_payload * 0.9 + 0.001, "Splitter must preserve the ten-percent payload loss")
	_assert_true(manager.active_count() <= ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES, "Splitter must obey the eight-ball cap")
	manager.cleanup()

	var bumper := BumperNode.new()
	bumper.data = BUMPER_DATA
	bumper.configure(manager, paint_system)
	test_root.add_child(bumper)
	var bumper_projectile := manager.spawn_projectile(PROJECTILE_DATA, Vector3(0.0, 8.0, 0.0), Vector3(0.0, 0.0, -4.0))
	var velocity_before := bumper_projectile.linear_velocity
	_assert_true(bumper.activate(bumper_projectile), "ready Bumper must accept a projectile")
	await physics_frame
	_assert_true(bumper_projectile.linear_velocity.distance_to(velocity_before) > 0.1, "Bumper must redirect without consuming the projectile")
	_assert_true(manager.active_count() == 1, "Bumper must not consume or duplicate the ball")
	_assert_true(not bumper.activate(bumper_projectile), "Bumper cooldown and projectile guard must reject immediate duplicates")
	bumper.reset_state()
	_assert_true(is_zero_approx(bumper.cooldown_remaining), "reset must clear Bumper cooldown")

	if not _failed:
		print(
			"Phase 5 mechanism checks passed: Burst %.4f%%, Splitter payload %.1f/%.1f, Bumper retained one ball." % [
				burst_coverage,
				total_child_payload,
				parent_payload,
			]
		)
	manager.cleanup()
	test_root.queue_free()
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
