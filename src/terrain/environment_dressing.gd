class_name EnvironmentDressing
extends Node3D

const MODEL_PATHS := {
	&"tree_pineSmallA": "res://assets/nature/kenney/tree_pineSmallA.glb",
	&"tree_pineSmallB": "res://assets/nature/kenney/tree_pineSmallB.glb",
	&"tree_pineTallA": "res://assets/nature/kenney/tree_pineTallA.glb",
	&"rock_smallA": "res://assets/nature/kenney/rock_smallA.glb",
	&"rock_largeA": "res://assets/nature/kenney/rock_largeA.glb",
}

var _stage_data: StageData
var _generated_layout: GeneratedStageLayout


func configure(stage_data: StageData, generated_layout: GeneratedStageLayout = null) -> void:
	_stage_data = stage_data
	_generated_layout = generated_layout
	for child in get_children():
		child.queue_free()
	for placement in _generated_layout.decoration_placements:
		_add_decoration(placement)
	_add_summit_flag()


func _add_decoration(placement: DecorationPlacement) -> void:
	var packed_scene := load(String(MODEL_PATHS.get(placement.model_id, ""))) as PackedScene
	assert(packed_scene != null, "Approved decoration model must import as a PackedScene.")
	var decoration := packed_scene.instantiate() as Node3D
	decoration.name = String(placement.model_id)
	var height := _height_at(placement.local_xz.x, placement.local_xz.y)
	decoration.position = Vector3(
		_stage_data.terrain_center.x + placement.local_xz.x,
		_stage_data.terrain_center.y + height,
		_stage_data.terrain_center.z + placement.local_xz.y
	)
	decoration.rotation.y = deg_to_rad(placement.yaw_degrees)
	decoration.scale = Vector3.ONE * placement.uniform_scale
	_apply_muted_material(decoration, String(placement.model_id).begins_with("tree_"))
	add_child(decoration)


func _apply_muted_material(node: Node, is_tree: bool) -> void:
	var material := _material(Color("59636d") if is_tree else Color("747b82"), 0.94)
	for child in node.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = material
		_apply_muted_material(child, is_tree)


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
