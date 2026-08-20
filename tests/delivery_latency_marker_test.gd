extends SceneTree

const BAKED_GAMEPLAY_FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")
const TERRAIN_FIXTURE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const TERRAIN_FACTORY := preload("res://tests/support/terrain_test_fixture_factory.gd")
const PROJECTILE_DATA := preload("res://resources/projectiles/basic_paintball.tres")
const PAINT_SHADER := preload("res://src/paint/terrain_paint.gdshader")
const SURFACE_TUNING := preload("res://resources/paint/default_paint_surface_tuning.tres")

var _failed := false
var _markers: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	RuntimeDeliveryTelemetry.set_test_observer(_capture_marker)
	await _check_cold_and_warm_root_markers()
	await _check_cold_special_root(&"stage_02", BallKind.Value.IMPACT_BURST, &"impact_burst")
	await _check_cold_special_root(&"stage_03", BallKind.Value.APEX_SPLIT, &"apex_split")
	await _check_paint_publication_markers()
	await _check_apex_replacement_markers()
	RuntimeDeliveryTelemetry.clear_test_observer()
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = true
	if not _failed:
		print("delivery_latency_marker_test passed: per-trace root, paint, render, and split markers are ordered and correlated.")
	quit(1 if _failed else 0)


func _check_cold_and_warm_root_markers() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	game_state.select_stage(&"stage_01")
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(&"stage_01")
	_assert(gameplay != null, "root marker fixture requires the baked Stage 01 layout")
	if gameplay == null:
		return
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	_assert(controller.begin_aiming(), "root marker fixture must enter Aiming")
	await process_frame

	var first_start := _markers.size()
	_assert(controller.request_fire(), "cold Standard fire must be accepted")
	await process_frame
	await process_frame
	var first_trace := _first_trace_id_since(first_start)
	_assert(first_trace > 0, "cold Standard fire must receive a trace ID")
	_assert_root_delivery_order(first_trace, "cold Standard")

	var active := manager.active_projectiles()
	_assert(not active.is_empty(), "cold Standard root must remain available for effect presentation")
	if not active.is_empty():
		var projectile := active[0] as PaintProjectile
		gameplay._on_ball_effect_triggered(
			projectile,
			&"impact_burst",
			projectile.global_position
		)
		await process_frame
		await process_frame
		_assert(
			_count_marker(first_trace, &"effect_requested", &"impact_burst") == 1 \
					and _count_marker(first_trace, &"effect_frame_presented", &"impact_burst") == 1,
			"a requested special-ball effect must publish one post-frame presentation marker"
		)

	_assert(controller.restart(false), "warm-shot fixture must restart into Aiming")
	await process_frame
	await process_frame
	var warm_start := _markers.size()
	_assert(controller.request_fire(), "warm Standard fire must be accepted")
	await process_frame
	await process_frame
	var warm_trace := _first_trace_id_since(warm_start)
	_assert(warm_trace > first_trace, "warm Standard fire must use a distinct increasing trace ID")
	_assert_root_delivery_order(warm_trace, "warm Standard")
	gameplay.queue_free()
	await process_frame


