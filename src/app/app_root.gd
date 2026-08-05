class_name AppRoot
extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const ENVIRONMENT_DRESSING_SCRIPT := preload("res://src/terrain/environment_dressing.gd")
const MAIN_MENU_SCENE := preload("res://scenes/ui/screens/main_menu.tscn")
const STAGE_SELECT_SCENE := preload("res://scenes/ui/screens/stage_select.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings.tscn")
const STAGE_LAYOUT_PREPARER_SCRIPT := preload("res://src/app/stage_layout_preparer.gd")

var _preview_world: Node3D
var _preview_mountain: MeshInstance3D
var _main_menu: MainMenuScreen
var _stage_select: StageSelectScreen
var _settings: SettingsScreen
var _gameplay: Node3D
var _layout_preparer: StageLayoutPreparer
var _settings_return: StringName = &"main_menu"
var _preview_artifact_cache: Dictionary = {}
var _active_preview_stage_id: StringName = &""
var _pending_start_stage_id: StringName = &""


func _ready() -> void:
	_layout_preparer = STAGE_LAYOUT_PREPARER_SCRIPT.new()
	_layout_preparer.name = "StageLayoutPreparer"
	add_child(_layout_preparer)
	_layout_preparer.layout_ready.connect(_on_layout_ready)
	_layout_preparer.layout_failed.connect(_on_layout_failed)
	_build_preview_world()
	_main_menu = MAIN_MENU_SCENE.instantiate()
	_main_menu.name = "MainMenu"
	add_child(_main_menu)
	_stage_select = STAGE_SELECT_SCENE.instantiate()
	_stage_select.name = "StageSelect"
	add_child(_stage_select)
	_settings = SETTINGS_SCENE.instantiate()
	_settings.name = "Settings"
	add_child(_settings)
	_connect_screens()
	_show_main_menu()


func _connect_screens() -> void:
	_main_menu.play_requested.connect(_start_selected_stage)
	_main_menu.stage_select_requested.connect(_show_stage_select)
	_main_menu.settings_requested.connect(func() -> void: _show_settings(&"main_menu"))
	_main_menu.quit_requested.connect(func() -> void: get_tree().quit())
	_stage_select.back_requested.connect(_show_main_menu)
	_stage_select.start_requested.connect(_start_stage)
	_stage_select.selection_changed.connect(_on_stage_selection_changed)
	_settings.close_requested.connect(_on_settings_closed)


func _show_main_menu() -> void:
	_audio_ui()
	_pending_start_stage_id = &""
	_remove_gameplay()
	_preview_world.visible = true
	_main_menu.visible = true
	_stage_select.visible = false
	var game_state := get_node("/root/GameState")
	_request_user_stage(StageCatalog.get_stage(game_state.selected_stage_id))
	_request_menu_preview()
	_main_menu.focus_primary.call_deferred()


func _show_stage_select() -> void:
	_audio_ui()
	_pending_start_stage_id = &""
	_remove_gameplay()
	_preview_world.visible = true
	_main_menu.visible = false
	_stage_select.visible = true
	_stage_select.refresh()
	_request_user_stage(StageCatalog.get_stage(_stage_select.selected_stage_id()))
	_stage_select.focus_primary.call_deferred()


func _start_selected_stage() -> void:
	var game_state := get_node("/root/GameState")
	_start_stage(game_state.selected_stage_id)


func _start_stage(stage_id: StringName) -> void:
	var game_state := get_node("/root/GameState")
	if not game_state.select_stage(stage_id):
		return
	var selected_stage := StageCatalog.get_stage(stage_id)
	var cached_layout := _layout_preparer.ready_layout(selected_stage)
	if cached_layout == null:
		_pending_start_stage_id = selected_stage.stage_id
		_set_stage_preparation_state(selected_stage, false)
		_layout_preparer.request_layout(selected_stage, true)
		return
	_enter_stage(selected_stage, cached_layout)


