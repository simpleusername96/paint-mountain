class_name EnvironmentDressing
extends Node3D

const TREE_POSITIONS: Array[Vector2] = [
	Vector2(-72, 24), Vector2(-63, -18), Vector2(-50, 8), Vector2(-39, 34),
	Vector2(-26, -33), Vector2(-10, 29), Vector2(19, 34), Vector2(34, -31),
	Vector2(48, 12), Vector2(59, -19), Vector2(69, 28), Vector2(76, -36),
]

var _stage_data: StageData
var _generated_layout: GeneratedStageLayout


func configure(stage_data: StageData, generated_layout: GeneratedStageLayout = null) -> void:
	_stage_data = stage_data
	_generated_layout = generated_layout
	for child in get_children():
		child.queue_free()
	for index in range(TREE_POSITIONS.size()):
		_add_tree(TREE_POSITIONS[index], 0.78 + float(index % 4) * 0.1)
	_add_summit_flag()


func _add_tree(local_xz: Vector2, scale_factor: float) -> void:
	var tree := Node3D.new()
	tree.name = "Pine"
	var height := _height_at(local_xz.x, local_xz.y)
	tree.position = Vector3(
		_stage_data.terrain_center.x + local_xz.x,
		_stage_data.terrain_center.y + height,
		_stage_data.terrain_center.z + local_xz.y
	)
	tree.scale = Vector3.ONE * scale_factor
	add_child(tree)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.32
	trunk_mesh.height = 2.3
	trunk_mesh.radial_segments = 6
	trunk_mesh.material = _material(Color(0.25, 0.21, 0.18, 1.0), 1.0)
	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.15
	tree.add_child(trunk)
	for layer in range(3):
		var foliage_mesh := CylinderMesh.new()
		foliage_mesh.top_radius = 0.0
		foliage_mesh.bottom_radius = 1.55 - float(layer) * 0.27
		foliage_mesh.height = 2.8
		foliage_mesh.radial_segments = 7
		foliage_mesh.material = _material(Color(0.2 + float(layer) * 0.018, 0.27 + float(layer) * 0.018, 0.29, 1.0), 0.96)
		var foliage := MeshInstance3D.new()
		foliage.mesh = foliage_mesh
		foliage.position.y = 2.35 + float(layer) * 1.15
		tree.add_child(foliage)


func _add_summit_flag() -> void:
	var summit_xz := Vector2.ZERO
	var summit_height := -INF
	for z in range(-46, 47, 8):
		for x in range(-76, 77, 8):
			var height := _height_at(float(x), float(z))
			if height > summit_height:
				summit_height = height
				summit_xz = Vector2(float(x), float(z))
	var flag_root := Node3D.new()
	flag_root.name = "SummitFlag"
	flag_root.position = Vector3(
		_stage_data.terrain_center.x + summit_xz.x,
		_stage_data.terrain_center.y + summit_height,
		_stage_data.terrain_center.z + summit_xz.y
	)
	add_child(flag_root)
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.09
	pole_mesh.bottom_radius = 0.12
	pole_mesh.height = 6.5
	pole_mesh.radial_segments = 8
	pole_mesh.material = _material(Color(0.84, 0.87, 0.9, 1.0), 0.55)
	var pole := MeshInstance3D.new()
	pole.mesh = pole_mesh
	pole.position.y = 3.25
	flag_root.add_child(pole)
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(3.2, 1.55, 0.1)
	flag_mesh.material = _material(_stage_data.paint_color, 0.34)
	var flag := MeshInstance3D.new()
	flag.mesh = flag_mesh
	flag.position = Vector3(1.6, 5.15, 0.0)
	flag_root.add_child(flag)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result


func _height_at(local_x: float, local_z: float) -> float:
	assert(_generated_layout != null, "Environment dressing requires the accepted generated layout.")
	return _generated_layout.height_at_local(local_x, local_z)