func _check_cold_special_root(
		stage_id: StringName,
		ball_kind: int,
		effect_id: StringName
) -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.select_stage(stage_id)
	var gameplay := BAKED_GAMEPLAY_FIXTURE.instantiate(stage_id)
	_assert(gameplay != null, "%s marker fixture requires its baked layout" % stage_id)
	if gameplay == null:
		return
	root.add_child(gameplay)
	await physics_frame
	await process_frame
	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var special_index := -1
	for index in range(controller._deal.size()):
		var token := controller._deal[index] as BallToken
		if token != null and token.kind == ball_kind:
			special_index = index
			break
	_assert(special_index >= 0, "%s deal must contain the requested special ball" % stage_id)
	_assert(controller.begin_aiming(), "%s special fixture must enter Aiming" % stage_id)
	await process_frame
	if special_index >= 0:
		controller._queue_cursor = special_index
		controller.shots_remaining = controller._deal.size() - special_index
	var marker_start := _markers.size()
	_assert(controller.request_fire(), "%s cold special fire must be accepted" % stage_id)
	await process_frame
	await process_frame
	var trace_id := _first_trace_id_since(marker_start)
	_assert_root_delivery_order(trace_id, "%s cold special" % stage_id)
	var events := _markers_for_trace(trace_id)
	for marker in [&"root_construction_started", &"root_admitted", &"fire_accepted"]:
		var marker_index := _marker_index(events, marker)
		_assert(
			marker_index >= 0 and int(events[marker_index].get("ball_kind", -1)) == ball_kind,
			"%s marker %s must preserve its special-ball kind" % [stage_id, marker]
		)
	var active := manager.active_projectiles()
	if not active.is_empty():
		var projectile := active[0] as PaintProjectile
		gameplay._on_ball_effect_triggered(projectile, effect_id, projectile.global_position)
		await process_frame
		await process_frame
		_assert(
			_count_marker(trace_id, &"effect_requested", effect_id) == 1 \
					and _count_marker(trace_id, &"effect_frame_presented", effect_id) == 1,
			"%s special effect must expose one request and one presented frame" % stage_id
		)
	gameplay.queue_free()
	await process_frame


func _check_paint_publication_markers() -> void:
	var layout := TERRAIN_FACTORY.build_layout(TERRAIN_FACTORY.Kind.FLAT)
	var target_mask := PackedByteArray()
	target_mask.resize(PaintSystem.MASK_SIZE * PaintSystem.MASK_SIZE)
	target_mask.fill(255)
	_assert(
		TERRAIN_FACTORY.install_target_mask_with_coverage(layout, target_mask),
		"paint marker fixture must install target metadata"
	)
	var body_rid := PhysicsServer3D.body_create()
	var paint := PaintSystem.new()
	root.add_child(paint)
	var material := ShaderMaterial.new()
	material.shader = PAINT_SHADER
	paint.configure(
		layout.local_bounds,
		0.0,
		material,
		Color(0.03, 0.38, 1.0),
		layout,
		SURFACE_TUNING
	)
	paint.configure_top_surface_identity(
		body_rid,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		0
	)
	var trace_id := RuntimeDeliveryTelemetry.begin_fire_trace({"scenario": "paint_publication"})
	var shot_id := 7001
	RuntimeDeliveryTelemetry.bind_shot_trace(trace_id, shot_id)
	RuntimeDeliveryTelemetry.end_fire_trace(trace_id)
	var point := Vector3(0.0, layout.height_at_local(0.0, 0.0), 0.0)
	var command := RadialPaintMark.new(
		shot_id,
		0,
		0,
		0,
		point,
		layout.normal_at_local(0.0, 0.0),
		4.0,
		body_rid,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		0,
		RadialPaintMark.Kind.IMPACT,
		shot_id,
		PaintChannel.Value.RED
	)
	_assert(paint.queue_radial_paint_mark(command), "paint marker command must queue")
	var paired := RadialPaintMark.new(
		shot_id,
		0,
		1,
		1,
		point,
		layout.normal_at_local(0.0, 0.0),
		14.0,
		body_rid,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		0,
		RadialPaintMark.Kind.BURST,
		shot_id,
		PaintChannel.Value.RED
	)
	_assert(paint.queue_radial_paint_mark(paired), "paired Burst paint marker command must queue")
	paint.drain_pending_commands()
	paint.force_flush_paint_texture()
	var followup := RadialPaintMark.new(
		7002,
		0,
		2,
		0,
		point + Vector3(1.0, 0.0, 0.0),
		layout.normal_at_local(1.0, 0.0),
		4.0,
		body_rid,
		TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID,
		TerrainSurface.TOP_SHAPE_ID,
		0,
		RadialPaintMark.Kind.IMPACT,
		shot_id,
		PaintChannel.Value.RED
	)
	_assert(paint.queue_radial_paint_mark(followup), "follow-up paint marker command must queue")
	paint.drain_pending_commands()
	paint.force_flush_paint_texture()
	var paint_started := _marker_index_with_trace_array(&"paint_batch_started", trace_id)
	var paint_finished := _marker_index_with_trace_array(&"paint_batch_finished", trace_id)
	var texture_started := _marker_index_with_trace_array(&"texture_publish_started", trace_id)
	var texture_finished := _marker_index_with_trace_array(&"texture_publish_finished", trace_id)
	_assert(
		paint_started >= 0 and paint_started < paint_finished \
				and paint_finished < texture_started and texture_started < texture_finished,
		"paint drain and texture publication markers must keep authoritative order"
	)
	_assert(
		_count_marker_with_trace_array(&"paint_batch_started", trace_id) == 1 \
				and _count_marker_with_trace_array(&"paint_batch_finished", trace_id) == 1 \
				and _count_marker_with_trace_array(&"texture_publish_started", trace_id) == 1 \
				and _count_marker_with_trace_array(&"texture_publish_finished", trace_id) == 1,
		"rolling paint must keep telemetry bounded to one drain and texture pair per Fire trace"
	)
	if paint_finished >= 0:
		_assert(
			int(_markers[paint_finished].get("command_count", 0)) == 2,
			"the first paint telemetry boundary must include every command already in its canonical batch"
		)
	if texture_finished >= 0:
		var payload := _markers[texture_finished]
		var dirty: Dictionary = payload.get("dirty_rect", {})
		_assert(
			int(dirty.get("width", 0)) > 0 and int(dirty.get("height", 0)) > 0 \
					and String(payload.get("upload_path", "")).length() > 0,
			"texture completion must report a non-empty dirty region and upload path"
		)
	paint.free()
	PhysicsServer3D.free_rid(body_rid)