func _enter_stage(selected_stage: StageData, cached_layout: GeneratedStageLayout) -> void:
	if selected_stage == null or not _layout_matches_stage(cached_layout, selected_stage):
		if selected_stage != null:
			_set_stage_preparation_state(selected_stage, false, true)
		return
	_pending_start_stage_id = &""
	_audio_ui()
	_remove_gameplay()
	_preview_world.visible = false
	_main_menu.visible = false
	_stage_select.visible = false
	_gameplay = GAMEPLAY_SCENE.instantiate()
	_gameplay.name = "ActiveGameplay"
	_gameplay.call(&"prepare_stage", selected_stage, cached_layout)
	if _gameplay.has_signal("navigation_requested"):
		_gameplay.navigation_requested.connect(_on_gameplay_navigation)
	add_child(_gameplay)
	_prefetch_next_stage(selected_stage.stage_id)


func _on_stage_selection_changed(stage: StageData) -> void:
	if stage == null:
		return
	if not _pending_start_stage_id.is_empty() and _pending_start_stage_id != stage.stage_id:
		_pending_start_stage_id = &""
	_request_user_stage(stage)


func _request_user_stage(stage: StageData) -> void:
	if stage == null:
		return
	var ready := _layout_preparer.ready_layout(stage) != null
	_set_stage_preparation_state(stage, ready)
	if not ready:
		_layout_preparer.request_layout(stage, true)


func _set_stage_preparation_state(
		stage: StageData,
		ready: bool,
		failed: bool = false
) -> void:
	if stage == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	if _main_menu != null and game_state != null \
			and game_state.selected_stage_id == stage.stage_id:
		_main_menu.set_play_preparation_state(ready, failed)
	if _stage_select != null:
		_stage_select.set_stage_preparation_state(stage.stage_id, ready, failed)


func _on_layout_ready(stage_id: StringName, layout: GeneratedStageLayout) -> void:
	var stage := StageCatalog.get_stage(stage_id)
	if stage == null or not _layout_matches_stage(layout, stage):
		_on_layout_failed(stage_id)
		return
	_set_stage_preparation_state(stage, true)
	if _pending_start_stage_id == stage_id:
		_enter_stage(stage, layout)
		return
	if stage_id == &"stage_01" and _preview_world.visible:
		_set_menu_preview_if_visible.call_deferred(stage)


func _on_layout_failed(stage_id: StringName) -> void:
	var stage := StageCatalog.get_stage(stage_id)
	if stage != null:
		_set_stage_preparation_state(stage, false, true)
	if _pending_start_stage_id == stage_id:
		_pending_start_stage_id = &""


func _prefetch_next_stage(stage_id: StringName) -> void:
	var next_stage_id := StageCatalog.next_stage_id(stage_id)
	if next_stage_id.is_empty():
		return
	var next_stage := StageCatalog.get_stage(next_stage_id)
	if next_stage != null:
		_layout_preparer.request_layout(next_stage, false)


func _request_menu_preview() -> void:
	var preview_stage := StageCatalog.get_stage(&"stage_01")
	if preview_stage == null:
		return
	if _layout_preparer.ready_layout(preview_stage) != null:
		_set_menu_preview_if_visible.call_deferred(preview_stage)
	else:
		_layout_preparer.request_layout(preview_stage, false)


func _set_menu_preview_if_visible(stage: StageData) -> void:
	if _preview_world.visible and _main_menu.visible:
		_set_preview_stage(stage)


func _on_gameplay_navigation(destination: StringName) -> void:
	match destination:
		&"main_menu":
			_show_main_menu()
		&"stage_select":
			_show_stage_select()
		&"next_stage":
			var game_state := get_node("/root/GameState")
			var next_id := StageCatalog.next_stage_id(game_state.selected_stage_id)
			if next_id.is_empty() or not game_state.unlocked_stages.has(next_id):
				_show_stage_select()
			else:
				_start_stage(next_id)
		&"settings":
			_show_settings(&"gameplay")


