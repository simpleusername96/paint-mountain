extends SceneTree

const PROJECTILE_DATA: ProjectileData = preload("res://resources/projectiles/basic_paintball.tres")
const WIND_PROFILE: WindProfile = preload("res://resources/wind/standard_wind.tres")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var terrain := TerrainSurface.new()
	var manager := ProjectileManager.new()
	root.add_child(manager)
	manager.configure_terrain(terrain)
	var projectile := manager.spawn_projectile(
		PROJECTILE_DATA,
		Vector3.ZERO,
		Vector3.FORWARD
	)
	_assert(projectile != null, "wind fixture must spawn one projectile")
	if projectile == null:
		quit(1)
		return
	projectile.configure_wind(null, WIND_PROFILE)
	projectile._has_touched_playable_top = true
	projectile._last_valid_top_contact = ProjectileContact.new(
		Vector3.ZERO,
		Vector3.UP
	)
	projectile.sleeping = true
	projectile._set_motion_state(PaintProjectile.MotionState.RESTING_ON_TERRAIN)

	var weak := WindSnapshot.new(
		0, Vector3.RIGHT * 2.0, Vector3.RIGHT * 3.0,
		0.3, 0.4, 20.0, 0.0, &"wind-test"
	)
	weak.strong = false
	weak.strong_episode_id = 1
	_assert(not projectile.wake_for_strong_wind(weak), "weak wind must not explicitly wake a resident")

	var strong := WindSnapshot.new(
		60, Vector3.RIGHT * 5.0, Vector3.FORWARD * 4.0,
		0.9, 0.8, 19.0, 0.0, &"wind-test"
	)
	strong.strong = true
	strong.strong_episode_id = 1
	_assert(projectile.wake_for_strong_wind(strong), "a strong episode must wake an eligible resident")
	_assert(not projectile.sleeping, "strong wake must release engine sleep")
	_assert(
		projectile.motion_state == PaintProjectile.MotionState.MOVING_ON_TERRAIN,
		"strong wake must return the same body to terrain motion"
	)

	projectile.sleeping = true
	projectile._set_motion_state(PaintProjectile.MotionState.RESTING_ON_TERRAIN)
	_assert(not projectile.wake_for_strong_wind(strong), "one strong episode must issue at most one wake impulse")
	strong.strong_episode_id = 2
	_assert(projectile.wake_for_strong_wind(strong), "a later strong episode may wake the resident again")

	manager.cleanup()
	await process_frame
	manager.queue_free()
	await process_frame
	terrain.free()
	if not _failed:
		print("Wind projectile checks passed: weak rest, one-shot strong wake, and later reawakening.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Wind projectile check failed: %s" % message)