func _check_apex_replacement_markers() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var surface := TERRAIN_FIXTURE.instantiate() as TerrainSurface
	host.add_child(surface)
	surface.configure(TERRAIN_FACTORY.build_layout(TERRAIN_FACTORY.Kind.FLAT))
	var manager := ProjectileManager.new()
	host.add_child(manager)
	manager.configure_terrain(surface)
	await physics_frame
	var trace_id := RuntimeDeliveryTelemetry.begin_fire_trace({"scenario": "apex_replacement"})
	var parent := manager.spawn_projectile(
		PROJECTILE_DATA,
		Vector3(0.0, 20.0, 0.0),
		Vector3(10.0, 10.0, 0.0),
		0,
		0,
		-1.0,
		BallToken.new(BallKind.Value.APEX_SPLIT, PaintChannel.Value.GREEN)
	)
	RuntimeDeliveryTelemetry.end_fire_trace(trace_id)
	_assert(parent != null, "Apex marker fixture must admit its root")
	if parent != null:
		parent.freeze = true
		manager._on_apex_split_requested(
			parent,
			[Vector3(8.0, 1.5, 0.0), Vector3(0.0, 1.5, 8.0), Vector3(-8.0, 1.5, 0.0)]
		)
	var events := _markers_for_trace(trace_id)
	_assert(
		_count_named(events, &"split_replacement_started") == 1 \
				and _count_named(events, &"split_child_construction_started") == 3 \
				and _count_named(events, &"split_child_construction_finished") == 3 \
				and _count_named(events, &"split_child_admitted") == 3 \
				and _count_named(events, &"split_replacement_finished") == 1,
		"Apex replacement must expose one atomic boundary and three constructed/admitted children"
	)
	var last_child_admitted := _last_marker_index(events, &"split_child_admitted")
	var replacement_finished := _marker_index(events, &"split_replacement_finished")
	_assert(
		last_child_admitted >= 0 and last_child_admitted < replacement_finished,
		"Apex replacement completion must follow all three child admissions"
	)
	if replacement_finished >= 0:
		_assert(
			bool(events[replacement_finished].get("success", false)) \
					and int(events[replacement_finished].get("constructed_children", 0)) == 3,
			"Apex replacement completion must report its successful three-child result"
		)
	manager.cleanup()
	host.queue_free()
	await physics_frame


