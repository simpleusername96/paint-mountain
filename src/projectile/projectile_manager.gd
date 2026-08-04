class_name ProjectileManager
extends Node3D

signal projectile_spawned(projectile: PaintProjectile)
signal projectile_contact_reported(projectile: PaintProjectile, contact: ProjectileContact)
signal radial_paint_mark_ready(command: RadialPaintMark)
signal surface_paint_sweep_ready(command: SurfacePaintSweep)
signal transient_splash_requested(projectile: PaintProjectile, contact: ProjectileContact)
signal projectile_stopped(projectile: PaintProjectile, reason: StringName)
signal all_projectiles_settled
signal shot_family_started(shot_id: int, root_projectile: PaintProjectile)
signal shot_family_finished(shot_id: int)
signal activity_changed(active_shot_ids: PackedInt64Array, active_projectiles: int)

const MAXIMUM_ACTIVE_PROJECTILES := 8
const COMMAND_CANONICALIZATION_PRIORITY := 900
const DEFAULT_PAINT_SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")

var stage_bounds := AABB(Vector3(-140.0, -30.0, -210.0), Vector3(280.0, 210.0, 260.0))
var _terrain_surface: TerrainSurface
var _paint_surface_tuning: PaintSurfaceTuning = DEFAULT_PAINT_SURFACE_TUNING
var _active: Array[PaintProjectile] = []
var _settlement_check_queued := false
var _pending_intents: Array[Dictionary] = []
var _next_spawn_ordinal: int = 0
var _next_shot_id: int = 1
var _next_sequence_by_ordinal: Dictionary = {}


func _init() -> void:
	process_physics_priority = COMMAND_CANONICALIZATION_PRIORITY


func configure_terrain(
		terrain_surface: TerrainSurface,
		paint_surface_tuning: PaintSurfaceTuning = DEFAULT_PAINT_SURFACE_TUNING
) -> void:
	assert(terrain_surface != null, "ProjectileManager requires TerrainSurface.")
	assert(paint_surface_tuning != null and paint_surface_tuning.is_valid(), "ProjectileManager requires valid paint-surface tuning.")
	_terrain_surface = terrain_surface
	_paint_surface_tuning = paint_surface_tuning


func spawn_projectile(
		projectile_data: ProjectileData,
		origin: Vector3,
		velocity: Vector3,
		split_generation: int = 0,
		requested_shot_id: int = 0
) -> PaintProjectile:
	_prune_invalid()
	if _active.size() >= MAXIMUM_ACTIVE_PROJECTILES or _terrain_surface == null:
		return null
	# Spawn ordinals stay monotonic for the complete attempt. This is important
	# when a new root is fired while the previous family's paint commands are
	# still queued: command identity must never collide across families.
	var assigned_ordinal := _next_spawn_ordinal
	_next_spawn_ordinal += 1
	var assigned_shot_id := requested_shot_id
	if split_generation == 0:
		if assigned_shot_id <= 0:
			assigned_shot_id = _next_shot_id
			_next_shot_id += 1
	else:
		if assigned_shot_id <= 0:
			return null
	var projectile := PaintProjectile.new()
	projectile.name = "PaintProjectile%02d" % (assigned_ordinal + 1)
	projectile.configure(
		projectile_data,
		stage_bounds,
		_terrain_surface,
		velocity,
		split_generation,
		_paint_surface_tuning,
		assigned_ordinal,
		assigned_shot_id
	)
	projectile.contact_reported.connect(_on_contact_reported)
	projectile.radial_paint_mark_intent_requested.connect(_on_radial_paint_mark_intent)
	projectile.surface_paint_sweep_intent_requested.connect(_on_surface_paint_sweep_intent)
	projectile.transient_splash_requested.connect(_on_transient_splash_requested)
	projectile.stopped.connect(_on_projectile_stopped)
	projectile.position = to_local(origin)
	projectile.linear_velocity = velocity
	add_child(projectile)
	_active.append(projectile)
	projectile_spawned.emit(projectile)
	if split_generation == 0:
		shot_family_started.emit(assigned_shot_id, projectile)
	_emit_activity_changed()
	return projectile


func active_count() -> int:
	_prune_invalid()
	return _active.size()


func active_projectiles() -> Array[PaintProjectile]:
	_prune_invalid()
	return _active.duplicate()


func pending_intent_count() -> int:
	return _pending_intents.size()


func active_shot_ids() -> PackedInt64Array:
	_prune_invalid()
	var ids := PackedInt64Array()
	for projectile in _active:
		if projectile.shot_id > 0 and not ids.has(projectile.shot_id):
			ids.append(projectile.shot_id)
	ids.sort()
	return ids