func _remove_gameplay() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if _gameplay != null and is_instance_valid(_gameplay):
		_gameplay.queue_free()
		_gameplay = null


func _show_settings(return_to: StringName) -> void:
	_audio_ui()
	_pending_start_stage_id = &""
	_settings_return = return_to
	if return_to == &"main_menu":
		_main_menu.visible = false
	elif return_to == &"stage_select":
		_stage_select.visible = false
	elif return_to == &"gameplay":
		# Gameplay owns the paused scrim; the full settings screen is only entered
		# from the explicit pause panel, so keep the parent hidden while it opens.
		pass
	_settings.open()


func _on_settings_closed() -> void:
	match _settings_return:
		&"stage_select":
			_stage_select.visible = true
			_stage_select.focus_primary.call_deferred()
		&"gameplay":
			pass
		_:
			_main_menu.visible = true
			_main_menu.focus_primary.call_deferred()


func _build_preview_world() -> void:
	_preview_world = Node3D.new()
	_preview_world.name = "PreviewWorld"
	add_child(_preview_world)
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color(0.93, 0.91, 0.88, 1.0)
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color(0.78, 0.8, 0.84, 1.0)
	environment_resource.ambient_light_energy = 0.72
	environment.environment = environment_resource
	_preview_world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.86, 1.0)
	sun.light_energy = 0.94
	sun.shadow_enabled = true
	_preview_world.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(94.0, 58.0, 20.0)
	camera.fov = 48.0
	camera.current = true
	_preview_world.add_child(camera)
	camera.look_at(Vector3(0.0, 24.0, -112.0), Vector3.UP)
	_preview_mountain = MeshInstance3D.new()
	_preview_mountain.name = "PreviewMountain"
	_preview_mountain.position = Vector3(0.0, -2.0, -112.0)
	_preview_mountain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_preview_world.add_child(_preview_mountain)
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(360.0, 360.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.79, 0.78, 0.75, 1.0)
	ground_material.roughness = 1.0
	ground_mesh.material = ground_material
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, -2.7, -100.0)
	_preview_world.add_child(ground)


func _set_preview_stage(stage: StageData) -> void:
	if stage == null or _preview_mountain == null:
		return
	var cached: Dictionary = _preview_artifact_cache.get(stage.stage_id, {})
	if _active_preview_stage_id == stage.stage_id \
			and _preview_artifact_matches_stage(cached, stage):
		return
	var artifact := _preview_artifact_for_stage(stage)
	if artifact.is_empty():
		return
	for entry in _preview_artifact_cache.values():
		var cached_dressing := entry.get("dressing") as Node3D
		if cached_dressing != null and is_instance_valid(cached_dressing):
			cached_dressing.visible = false
	_preview_mountain.position = stage.terrain_center
	_preview_mountain.mesh = artifact.get("mesh") as ArrayMesh
	_preview_mountain.material_override = artifact.get("material") as ShaderMaterial
	var dressing := artifact.get("dressing") as Node3D
	if dressing != null:
		dressing.visible = true
	_active_preview_stage_id = stage.stage_id