func _assert_root_delivery_order(trace_id: int, label: String) -> void:
	var events := _markers_for_trace(trace_id)
	var names: Array[StringName] = [
		&"fire_input_received",
		&"fire_admission_started",
		&"root_construction_started",
		&"root_construction_finished",
		&"root_admitted",
		&"fire_accepted",
		&"root_frame_presented",
	]
	var previous_index := -1
	for marker in names:
		var index := _marker_index(events, marker)
		_assert(index > previous_index, "%s marker %s must follow the prior boundary" % [label, marker])
		_assert(_count_named(events, marker) == 1, "%s marker %s must occur exactly once" % [label, marker])
		previous_index = index
	var construction_finished := _marker_index(events, &"root_construction_finished")
	if construction_finished >= 0:
		_assert(
			int(events[construction_finished].get("duration_usec", -1)) >= 0,
			"%s construction completion must include a duration" % label
		)
	var root_presented := _marker_index(events, &"root_frame_presented")
	if root_presented >= 0:
		_assert(
			String(events[root_presented].get("frame_boundary", "")) == "test_process_frame",
			"headless root presentation must identify its process-frame test fallback"
		)


func _capture_marker(payload: Dictionary) -> void:
	_markers.append(payload.duplicate(true))


func _first_trace_id_since(start_index: int) -> int:
	for index in range(start_index, _markers.size()):
		if StringName(_markers[index].get("paint_mountain_marker", "")) == &"fire_input_received":
			return int(_markers[index].get("trace_id", 0))
	return 0


func _markers_for_trace(trace_id: int) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for payload in _markers:
		if int(payload.get("trace_id", 0)) == trace_id:
			matches.append(payload)
	return matches


func _count_marker(trace_id: int, marker: StringName, effect_id: StringName) -> int:
	var count := 0
	for payload in _markers_for_trace(trace_id):
		if StringName(payload.get("paint_mountain_marker", "")) == marker \
				and StringName(payload.get("effect_id", "")) == effect_id:
			count += 1
	return count


func _count_named(events: Array[Dictionary], marker: StringName) -> int:
	var count := 0
	for payload in events:
		if StringName(payload.get("paint_mountain_marker", "")) == marker:
			count += 1
	return count


func _marker_index(events: Array[Dictionary], marker: StringName) -> int:
	for index in range(events.size()):
		if StringName(events[index].get("paint_mountain_marker", "")) == marker:
			return index
	return -1


func _last_marker_index(events: Array[Dictionary], marker: StringName) -> int:
	for index in range(events.size() - 1, -1, -1):
		if StringName(events[index].get("paint_mountain_marker", "")) == marker:
			return index
	return -1


func _marker_index_with_trace_array(marker: StringName, trace_id: int) -> int:
	for index in range(_markers.size()):
		var payload := _markers[index]
		if StringName(payload.get("paint_mountain_marker", "")) != marker:
			continue
		var trace_ids: Array = payload.get("trace_ids", [])
		if trace_ids.has(trace_id):
			return index
	return -1


func _count_marker_with_trace_array(marker: StringName, trace_id: int) -> int:
	var count := 0
	for payload in _markers:
		if StringName(payload.get("paint_mountain_marker", "")) != marker:
			continue
		var trace_ids: Array = payload.get("trace_ids", [])
		if trace_ids.has(trace_id):
			count += 1
	return count


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Delivery latency marker check failed: %s" % message)