func active_root_count() -> int:
	return active_shot_ids().size()


func root_capacity_available(maximum_roots: int = 2) -> bool:
	return active_root_count() < maxi(1, maximum_roots)


func submit_radial_paint_intent(intent: RadialPaintMark) -> bool:
	if intent == null or not intent.is_intent_valid():
		return false
	_pending_intents.append({"intent": intent})
	return true


func submit_surface_paint_intent(intent: SurfacePaintSweep) -> bool:
	if intent == null or not intent.is_intent_valid():
		return false
	_pending_intents.append({"intent": intent})
	return true


func cleanup() -> void:
	_settlement_check_queued = false
	_pending_intents.clear()
	_begin_shot_ordering()
	_next_shot_id = 1
	for projectile in _active:
		if is_instance_valid(projectile):
			projectile.queue_free()
	_active.clear()
	_emit_activity_changed()
	all_projectiles_settled.emit()


func _physics_process(_delta: float) -> void:
	_canonicalize_completed_ticks(Engine.get_physics_frames())


func _begin_shot_ordering() -> void:
	_next_spawn_ordinal = 0
	_next_sequence_by_ordinal.clear()


func _on_contact_reported(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	projectile_contact_reported.emit(projectile, contact)


func _on_radial_paint_mark_intent(
		_projectile: PaintProjectile,
		intent: RadialPaintMark
) -> void:
	submit_radial_paint_intent(intent)


func _on_surface_paint_sweep_intent(
		_projectile: PaintProjectile,
		intent: SurfacePaintSweep
) -> void:
	submit_surface_paint_intent(intent)


func _canonicalize_completed_ticks(current_physics_tick: int) -> void:
	if _pending_intents.is_empty():
		return
	var ready: Array[Dictionary] = []
	var waiting: Array[Dictionary] = []
	for entry in _pending_intents:
		var intent: Variant = entry.intent
		if int(intent.physics_tick) < current_physics_tick:
			ready.append(entry)
		else:
			waiting.append(entry)
	_pending_intents = waiting
	ready.sort_custom(_intent_entry_less)
	for entry in ready:
		var intent: Variant = entry.intent
		var ordinal := int(intent.spawn_ordinal)
		var sequence := int(_next_sequence_by_ordinal.get(ordinal, 0))
		_next_sequence_by_ordinal[ordinal] = sequence + 1
		if intent is RadialPaintMark:
			var radial := (intent as RadialPaintMark).with_sequence(sequence)
			assert(radial.is_valid(), "Canonicalized radial command must be valid.")
			radial_paint_mark_ready.emit(radial)
		elif intent is SurfacePaintSweep:
			var sweep := (intent as SurfacePaintSweep).with_sequence(sequence)
			assert(sweep.is_valid(), "Canonicalized sweep command must be valid.")
			surface_paint_sweep_ready.emit(sweep)


func _intent_entry_less(a: Dictionary, b: Dictionary) -> bool:
	var a_key: Array = a.intent.queue_sort_key()
	var b_key: Array = b.intent.queue_sort_key()
	for index in range(mini(a_key.size(), b_key.size())):
		if a_key[index] == b_key[index]:
			continue
		return a_key[index] < b_key[index]
	return a_key.size() < b_key.size()


func _on_transient_splash_requested(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	transient_splash_requested.emit(projectile, contact)


func _on_projectile_stopped(projectile: PaintProjectile, reason: StringName) -> void:
	_active.erase(projectile)
	projectile_stopped.emit(projectile, reason)
	var shot_id := projectile.shot_id
	if shot_id > 0 and not _has_active_shot_id(shot_id):
		shot_family_finished.emit(shot_id)
	_emit_activity_changed()
	if _active.is_empty() and not _settlement_check_queued:
		_settlement_check_queued = true
		_emit_settled_if_still_empty.call_deferred()


func _emit_settled_if_still_empty() -> void:
	if not _settlement_check_queued:
		return
	_settlement_check_queued = false
	_prune_invalid()
	if _active.is_empty():
		all_projectiles_settled.emit()
	_emit_activity_changed()


func _prune_invalid() -> void:
	for index in range(_active.size() - 1, -1, -1):
		if not is_instance_valid(_active[index]):
			_active.remove_at(index)


func _has_active_shot_id(shot_id: int) -> bool:
	for projectile in _active:
		if is_instance_valid(projectile) and projectile.shot_id == shot_id:
			return true
	return false


func _emit_activity_changed() -> void:
	activity_changed.emit(active_shot_ids(), _active.size())