func _preview_artifact_for_stage(stage: StageData) -> Dictionary:
	if stage == null or stage.generation_profile == null:
		return {}
	var cached: Dictionary = _preview_artifact_cache.get(stage.stage_id, {})
	if _preview_artifact_matches_stage(cached, stage):
		return cached
	var layout := _layout_preparer.ready_layout(stage)
	if not _layout_matches_stage(layout, stage):
		return {}
	_clear_preview_artifact_cache()
	var geometry := TerrainGeometryFactory.build(layout)
	var paint_texture := _preview_paint_texture(stage.stage_number)
	var target_texture := _preview_target_texture(layout)
	var material := ShaderMaterial.new()
	material.shader = load("res://src/paint/terrain_paint.gdshader")
	material.set_shader_parameter(&"paint_mask", paint_texture)
	material.set_shader_parameter(&"target_mask", target_texture)
	material.set_shader_parameter(&"paint_color", stage.paint_color)
	material.set_shader_parameter(&"rock_color", Color("F2F4F7"))
	material.set_shader_parameter(&"shadow_tint", Color("C4CBD5"))
	var dressing: Node3D = ENVIRONMENT_DRESSING_SCRIPT.new()
	dressing.name = "PreviewDressing_%s" % stage.stage_id
	dressing.visible = false
	_preview_world.add_child(dressing)
	dressing.configure(stage, layout)
	var artifact := {
		"stage_id": stage.stage_id,
		"stage_version": stage.stage_version,
		"profile_id": stage.generation_profile.profile_id,
		"profile_version": stage.generation_profile.profile_version,
		"terrain_seed": stage.terrain_seed,
		"layout_checksum": layout.checksum,
		"paint_color": stage.paint_color,
		"mesh": geometry.render_mesh,
		"material": material,
		"paint_texture": paint_texture,
		"target_texture": target_texture,
		"dressing": dressing,
	}
	_preview_artifact_cache[stage.stage_id] = artifact
	return artifact


func _clear_preview_artifact_cache() -> void:
	for entry in _preview_artifact_cache.values():
		var cached_dressing := entry.get("dressing") as Node3D
		if cached_dressing != null and is_instance_valid(cached_dressing):
			cached_dressing.queue_free()
	_preview_artifact_cache.clear()
	_active_preview_stage_id = &""


func _preview_artifact_matches_stage(artifact: Dictionary, stage: StageData) -> bool:
	if artifact.is_empty() or stage == null or stage.generation_profile == null:
		return false
	var dressing := artifact.get("dressing") as Node3D
	return artifact.get("stage_id", &"") == stage.stage_id \
			and int(artifact.get("stage_version", -1)) == stage.stage_version \
			and artifact.get("profile_id", &"") == stage.generation_profile.profile_id \
			and int(artifact.get("profile_version", -1)) \
					== stage.generation_profile.profile_version \
			and int(artifact.get("terrain_seed", -1)) == stage.terrain_seed \
			and int(artifact.get("layout_checksum", 0)) != 0 \
			and artifact.get("paint_color", Color.TRANSPARENT) == stage.paint_color \
			and artifact.get("mesh") is ArrayMesh \
			and artifact.get("material") is ShaderMaterial \
			and artifact.get("paint_texture") is ImageTexture \
			and artifact.get("target_texture") is ImageTexture \
			and dressing != null and is_instance_valid(dressing)


func _layout_matches_stage(layout: GeneratedStageLayout, stage: StageData) -> bool:
	return layout != null and layout.matches_stage_identity(stage)


func _preview_target_texture(layout: GeneratedStageLayout) -> ImageTexture:
	var image := Image.create_from_data(512, 512, false, Image.FORMAT_L8, layout.target_mask)
	return ImageTexture.create_from_image(image)


func _preview_paint_texture(stage_number: int) -> ImageTexture:
	const SIZE := 256
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	image.fill(Color.BLACK)
	var centers: Array[Vector2] = [
		Vector2(0.45, 0.25),
		Vector2(0.49, 0.34),
		Vector2(0.45, 0.43),
		Vector2(0.51, 0.52),
	]
	if stage_number > 1:
		centers.append_array([Vector2(0.64, 0.32), Vector2(0.68, 0.43), Vector2(0.63, 0.54)])
	for y in range(SIZE):
		var normalized_y := float(y) / float(SIZE - 1)
		for x in range(SIZE):
			var normalized_x := float(x) / float(SIZE - 1)
			var amount := 0.0
			for center in centers:
				var distance := Vector2(normalized_x, normalized_y).distance_to(center)
				amount = maxf(amount, 1.0 - smoothstep(0.035, 0.075, distance))
			if amount > 0.0:
				image.set_pixel(x, y, Color(amount, amount, amount, 1.0))
	return ImageTexture.create_from_image(image)


func _audio_ui() -> void:
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.play_cue(&"ui")
