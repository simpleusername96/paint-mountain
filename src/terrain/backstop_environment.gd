class_name BackstopEnvironment
extends Node3D

const NORMAL_TERRAIN_PHYSICS_MATERIAL := preload(
	"res://resources/physics/normal_terrain_physics_material.tres"
)

var containment_spec: ContainmentSpec:
	get:
		return _containment_spec

var _containment_spec: ContainmentSpec
var _apron_geometry: ApronGeometry


func configure(
		spec: ContainmentSpec,
		terrain_world_bounds: Rect2,
		terrain_world_join_y: float
) -> void:
	assert(spec != null and spec.is_valid(), "BackstopEnvironment requires a valid containment specification.")
	var backstop_mesh := get_node_or_null("BackstopWallMesh") as MeshInstance3D
	var backstop_body := get_node_or_null("BackstopBody") as StaticBody3D
	var backstop_shape_node := get_node_or_null("BackstopBody/BackstopWall") as CollisionShape3D
	var side_left_mesh := get_node_or_null("SideWallLeftMesh") as MeshInstance3D
	var side_left_body := get_node_or_null("SideWallLeftBody") as StaticBody3D
	var side_left_shape := get_node_or_null("SideWallLeftBody/SideWallLeft") as CollisionShape3D
	var side_right_mesh := get_node_or_null("SideWallRightMesh") as MeshInstance3D
	var side_right_body := get_node_or_null("SideWallRightBody") as StaticBody3D
	var side_right_shape := get_node_or_null("SideWallRightBody/SideWallRight") as CollisionShape3D
	var apron_mesh := get_node_or_null("ApronMesh") as MeshInstance3D
	var apron_body := get_node_or_null("ApronBody") as StaticBody3D
	var apron_shape_node := get_node_or_null("ApronBody/ApronShape") as CollisionShape3D
	assert(backstop_mesh != null and backstop_body != null and backstop_shape_node != null, "Backstop wall nodes are missing.")
	assert(side_left_mesh != null and side_left_body != null and side_left_shape != null \
			and side_right_mesh != null and side_right_body != null and side_right_shape != null, \
			"Side containment wall nodes are missing.")
	assert(apron_mesh != null and apron_body != null and apron_shape_node != null, "Apron nodes are missing.")

	_containment_spec = spec
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = spec.backstop_size
	var wall_shape := BoxShape3D.new()
	wall_shape.size = spec.backstop_size
	backstop_mesh.mesh = wall_mesh
	backstop_mesh.position = spec.backstop_center
	backstop_body.position = spec.backstop_center
	backstop_shape_node.shape = wall_shape
	_configure_contact_identity(
		backstop_body,
		backstop_shape_node,
		ContainmentSpec.BACKSTOP_OWNER_ID,
		ContainmentSpec.BACKSTOP_SHAPE_ID
	)
	_configure_side_wall(
		side_left_mesh,
		side_left_body,
		side_left_shape,
		-1,
		ContainmentSpec.SIDE_WALL_LEFT_SHAPE_ID
	)
	_configure_side_wall(
		side_right_mesh,
		side_right_body,
		side_right_shape,
		1,
		ContainmentSpec.SIDE_WALL_RIGHT_SHAPE_ID
	)

	_apron_geometry = ApronGeometryFactory.build(
		spec,
		terrain_world_bounds,
		terrain_world_join_y
	)
	apron_mesh.mesh = _apron_geometry.render_mesh
	apron_shape_node.shape = _apron_geometry.collision_shape
	_configure_contact_identity(
		apron_body,
		apron_shape_node,
		ContainmentSpec.APRON_OWNER_ID,
		ContainmentSpec.APRON_SHAPE_ID
	)
	apron_body.physics_material_override = NORMAL_TERRAIN_PHYSICS_MATERIAL


func is_configured() -> bool:
	return _containment_spec != null and _containment_spec.is_valid() \
			and _apron_geometry != null and _apron_geometry.is_valid()


func apron_geometry_read_only() -> ApronGeometry:
	return _apron_geometry


func _configure_contact_identity(
		body: StaticBody3D,
		shape: CollisionShape3D,
		owner_id: StringName,
		shape_id: StringName
) -> void:
	body.collision_layer = _containment_spec.collision_layer
	body.collision_mask = _containment_spec.collision_mask
	body.set_meta(ContainmentSpec.CONTACT_OWNER_META, owner_id)
	shape.set_meta(ContainmentSpec.CONTACT_SHAPE_META, shape_id)


func _configure_side_wall(
	mesh_node: MeshInstance3D,
	body: StaticBody3D,
	shape_node: CollisionShape3D,
	side: int,
	shape_id: StringName
) -> void:
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = _containment_spec.side_wall_size()
	mesh_node.mesh = wall_mesh
	mesh_node.position = _containment_spec.side_wall_center(side)
	var wall_shape := BoxShape3D.new()
	wall_shape.size = _containment_spec.side_wall_size()
	shape_node.shape = wall_shape
	body.position = _containment_spec.side_wall_center(side)
	_configure_contact_identity(
		body,
		shape_node,
		ContainmentSpec.SIDE_WALL_OWNER_ID,
		shape_id
	)
