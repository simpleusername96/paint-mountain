class_name DebugOverlay
extends CanvasLayer

signal replay_last_shot_requested
signal mechanism_labels_toggled(visible: bool)

var _stage_data: StageData
var _controller: StageController
var _cannon: CannonController
var _projectiles: ProjectileManager
var _paint: PaintSystem
var _trajectory: TrajectoryPreview
var _camera: CameraDirector
var _mechanisms: Array[GimmickBase] = []
var _replay: ReplayRecorder
var _root: Control
var _metrics: Label
var _paint_preview: TextureRect
var _eligible_preview: TextureRect
var _recent_preview: TextureRect
var _excluded_preview: TextureRect
var _last_gain: float = 0.0
var _last_restart_ms: float = 0.0
var _slow_motion: bool = false
var _labels_visible: bool = false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	set_process(OS.is_debug_build())
	set_process_unhandled_input(OS.is_debug_build())


func configure(
		stage_data: StageData,
		controller: StageController,
		cannon: CannonController,
		projectiles: ProjectileManager,
		paint: PaintSystem,
		trajectory: TrajectoryPreview,
		camera: CameraDirector,
		mechanisms: Array[GimmickBase],
		replay: ReplayRecorder
) -> void:
	_stage_data = stage_data
	_controller = controller
	_cannon = cannon
	_projectiles = projectiles
	_paint = paint
	_trajectory = trajectory
	_camera = camera
	_mechanisms = mechanisms
	_replay = replay
	_paint_preview.texture = _paint.paint_texture()
	_eligible_preview.texture = _paint.eligible_texture()
	_recent_preview.texture = _paint.recent_texture()
	_excluded_preview.texture = _paint.excluded_texture()
	_controller.shot_result.connect(func(gain: float, _total: float) -> void: _last_gain = gain)
	_controller.restart_completed.connect(func(elapsed_ms: float) -> void: _last_restart_ms = elapsed_ms)


func _process(_delta: float) -> void:
	if not visible or _controller == null:
		return
	var velocity := Vector3.ZERO
	var payload := 0.0
	var active := _projectiles.active_projectiles()
	if not active.is_empty():
		velocity = active[0].linear_velocity
		payload = active[0].remaining_payload
	var mechanism_lines: Array[String] = []
	for mechanism in _mechanisms:
		var snapshot := mechanism.state_snapshot()
		mechanism_lines.append("%s charge=%s cd=%.2f" % [snapshot.kind, snapshot.remaining_charges, snapshot.cooldown])
	var seed := int(_replay.attempt.get("physics_seed", 0)) if _replay != null else 0
	_metrics.text = "STATE  %s\nFPS  %d\nPROJECTILES  %d / %d\nVELOCITY  %s\nPAYLOAD  %.2f\nCOVERAGE  %.3f%%\nSHOT GAIN  %.3f%%\nTRAJECTORY SAMPLES  %d\nFIRST COLLISION  %s\nMECHANISMS\n%s\nSEED  %d\nBOUNDS  %s\nCAMERA  %s\nRESTART  %.3f ms\nFLOW  %s" % [
		_controller.state_name(),
		Engine.get_frames_per_second(),
		active.size(),
		ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES,
		velocity,
		payload,
		_paint.coverage_percent(),
		_last_gain,
		_trajectory.visible_sample_count(),
		str(_trajectory.first_collision_position) if _trajectory.has_first_collision else "NONE",
		"\n".join(mechanism_lines) if not mechanism_lines.is_empty() else "NONE",
		seed,
		_stage_data.stage_bounds,
		_camera.mode_name(),
		_last_restart_ms,
		"ON" if _paint.flow_simulation_enabled else "OFF",
	]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		visible = not visible
		get_viewport().set_input_as_handled()


func set_debug_visible(value: bool) -> void:
	if OS.is_debug_build():
		visible = value


func export_shot_log(path: String = "user://paint_mountain_shot_log.json") -> Error:
	if _replay == null:
		return ERR_UNCONFIGURED
	var payload := _replay.export_attempt()
	payload["exported_state"] = _controller.state_name()
	payload["coverage"] = _paint.coverage_percent()
	payload["last_shot_gain"] = _last_gain
	payload["mechanisms"] = []
	for mechanism in _mechanisms:
		payload.mechanisms.append(mechanism.state_snapshot())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return OK


func _build() -> void:
	_root = Control.new()
	_root.name = "DebugRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(520.0, clampf(get_viewport().get_visible_rect().size.y - 36.0, 320.0, 920.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.025, 0.045, 0.93)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = panel.custom_minimum_size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 18)
	scroll.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	var heading := Label.new()
	heading.text = "PAINT MOUNTAIN DEBUG  ·  F3"
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color(0.2, 0.62, 1.0))
	content.add_child(heading)
	_metrics = Label.new()
	_metrics.custom_minimum_size.y = 410.0
	_metrics.add_theme_font_size_override("font_size", 13)
	_metrics.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	content.add_child(_metrics)
	var previews := GridContainer.new()
	previews.columns = 2
	previews.add_theme_constant_override("h_separation", 12)
	previews.add_theme_constant_override("v_separation", 8)
	content.add_child(previews)
	_paint_preview = _mask_preview("PAINT MASK", previews)
	_eligible_preview = _mask_preview("ELIGIBLE MASK", previews)
	_recent_preview = _mask_preview("RECENT STAMPS", previews)
	_excluded_preview = _mask_preview("EXCLUDED MASK", previews)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	content.add_child(actions)
	_add_action(actions, "REFILL SHOTS", func() -> void: _controller.debug_refill_shots())
	_add_action(actions, "CLEAR PAINT", func() -> void: _paint.clear())
	_add_action(actions, "FORCE CLEAR", func() -> void: _controller.force_stage_clear())
	_add_action(actions, "TEST PROJECTILE", _spawn_test_projectile)
	_add_action(actions, "SLOW MOTION", _toggle_slow_motion)
	_add_action(actions, "TOGGLE FLOW", func() -> void: _paint.flow_simulation_enabled = not _paint.flow_simulation_enabled)
	_add_action(actions, "MECHANISM LABELS", _toggle_labels)
	_add_action(actions, "SAVE AIM", _save_aim)
	_add_action(actions, "REPLAY LAST SHOT", func() -> void: replay_last_shot_requested.emit())
	_add_action(actions, "EXPORT SHOT LOG", func() -> void: export_shot_log())


func _mask_preview(caption: String, parent: Container) -> TextureRect:
	var column := VBoxContainer.new()
	parent.add_child(column)
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	column.add_child(label)
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(222.0, 105.0)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(preview)
	return preview


func _add_action(parent: GridContainer, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(228.0, 38.0)
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(action)
	parent.add_child(button)


func _spawn_test_projectile() -> void:
	if _projectiles.active_count() >= ProjectileManager.MAXIMUM_ACTIVE_PROJECTILES:
		return
	_projectiles.spawn_projectile(_cannon.projectile_data, _cannon.get_launch_origin(), _cannon.get_launch_velocity())


func _toggle_slow_motion() -> void:
	_slow_motion = not _slow_motion
	Engine.time_scale = 0.35 if _slow_motion else 1.0


func _toggle_labels() -> void:
	_labels_visible = not _labels_visible
	mechanism_labels_toggled.emit(_labels_visible)


func _save_aim() -> void:
	var file := FileAccess.open("user://paint_mountain_debug_aim.json", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"stage_id": String(_stage_data.stage_id),
		"yaw": _cannon.yaw_degrees,
		"elevation": _cannon.elevation_degrees,
		"power": _cannon.power_percent,
	}, "\t"))
	file.close()
