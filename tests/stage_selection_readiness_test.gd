extends SceneTree

const APP_SCENE := preload("res://scenes/app/app.tscn")
const TIMEOUT_MSEC := 60_000

var _failed := false
var _events: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var game_state := root.get_node("/root/GameState") as GameState
	game_state.persistence_enabled = false
	var data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	data.unlocked_stages = StageCatalog.all_stages().map(
		func(stage: StageData) -> String: return String(stage.stage_id)
	)
	data.selected_stage_id = "stage_01"
	game_state.initialize_from_data(data)

	var app := APP_SCENE.instantiate() as AppRoot
	root.add_child(app)
	await process_frame
	await process_frame
	app._show_stage_select()
	await process_frame

	var stage_select := app.get_node("StageSelect") as StageSelectScreen
	RuntimeDeliveryTelemetry.set_test_observer(_record_event)
	var preview_ground_id := app._preview_ground.get_instance_id()
	var preview_dressing_id := app._preview_dressing.get_instance_id()
	var intermediate_stage := StageCatalog.get_stage(&"stage_02")
	var requested_stage := StageCatalog.get_stage(&"stage_03")
	stage_select._stage_nodes[1].pressed.emit()
	await process_frame
	stage_select._stage_nodes[2].pressed.emit()
	_assert_true(
		stage_select.selected_stage_id() == requested_stage.stage_id,
		"the real Stage Select node must publish the latest rapid local selection"
	)
	_assert_true(
		game_state.selected_stage_id == &"stage_01",
		"selecting a card must not commit GameState before Start"
	)

	var ready_started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - ready_started < TIMEOUT_MSEC:
		if not stage_select._start_button.disabled \
				and app._active_preview_stage_id == requested_stage.stage_id:
			break
		await process_frame
	var ready_elapsed := Time.get_ticks_msec() - ready_started
	_assert_true(
		not app._prepared_gameplay_matches(requested_stage),
		"Stage Select browsing must not bind full Gameplay before Start"
	)
	_assert_true(
		not stage_select._start_button.disabled,
		"Start must become enabled when the latest artifact and preview are ready"
	)
	_assert_true(
		game_state.selected_stage_id == &"stage_01",
		"background readiness must still leave GameState unchanged before Start"
	)
	var preview_artifact := app._runtime_preparer.ready_artifact(requested_stage)
	_assert_true(
		preview_artifact != null
				and app._active_preview_stage_id == requested_stage.stage_id
				and app._preview_mountain.mesh == preview_artifact.geometry.render_mesh,
		"the latest ready local selection must publish its real terrain preview atomically"
	)
	_assert_true(
		app._preview_ground.get_instance_id() == preview_ground_id
				and app._preview_dressing.get_instance_id() == preview_dressing_id,
		"stage browsing must reuse the preview ground and dressing roots"
	)
	var selection_durations: Array[int] = []
	for event in _events:
		if String(event.get("paint_mountain_marker", "")) == "stage_selection_dispatched":
			selection_durations.append(int(event.get("duration_usec", 999999)))
	_assert_true(selection_durations.size() == 2
			and selection_durations.max() < 8000,
		"rapid selection dispatches must stay below 8 ms")
	_assert_true(
		_count_marker_for_stage(&"gameplay_instantiated", intermediate_stage.stage_id) == 0
				and _count_marker_for_stage(&"gameplay_instantiated", requested_stage.stage_id) == 0,
		"intermediate and final Gameplay scenes must not instantiate while browsing"
	)

	if not stage_select._start_button.disabled:
		stage_select._start_button.pressed.emit()
	var gameplay := await _wait_for_active_stage(app, requested_stage.stage_id)
	_assert_true(gameplay != null, "Start must enter the stage chosen on the rail")
	_assert_true(
		game_state.selected_stage_id == requested_stage.stage_id,
		"entering the prepared stage must commit the selected stage"
	)
	_assert_true(
		_count_marker_for_stage(&"gameplay_instantiated", intermediate_stage.stage_id) == 0
				and _count_marker_for_stage(&"gameplay_instantiated", requested_stage.stage_id) == 1,
		"Start must instantiate only the final selected Gameplay scene"
	)
	if not _failed:
		print(
			"Stage selection readiness passed: latest preview prepared in %d ms and only final Gameplay entered."
			% ready_elapsed
		)

	RuntimeDeliveryTelemetry.clear_test_observer()
	game_state.persistence_enabled = true
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _record_event(payload: Dictionary) -> void:
	_events.append(payload)


func _count_marker_for_stage(marker: StringName, stage_id: StringName) -> int:
	var count := 0
	for event in _events:
		if StringName(event.get("paint_mountain_marker", &"")) == marker \
				and StringName(event.get("stage_id", &"")) == stage_id:
			count += 1
	return count


func _wait_for_active_stage(app: AppRoot, stage_id: StringName) -> Node3D:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MSEC
	while Time.get_ticks_msec() < deadline:
		var gameplay := app.get_node_or_null("ActiveGameplay") as Node3D
		var active_stage := gameplay.get("stage_data") as StageData \
				if gameplay != null and not gameplay.is_queued_for_deletion() else null
		if active_stage != null and active_stage.stage_id == stage_id:
			return gameplay
		await process_frame
	return null


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
