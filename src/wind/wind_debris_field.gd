class_name WindDebrisField
extends Node3D

const MIN_DEBRIS_COUNT := 36
const MAX_DEBRIS_COUNT := 60
const SQUARE_METERS_PER_DEBRIS := 520.0
const MIN_HEIGHT_ABOVE_TERRAIN := 1.4
const HEIGHT_SPAN := 8.6
const GUST_CUE_SECONDS := 0.8
const MAX_PLACEMENT_ATTEMPTS := 48

var _terrain_surface: TerrainSurface
var _wind_controller: WindController
var _world_bounds := Rect2()
var _positions: Array[Vector3] = []
var _height_offsets := PackedFloat32Array()
var _phases := PackedFloat32Array()
var _scales := PackedFloat32Array()
var _multimesh: MultiMesh
var _visual_time := 0.0
var _gust_cue_remaining := 0.0
var _placement_random := RandomNumberGenerator.new()


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(game_state.settings)


func configure(
		stage_data: StageData,
		terrain_surface: TerrainSurface,
		wind_controller: WindController,
		schedule_seed: int
) -> void:
	assert(stage_data != null and terrain_surface != null and wind_controller != null)
	_terrain_surface = terrain_surface
	_wind_controller = wind_controller
	if not _wind_controller.strong_episode_started.is_connected(_on_strong_episode_started):
		_wind_controller.strong_episode_started.connect(_on_strong_episode_started)
	_world_bounds = stage_data.paint_world_bounds()
	_build_visuals(schedule_seed)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		_on_settings_changed(game_state.settings)


## Returns copies of the current per-instance visual positions for
## deterministic contracts without exposing the mutable multimesh resource.
func instance_positions_read_only() -> Array[Vector3]:
	return _positions.duplicate()


func _physics_process(delta: float) -> void:
	if not visible or _multimesh == null or _wind_controller == null or _terrain_surface == null:
		return
	var snapshot := _wind_controller.current_snapshot()
	if snapshot == null:
		return
	_visual_time += delta
	_gust_cue_remaining = maxf(0.0, _gust_cue_remaining - delta)
	var direction := snapshot.push_direction()
	var travel_speed := lerpf(0.35, 3.4, snapshot.normalized_strength)
	var gust_weight := _gust_cue_remaining / GUST_CUE_SECONDS
	travel_speed *= 1.0 + gust_weight * 0.75
	for index in range(_positions.size()):
		var phase := _phases[index]
		var lateral := Vector3(-direction.z, 0.0, direction.x) \
				* sin(_visual_time * 1.7 + phase) * 0.18
		_positions[index] += (direction * travel_speed + lateral) * delta
		_positions[index] = _wrap_position(_positions[index])
		var world_xz := Vector2(_positions[index].x, _positions[index].z)
		if not _terrain_surface.contains_world_xz(world_xz):
			_positions[index] = _sample_playable_position()
			world_xz = Vector2(_positions[index].x, _positions[index].z)
		var terrain_y := _terrain_surface.world_surface_point(world_xz).y
		_positions[index].y = terrain_y + _height_offsets[index] \
				+ sin(_visual_time * 2.1 + phase) * 0.35
		var yaw := atan2(direction.x, direction.z) + sin(_visual_time * 2.8 + phase) * 0.35
		var flutter := sin(_visual_time * 4.2 + phase) * 0.55
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, flutter)
		basis = basis.scaled(Vector3.ONE * _scales[index] * (1.0 + gust_weight * 0.25))
		_multimesh.set_instance_transform(index, Transform3D(basis, _positions[index]))


