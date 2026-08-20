extends SceneTree

const FIXTURE := preload("res://tests/support/baked_gameplay_fixture.gd")
const EVIDENCE_PATH := \
	"res://.agents/evidence/three-ball-target-band-prototype-2026-08-18/compact-performance.json"
const STAGE_ID := &"stage_06"
const ROOT_COUNT := 6
const APEX_ROOT_COUNT := 2
const MAXIMUM_SCENARIO_TICKS := 60 * 60
const POST_LAUNCH_TICKS := 30
const FRAME_INTERVAL_AVERAGE_BUDGET_MS := 20.0
const FRAME_INTERVAL_P95_REFERENCE_MS := 1000.0 / 30.0
const OBJECT_RETENTION_ALLOWANCE := 64

var _failed := false
var _failure_messages: Array[String] = []
var _frame_intervals_ms: Array[float] = []
var _physics_monitor_aggregate_ms: Array[float] = []
var _last_physics_frame_usec := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var gameplay := FIXTURE.instantiate(STAGE_ID)
	_assert(gameplay != null, "the baked Stage 06 fixture must instantiate")
	if gameplay == null:
		_write_evidence({"passed": false, "failures": _failure_messages})
		quit(1)
		return
	root.add_child(gameplay)
	for _index in range(12):
		await physics_frame

	var controller := gameplay.get_node("StageController") as StageController
	var manager := gameplay.get_node("ProjectileManager") as ProjectileManager
	var paint := gameplay.get_node("PaintSystem") as PaintSystem
	var layout := gameplay.generated_layout() as GeneratedStageLayout
	_assert(controller != null and manager != null and paint != null,
		"the performance fixture must expose its runtime owners")
	_assert(controller.stage_data.uses_target_band()
		and controller.stage_data.maximum_shots == ROOT_COUNT,
		"the scenario requires a six-root prototype stage")
	if _failed:
		gameplay.queue_free()
		await process_frame
		_write_evidence({"passed": false, "failures": _failure_messages})
		quit(1)
		return

	# This is one explicit performance workload, not a shippable deal. It keeps
	# the real StageController admission path while fixing the kind/channel mix.
	var scenario_deal: Array[BallToken] = [
		BallToken.new(BallKind.Value.APEX_SPLIT, PaintChannel.Value.RED),
		BallToken.new(BallKind.Value.APEX_SPLIT, PaintChannel.Value.GREEN),
		BallToken.new(BallKind.Value.IMPACT_BURST, PaintChannel.Value.RED),
		BallToken.new(BallKind.Value.IMPACT_BURST, PaintChannel.Value.GREEN),
		BallToken.new(BallKind.Value.STANDARD, PaintChannel.Value.RED),
		BallToken.new(BallKind.Value.STANDARD, PaintChannel.Value.GREEN),
	]
	controller._deal = scenario_deal
	controller._queue_cursor = 0
	controller.shots_remaining = scenario_deal.size()
	controller._duration_run_ticks = 60 * 120
	controller._emit_deal_changed()

	var observed := {
		"root_spawns": 0,
		"generation_one_children": 0,
		"apex_splits": 0,
		"impact_bursts": 0,
		"peak_residents": 0,
		"paint_drains": 0,
		"paint_commands": 0,
		"written_pixels": 0,
	}
	manager.projectile_spawned.connect(func(projectile: PaintProjectile) -> void:
		if projectile.split_generation == 0:
			observed.root_spawns = int(observed.root_spawns) + 1
		elif projectile.split_generation == 1:
			observed.generation_one_children = int(observed.generation_one_children) + 1
		observed.peak_residents = maxi(int(observed.peak_residents), manager.active_count())
	)
	manager.activity_changed.connect(
		func(_shot_ids: PackedInt64Array, active_projectiles: int) -> void:
			observed.peak_residents = maxi(int(observed.peak_residents), active_projectiles)
	)
	manager.ball_effect_triggered.connect(
		func(_projectile: PaintProjectile, effect_id: StringName, _position: Vector3) -> void:
			if effect_id == &"apex_split":
				observed.apex_splits = int(observed.apex_splits) + 1
			elif effect_id == &"impact_burst":
				observed.impact_bursts = int(observed.impact_bursts) + 1
	)
	paint.paint_commands_drained.connect(
		func(_tick: int, command_count: int, _checksum: int) -> void:
			observed.paint_drains = int(observed.paint_drains) + 1
			observed.paint_commands = int(observed.paint_commands) + command_count
	)
	paint.paint_command_applied.connect(
		func(_command, written_pixel_count: int, _newly_painted: int) -> void:
			observed.written_pixels = int(observed.written_pixels) + written_pixel_count
	)

	var object_count_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var upload_count_before := paint.texture_upload_batch_count()
	var scenario_started_usec := Time.get_ticks_usec()
	_last_physics_frame_usec = scenario_started_usec
	_assert(controller.begin_aiming(), "the compact scenario must enter aiming")
	var launched := 0
	var ticks := 0
	var post_launch_ticks := 0
	while ticks < MAXIMUM_SCENARIO_TICKS:
		if launched < scenario_deal.size() \
				and bool(controller.fire_readiness_snapshot(
					StageController.ActionOrigin.DEBUG
				).get("fireable", false)):
			var aim := _scenario_aim(layout, launched)
			_assert(controller.set_aim(
				aim.yaw_degrees, aim.elevation_degrees, aim.power_percent,
				StageController.ActionOrigin.DEBUG
			), "scenario aim %d must be accepted" % (launched + 1))
			_assert(controller.request_fire(StageController.ActionOrigin.DEBUG),
				"scenario root %d must be admitted" % (launched + 1))
			if _failed:
				break
			launched += 1
		await physics_frame
		_record_frame_health_sample()
		observed.peak_residents = maxi(int(observed.peak_residents), manager.active_count())
		ticks += 1
		if launched == scenario_deal.size() \
				and manager.active_root_count() == 0 \
				and int(observed.apex_splits) == APEX_ROOT_COUNT \
				and int(observed.written_pixels) > 0:
			post_launch_ticks += 1
			if post_launch_ticks >= POST_LAUNCH_TICKS:
				break
		else:
			post_launch_ticks = 0

	manager.finalize_pending_paint_intents()
	paint.force_flush_paint_texture()
	var scenario_elapsed_ms := float(Time.get_ticks_usec() - scenario_started_usec) / 1000.0
	var upload_batches := paint.texture_upload_batch_count() - upload_count_before
	var painted_snapshot := paint.coverage_snapshot()
	var paint_queue_latency := paint.queue_latency_snapshot()
	var partial_upload_supported := paint.paint_texture().has_method(&"set_data_partial")
	var frame_interval_average_ms := _average(_frame_intervals_ms)
	var frame_interval_p95_ms := _percentile(_frame_intervals_ms, 0.95)
	var frame_interval_maximum_ms: float = float(_frame_intervals_ms.max()) \
		if not _frame_intervals_ms.is_empty() else 0.0

	_assert(launched == ROOT_COUNT and int(observed.root_spawns) == ROOT_COUNT,
		"all six representative roots must launch")
	_assert(int(observed.apex_splits) == APEX_ROOT_COUNT,
		"exactly two Apex families must split")
	_assert(int(observed.generation_one_children) == APEX_ROOT_COUNT * 3,
		"two Apex families must create exactly six generation-one children")
	_assert(int(observed.peak_residents) <= ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES,
		"resident peak must stay within the 21-body policy")
	_assert(int(observed.paint_commands) > 0 and int(observed.written_pixels) > 0
		and painted_snapshot.total_percent > 0.0,
		"the real prototype terrain must receive authoritative paint")
	_assert(manager.pending_intent_count() == 0 and paint.pending_work_count() == 0,
		"paint intent and command queues must drain")
	_assert(upload_batches > 0 and upload_batches < int(observed.paint_drains),
		"dirty paint must publish through a bounded batched-upload cadence")
	_assert(frame_interval_average_ms <= FRAME_INTERVAL_AVERAGE_BUDGET_MS,
		"sustained physics-frame delivery must remain healthy during the compact workload")
	_assert(int(paint_queue_latency.maximum_oldest_pending_age_ticks) <= 12,
		"the oldest authoritative paint command must stay within 12 physics ticks")
	_assert(int(paint_queue_latency.maximum_drain_usec) < 16700,
		"one interactive PaintSystem drain must stay below one 60 Hz frame")

	var restart_observed := {"elapsed_ms": -1.0}
	controller.restart_completed.connect(func(elapsed_ms: float) -> void:
		restart_observed.elapsed_ms = elapsed_ms
	, CONNECT_ONE_SHOT)
	while controller.current_state == StageController.State.FINISHING:
		await physics_frame
	var restart_call_started_usec := Time.get_ticks_usec()
	var restart_succeeded := controller.restart(false, StageController.ActionOrigin.DEBUG)
	var restart_call_ms := float(Time.get_ticks_usec() - restart_call_started_usec) / 1000.0
	var visual_restart_budget := 120
	while paint.dirty_region_read_only().has_area() and visual_restart_budget > 0:
		await process_frame
		visual_restart_budget -= 1
	var visual_restart_ms := float(Time.get_ticks_usec() - restart_call_started_usec) / 1000.0
	var object_count_after_restart := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory_after_restart := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var restart_signal_ms := float(restart_observed.elapsed_ms)
	_assert(restart_succeeded and restart_signal_ms >= 0.0 and restart_signal_ms < 1000.0,
		"authoritative restart must complete below the one-second target")
	_assert(visual_restart_budget > 0 and visual_restart_ms < 1000.0,
		"the restarted paint texture must publish below the one-second target")
	_assert(manager.active_count() == 0 and manager.active_root_count() == 0
		and manager.pending_intent_count() == 0 and paint.pending_work_count() == 0,
		"restart must release every task-owned resident and pending command")
	_assert(object_count_after_restart <= object_count_before + OBJECT_RETENTION_ALLOWANCE,
		"one complete workload/restart cycle must retain only a bounded object allowance")

	var evidence := {
		"acceptance": {
			"passed": not _failed,
			"failures": _failure_messages,
		},
		"engine": Engine.get_version_info(),
		"renderer": String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")),
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"scenario": {
			"stage_id": String(STAGE_ID),
			"root_count": launched,
			"root_mix": ["apex_split_red", "apex_split_green",
				"impact_burst_red", "impact_burst_green", "standard_red", "standard_green"],
			"apex_splits": int(observed.apex_splits),
			"generation_one_children": int(observed.generation_one_children),
			"impact_bursts": int(observed.impact_bursts),
			"elapsed_ms": scenario_elapsed_ms,
			"physics_ticks": ticks,
		},
		"physics_frame_intervals_ms": {
			"sample_count": _frame_intervals_ms.size(),
			"average": frame_interval_average_ms,
			"p95": frame_interval_p95_ms,
			"maximum": frame_interval_maximum_ms,
			"average_budget": FRAME_INTERVAL_AVERAGE_BUDGET_MS,
			"p95_reference": FRAME_INTERVAL_P95_REFERENCE_MS,
			"p95_is_release_gate": false,
			"engine_monitor_aggregate_average": _average(_physics_monitor_aggregate_ms),
			"engine_monitor_note": "TIME_PHYSICS_PROCESS is a periodically refreshed aggregate and is not used as a per-tick gate.",
		},
		"paint": {
			"command_drains": int(observed.paint_drains),
			"commands": int(observed.paint_commands),
			"written_pixels": int(observed.written_pixels),
			"coverage_percent": painted_snapshot.total_percent,
			"texture_upload_batches": upload_batches,
			"partial_upload_api_available": partial_upload_supported,
			"upload_path": "region" if partial_upload_supported else "full_image_fallback",
			"pending_intents_after_flush": manager.pending_intent_count(),
			"pending_commands_after_flush": paint.pending_work_count(),
			"queue_latency": paint_queue_latency,
		},
		"lifecycle": {
			"resident_peak": int(observed.peak_residents),
			"resident_limit": ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES,
			"restart_signal_ms": restart_signal_ms,
			"restart_call_ms": restart_call_ms,
			"visual_restart_ms": visual_restart_ms,
			"objects_before": object_count_before,
			"objects_after_restart": object_count_after_restart,
			"object_delta": object_count_after_restart - object_count_before,
			"object_allowance": OBJECT_RETENTION_ALLOWANCE,
			"memory_static_before": memory_before,
			"memory_static_after_restart": memory_after_restart,
			"memory_static_delta": memory_after_restart - memory_before,
		},
		"limitations": [
			"One deterministic native headless workload measures physics-frame delivery, not rendered GPU presentation.",
			"Headless fixed ticks may be coalesced by host scheduling, so p95 callback interval is diagnostic while sustained average throughput is the gate.",
			"Godot Compatibility used the full-image upload fallback; the ten-hertz batched cadence is the measured guardrail.",
			"The post-restart object bound is a compact leak sentinel, not a multi-hour soak test.",
		],
	}
	_write_evidence(evidence)
	gameplay.queue_free()
	await process_frame
	if not _failed:
		print("Compact performance passed: six roots, two Apex families, bounded paint/upload/restart lifecycle.")
	quit(1 if _failed else 0)


