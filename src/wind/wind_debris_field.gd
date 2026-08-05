class_name WindDebrisField
extends Node3D

const DEBRIS_COUNT := 24
const MIN_HEIGHT_ABOVE_TERRAIN := 1.5
const HEIGHT_SPAN := 7.0

var _terrain_surface: TerrainSurface
var _wind_controller: WindController
var _world_bounds := Rect2()
var _positions: Array[Vector3] = []
var _height_offsets := PackedFloat32Array()
var _phases := PackedFloat32Array()
var _multimesh: MultiMesh
var _visual_time := 0.0


func configure(
		stage_data: StageData,
		terrain_surface: TerrainSurface,
		wind_controller: WindController,
		schedule_seed: int
) -> void:
	assert(stage_data != null and terrain_surface != null and wind_controller != null)
	_terrain_surface = terrain_surface
	_wind_controller = wind_controller
	_world_bounds = stage_data.paint_world_bounds()
	_build_visuals(schedule_seed)


func _process(delta: float) -> void:
	if _multimesh == null or _wind_controller == null or _terrain_surface == null:
		return
	var snapshot := _wind_controller.current_snapshot()
	if snapshot == null:
		return
	_visual_time += delta
	var direction := snapshot.push_direction()
	var travel_speed := lerpf(0.35, 3.4, snapshot.normalized_strength)
	for index in range(_positions.size()):
		var phase := _phases[index]
		var lateral := Vector3(-direction.z, 0.0, direction.x) \
				* sin(_visual_time * 1.7 + phase) * 0.18
		_positions[index] += (direction * travel_speed + lateral) * delta
		_positions[index] = _wrap_position(_positions[index])
		var world_xz := Vector2(_positions[index].x, _positions[index].z)
		var terrain_y := _terrain_surface.world_surface_point(world_xz).y
		_positions[index].y = terrain_y + _height_offsets[index] \
				+ sin(_visual_time * 2.1 + phase) * 0.35
		var yaw := atan2(direction.x, direction.z) + sin(_visual_time * 2.8 + phase) * 0.35
		var flutter := sin(_visual_time * 4.2 + phase) * 0.55
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, flutter)
		_multimesh.set_instance_transform(index, Transform3D(basis, _positions[index]))


func _build_visuals(schedule_seed: int) -> void:
	for child in get_children():
		child.queue_free()
	_positions.clear()
	_visual_time = 0.0
	_height_offsets = PackedFloat32Array()
	_phases = PackedFloat32Array()
	var random := RandomNumberGenerator.new()
	random.seed = schedule_seed ^ 0x51A7D3
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = DEBRIS_COUNT
	var leaf_mesh := BoxMesh.new()
	leaf_mesh.size = Vector3(0.22, 0.035, 0.42)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	leaf_mesh.material = material
	_multimesh.mesh = leaf_mesh
	for index in range(DEBRIS_COUNT):
		var position := Vector3(
			random.randf_range(_world_bounds.position.x, _world_bounds.end.x),
			0.0,
			random.randf_range(_world_bounds.position.y, _world_bounds.end.y)
		)
		_positions.append(position)
		_height_offsets.append(random.randf_range(
			MIN_HEIGHT_ABOVE_TERRAIN,
			MIN_HEIGHT_ABOVE_TERRAIN + HEIGHT_SPAN
		))
		_phases.append(random.randf_range(0.0, TAU))
		_multimesh.set_instance_color(
			index,
			Color("A68B55") if index % 3 == 0 else Color("66724B")
		)
	var instance := MultiMeshInstance3D.new()
	instance.name = "WindLeaves"
	instance.multimesh = _multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = 280.0
	instance.custom_aabb = AABB(
		Vector3(_world_bounds.position.x, -20.0, _world_bounds.position.y),
		Vector3(_world_bounds.size.x, 180.0, _world_bounds.size.y)
	)
	add_child(instance)


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
