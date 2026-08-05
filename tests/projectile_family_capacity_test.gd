extends SceneTree

const PROJECTILE_DATA: ProjectileData = preload("res://resources/projectiles/basic_paintball.tres")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var terrain := TerrainSurface.new()
	var manager := ProjectileManager.new()
	root.add_child(manager)
	manager.configure_terrain(terrain)

	var first := manager.spawn_projectile(PROJECTILE_DATA, Vector3.ZERO, Vector3.FORWARD)
	var second := manager.spawn_projectile(PROJECTILE_DATA, Vector3.ZERO, Vector3.FORWARD)
	_assert(first != null and second != null, "two root families must be admitted")
	_assert(manager.active_root_count() == 2, "two moving roots must occupy both initial-flight slots")
	_assert(not manager.root_capacity_available(2), "a third root must wait while both families are in initial flight")

	first._set_motion_state(PaintProjectile.MotionState.RESTING_ON_TERRAIN)
	_assert(manager.active_count() == 2, "resting must keep the projectile resident")
	_assert(manager.active_root_count() == 1, "first rest must release only that family's Fire slot")
	first._set_motion_state(PaintProjectile.MotionState.MOVING_ON_TERRAIN)
	_assert(manager.active_root_count() == 1, "reawakening a resident must not reclaim an initial-flight slot")

	var third := manager.spawn_projectile(PROJECTILE_DATA, Vector3.ZERO, Vector3.FORWARD)
	_assert(third != null and manager.active_root_count() == 2, "a released slot must admit another root")

	var child := manager.spawn_projectile(
		PROJECTILE_DATA,
		Vector3.ZERO,
		Vector3.FORWARD,
		1,
		second.shot_id
	)
	_assert(child != null, "a split child must retain its root family identity")
	second._set_motion_state(PaintProjectile.MotionState.RESTING_ON_TERRAIN)
	_assert(manager.active_root_count() == 2, "one moving child must keep its family in initial flight")
	child._set_motion_state(PaintProjectile.MotionState.RESTING_ON_TERRAIN)
	_assert(manager.active_root_count() == 1, "the family slot must release after all first-flight members rest")

	_assert(
		ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES == 21,
		"the resident-body cap must cover seven roots with one three-way split generation"
	)
	manager.cleanup()
	await process_frame
	manager.queue_free()
	await process_frame
	terrain.free()
	if not _failed:
		print("Projectile family capacity checks passed: residents and reawakening stay outside initial-flight Fire slots.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Projectile family capacity check failed: %s" % message)