func _scenario_aim(layout: GeneratedStageLayout, index: int) -> AimTuple:
	var aim := layout.default_aim
	var certificate := layout.reachability_certificate as DirectReachabilityCertificate
	if certificate != null and certificate.is_valid() and not certificate.witnesses.is_empty():
		var witness_index := roundi(
			float(index) * float(certificate.witnesses.size() - 1)
			/ float(maxi(ROOT_COUNT - 1, 1))
		)
		aim = certificate.witnesses[witness_index]
	if index < APEX_ROOT_COUNT:
		return AimTuple.canonicalize(
			aim.yaw_degrees,
			maxf(aim.elevation_degrees, 45.0),
			aim.power_percent
		)
	return aim


func _record_frame_health_sample() -> void:
	var now_usec := Time.get_ticks_usec()
	if _last_physics_frame_usec > 0:
		_frame_intervals_ms.append(float(now_usec - _last_physics_frame_usec) / 1000.0)
	_last_physics_frame_usec = now_usec
	var aggregate_ms := 1000.0 * float(
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	)
	if is_finite(aggregate_ms) and aggregate_ms >= 0.0:
		_physics_monitor_aggregate_ms.append(aggregate_ms)


func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _percentile(values: Array[float], quantile: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array[float] = values.duplicate()
	sorted_values.sort()
	var index := clampi(ceili(quantile * float(sorted_values.size() - 1)), 0, sorted_values.size() - 1)
	return sorted_values[index]


func _write_evidence(evidence: Dictionary) -> void:
	var file := FileAccess.open(EVIDENCE_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "compact performance evidence must be writable")
		return
	file.store_string(JSON.stringify(evidence, "\t") + "\n")


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	_failure_messages.append(message)
	push_error("Compact performance failed: %s" % message)