func _build_visuals(schedule_seed: int) -> void:
	for child in get_children():
		child.queue_free()
	_positions.clear()
	_visual_time = 0.0
	_height_offsets = PackedFloat32Array()
	_phases = PackedFloat32Array()
	_scales = PackedFloat32Array()
	_placement_random.seed = schedule_seed ^ 0x51A7D3
	var debris_count := clampi(
		roundi(_world_bounds.get_area() / SQUARE_METERS_PER_DEBRIS),
		MIN_DEBRIS_COUNT,
		MAX_DEBRIS_COUNT
	)
	var terrain_scale := clampf(
		maxf(_world_bounds.size.x, _world_bounds.size.y) / 200.0,
		0.85,
		1.25
	)
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = debris_count
	var leaf_mesh := BoxMesh.new()
	# These remain small leaves in world space, but are large enough to read as
	# a pooled wind layer across the game's 180-240 m mountain span.
	leaf_mesh.size = Vector3(0.72, 0.055, 1.55) * terrain_scale
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	leaf_mesh.material = material
	_multimesh.mesh = leaf_mesh
	for index in range(debris_count):
		var position := _sample_playable_position()
		_positions.append(position)
		_height_offsets.append(_placement_random.randf_range(
			MIN_HEIGHT_ABOVE_TERRAIN,
			MIN_HEIGHT_ABOVE_TERRAIN + HEIGHT_SPAN
		))
		_phases.append(_placement_random.randf_range(0.0, TAU))
		_scales.append(_placement_random.randf_range(0.78, 1.28))
		var initial_position := position
		initial_position.y += _height_offsets[index]
		_multimesh.set_instance_transform(
			index,
			Transform3D(
				Basis.IDENTITY.scaled(Vector3.ONE * _scales[index]),
				initial_position
			)
		)
		_multimesh.set_instance_color(
			index,
			Color("A68B55") if index % 3 == 0 else Color("66724B")
		)
	var instance := MultiMeshInstance3D.new()
	instance.name = "WindLeaves"
	instance.multimesh = _multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = 420.0
	instance.custom_aabb = AABB(
		Vector3(_world_bounds.position.x, -20.0, _world_bounds.position.y),
		Vector3(_world_bounds.size.x, 180.0, _world_bounds.size.y)
	)
	add_child(instance)


func _sample_playable_position() -> Vector3:
	# The generated mountain is an irregular footprint within this rectangle.
	# Bias toward its central mass, then reject gaps and support-only space.
	var center := _world_bounds.get_center()
	for _attempt in range(MAX_PLACEMENT_ATTEMPTS):
		var candidate := Vector2(
			_placement_random.randf_range(_world_bounds.position.x, _world_bounds.end.x),
			_placement_random.randf_range(_world_bounds.position.y, _world_bounds.end.y)
		).lerp(center, _placement_random.randf_range(0.10, 0.38))
		if _terrain_surface.contains_world_xz(candidate):
			var surface := _terrain_surface.world_surface_point(candidate)
			return Vector3(candidate.x, surface.y, candidate.y)
	# Every generated stage has playable top cells; retain a safe fallback for a
	# malformed external layout without querying a non-top surface each frame.
	if _terrain_surface.contains_world_xz(center):
		return _terrain_surface.world_surface_point(center)
	for z_index in range(1, 8):
		for x_index in range(1, 10):
			var candidate := _world_bounds.position + Vector2(
				_world_bounds.size.x * float(x_index) / 10.0,
				_world_bounds.size.y * float(z_index) / 8.0
			)
			if _terrain_surface.contains_world_xz(candidate):
				return _terrain_surface.world_surface_point(candidate)
	push_error("WindDebrisField requires at least one playable terrain-top position.")
	return Vector3(center.x, _terrain_surface.global_position.y, center.y)


func _wrap_position(position: Vector3) -> Vector3:
	var wrapped := position
	if wrapped.x < _world_bounds.position.x:
		wrapped.x = _world_bounds.end.x
	elif wrapped.x > _world_bounds.end.x:
		wrapped.x = _world_bounds.position.x
	if wrapped.z < _world_bounds.position.y:
		wrapped.z = _world_bounds.end.y
	elif wrapped.z > _world_bounds.end.y:
		wrapped.z = _world_bounds.position.y
	return wrapped


func _on_settings_changed(settings: Dictionary) -> void:
	visible = not bool(settings.get("reduced_motion", false))


func _on_strong_episode_started(_episode_id: int, _snapshot: WindSnapshot) -> void:
	_gust_cue_remaining = GUST_CUE_SECONDS
