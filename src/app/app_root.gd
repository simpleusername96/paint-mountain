class_name AppRoot
extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const ENVIRONMENT_DRESSING_SCRIPT := preload("res://src/terrain/environment_dressing.gd")

var _preview_world: Node3D
var _preview_mountain: MeshInstance3D
var _preview_dressing: Node3D
var _main_menu: MainMenuScreen
var _stage_select: StageSelectScreen
var _settings: SettingsScreen
var _gameplay: Node3D
var _settings_return: StringName = &"main_menu"
var _preview_layout_cache: Dictionary = {}


func _ready() -> void:
	_build_preview_world()
	_main_menu = MainMenuScreen.new()
	_main_menu.name = "MainMenu"
	add_child(_main_menu)
	_stage_select = StageSelectScreen.new()
	_stage_select.name = "StageSelect"
	add_child(_stage_select)
	_settings = SettingsScreen.new()
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
	_stage_select.selection_changed.connect(_set_preview_stage)
	_settings.close_requested.connect(_on_settings_closed)


func _show_main_menu() -> void:
	_audio_ui()
	_remove_gameplay()
	_preview_world.visible = true
	_main_menu.visible = true
	_stage_select.visible = false
	_set_preview_stage(StageCatalog.get_stage(&"first_descent"))
	_main_menu.focus_primary.call_deferred()


func _show_stage_select() -> void:
	_audio_ui()
	_remove_gameplay()
	_preview_world.visible = true
	_main_menu.visible = false
	_stage_select.visible = true
	_stage_select.refresh()
	_stage_select.focus_primary.call_deferred()


func _start_selected_stage() -> void:
	var game_state := get_node("/root/GameState")
	_start_stage(game_state.selected_stage_id)


func _start_stage(stage_id: StringName) -> void:
	var game_state := get_node("/root/GameState")
	if not game_state.select_stage(stage_id):
		return
	_audio_ui()
	_remove_gameplay()
	_preview_world.visible = false
	_main_menu.visible = false
	_stage_select.visible = false
	_gameplay = GAMEPLAY_SCENE.instantiate()
	_gameplay.name = "ActiveGameplay"
	add_child(_gameplay)
	if _gameplay.has_signal("navigation_requested"):
		_gameplay.navigation_requested.connect(_on_gameplay_navigation)


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
	_settings_return = return_to
	if return_to == &"main_menu":
		_main_menu.visible = false
	elif return_to == &"stage_select":
		_stage_select.visible = false
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
	_preview_mountain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_preview_world.add_child(_preview_mountain)
	_preview_dressing = ENVIRONMENT_DRESSING_SCRIPT.new()
	_preview_dressing.name = "PreviewDressing"
	_preview_world.add_child(_preview_dressing)
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
	_set_preview_stage(StageCatalog.get_stage(&"first_descent"))


func _set_preview_stage(stage: StageData) -> void:
	if stage == null or _preview_mountain == null:
		return
	var layout: GeneratedStageLayout = _preview_layout_cache.get(stage.stage_id)
	if layout == null:
		layout = SeededStageGenerator.generate(stage.generation_profile, stage.terrain_seed, stage)
		if layout != null:
			_preview_layout_cache[stage.stage_id] = layout
	if layout == null:
		push_error("Could not build preview layout for %s." % stage.stage_id)
		return
	_preview_mountain.mesh = TerrainMeshFactory.build_from_layout(layout)
	var material := ShaderMaterial.new()
	material.shader = load("res://src/paint/terrain_paint.gdshader")
	material.set_shader_parameter(&"paint_mask", _preview_paint_texture(stage.stage_number))
	material.set_shader_parameter(&"paint_color", stage.paint_color)
	material.set_shader_parameter(&"rock_color", Color(0.63, 0.65, 0.68, 1.0))
	_preview_mountain.material_override = material
	_preview_dressing.configure(stage, layout)


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
