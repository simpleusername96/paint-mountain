extends SceneTree

const ENVIRONMENT_SCENE := preload("res://scenes/gameplay/backstop_environment.tscn")
const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const TERRAIN_WORLD_BOUNDS := Rect2(Vector2(-90.0, -172.0), Vector2(180.0, 120.0))
const TERRAIN_WORLD_JOIN_Y := -2.0

var _failed := false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var spec := ContainmentSpec.new()
	_assert_spec(spec)
	var geometry := ApronGeometryFactory.build(spec, TERRAIN_WORLD_BOUNDS, TERRAIN_WORLD_JOIN_Y)
	_assert_apron_geometry(spec, geometry)
	await _assert_environment_scene(spec, geometry)
	_assert_gameplay_scene_structure()
	if not _failed:
		print("Containment geometry checks passed: fixed bounds, six-face wall, filled closed apron, collider parity, stable IDs, and gameplay replacement.")
	quit(1 if _failed else 0)


func _assert_spec(spec: ContainmentSpec) -> void:
	_assert_true(spec.is_valid(), "the fixed containment specification must validate")
	_assert_true(spec.containment_bounds == ContainmentSpec.FIXED_CONTAINMENT_BOUNDS, "the containment bounds must remain fixed")
	_assert_true(spec.apron_xz_bounds == ContainmentSpec.FIXED_APRON_XZ_BOUNDS, "the apron XZ bounds must remain fixed")
	_assert_true(is_equal_approx(spec.apron_minimum_y, TERRAIN_WORLD_JOIN_Y), "the apron top and current terrain join must meet at y=-2")
	_assert_true(spec.supports_terrain_join(TERRAIN_WORLD_BOUNDS, TERRAIN_WORLD_JOIN_Y), "the visible terrain edge must match the fixed rear transition")
	_assert_true(not spec.supports_terrain_join(TERRAIN_WORLD_BOUNDS, spec.apron_bottom_y()), "the structural apron bottom cannot serve as the visible terrain join")
	_assert_true(spec.backstop_bounds() == AABB(Vector3(-240.0, -31.0, -176.25), Vector3(480.0, 284.0, 4.0)), "the wall bounds must match its fixed six-face volume")


func _assert_apron_geometry(spec: ContainmentSpec, geometry: ApronGeometry) -> void:
	_assert_true(geometry.is_valid(), "apron geometry must be complete")
	_assert_true(geometry.top_xz_bounds == spec.apron_xz_bounds, "apron top vertices must span the exact fixed XZ bounds")
	_assert_true(is_equal_approx(geometry.minimum_top_y, spec.apron_minimum_y), "no apron top point may fall below the fixed catch height")
	_assert_true(geometry.terrain_join_gap <= spec.maximum_join_gap, "terrain/apron render and collision joins must share the same boundary")
	_assert_filled_top(spec, geometry)
	_assert_true(geometry.total_triangle_count > geometry.top_triangle_count, "the filled apron top must retain side and bottom closure")
	var render_faces: PackedVector3Array = geometry.render_mesh.get_faces()
	var collision_faces: PackedVector3Array = geometry.collision_shape.get_faces()
	_assert_packed_vectors_equal(render_faces, geometry.collision_faces, "render faces must preserve the generated apron faces")
	_assert_packed_vectors_equal(collision_faces, geometry.collision_faces, "collision faces must preserve the generated apron faces")
	_assert_flat_facets(geometry)


func _assert_filled_top(spec: ContainmentSpec, geometry: ApronGeometry) -> void:
	var covered_area := 0.0
	var top_is_at_join := true
	for index in range(0, geometry.top_vertex_count, 3):
		var a := geometry.collision_faces[index]
		var b := geometry.collision_faces[index + 1]
		var c := geometry.collision_faces[index + 2]
		top_is_at_join = top_is_at_join \
				and is_equal_approx(a.y, TERRAIN_WORLD_JOIN_Y) \
				and is_equal_approx(b.y, TERRAIN_WORLD_JOIN_Y) \
				and is_equal_approx(c.y, TERRAIN_WORLD_JOIN_Y)
		covered_area += (b - a).cross(c - a).length() * 0.5
	_assert_true(top_is_at_join, "every apron top face must meet the terrain at y=-2")
	_assert_true(is_equal_approx(covered_area, spec.apron_xz_bounds.get_area()), "apron top faces must fill the complete catch rectangle without a terrain-sized hole")


func _assert_environment_scene(spec: ContainmentSpec, expected_apron: ApronGeometry) -> void:
	var environment := ENVIRONMENT_SCENE.instantiate() as BackstopEnvironment
	root.add_child(environment)
	environment.configure(spec, TERRAIN_WORLD_BOUNDS, TERRAIN_WORLD_JOIN_Y)
	await physics_frame
	await physics_frame
	_assert_true(environment.is_configured(), "the environment must retain its validated configuration")

	var wall_mesh_node := environment.get_node("BackstopWallMesh") as MeshInstance3D
	var wall_mesh := wall_mesh_node.mesh as BoxMesh
	var wall_body := environment.get_node("BackstopBody") as StaticBody3D
	var wall_shape_node := environment.get_node("BackstopBody/BackstopWall") as CollisionShape3D
	var wall_shape := wall_shape_node.shape as BoxShape3D
	_assert_true(wall_mesh != null and wall_mesh.size == spec.backstop_size, "the visible wall must be the fixed BoxMesh")
	_assert_true(wall_mesh != null and wall_mesh.get_faces().size() == 36, "the wall mesh must expose all six box faces")
	_assert_true(wall_shape != null and wall_shape.size == spec.backstop_size, "the wall collider must exactly match the BoxMesh")
	_assert_true(wall_mesh_node.position == spec.backstop_center and wall_body.position == spec.backstop_center, "wall render and collision centers must match")
	_assert_contact_contract(wall_body, wall_shape_node, ContainmentSpec.BACKSTOP_OWNER_ID, ContainmentSpec.BACKSTOP_SHAPE_ID, spec)
	_assert_side_wall(environment, "SideWallLeft", -1, ContainmentSpec.SIDE_WALL_LEFT_SHAPE_ID, spec)
	_assert_side_wall(environment, "SideWallRight", 1, ContainmentSpec.SIDE_WALL_RIGHT_SHAPE_ID, spec)

	var apron_mesh_node := environment.get_node("ApronMesh") as MeshInstance3D
	var apron_body := environment.get_node("ApronBody") as StaticBody3D
	var apron_shape_node := environment.get_node("ApronBody/ApronShape") as CollisionShape3D
	_assert_true(apron_mesh_node.mesh is ArrayMesh and apron_shape_node.shape is ConcavePolygonShape3D, "the apron must have visible and collidable faceted geometry")
	_assert_packed_vectors_equal(apron_mesh_node.mesh.get_faces(), expected_apron.collision_faces, "scene apron render must match the pure geometry")
	_assert_packed_vectors_equal((apron_shape_node.shape as ConcavePolygonShape3D).get_faces(), expected_apron.collision_faces, "scene apron collider must match the pure geometry")
	_assert_contact_contract(apron_body, apron_shape_node, ContainmentSpec.APRON_OWNER_ID, ContainmentSpec.APRON_SHAPE_ID, spec)

	var wall_hit := _raycast(Vector3(0.0, 111.0, -160.0), Vector3(0.0, 111.0, -180.0))
	_assert_true(wall_hit.get("collider") == wall_body, "a frontal wall ray must hit the real BackstopBody")
	var wall_normal := wall_hit.get("normal", Vector3.ZERO) as Vector3
	_assert_true(wall_normal.angle_to(Vector3.BACK) <= deg_to_rad(0.1), "the wall front normal must point world +Z")
	var apron_hit := _raycast(Vector3(200.0, 20.0, -100.0), Vector3(200.0, -40.0, -100.0))
	_assert_true(apron_hit.get("collider") == apron_body, "an off-terrain downward ray must hit the visible apron collider")
	var terrain_center := TERRAIN_WORLD_BOUNDS.get_center()
	var filled_top_hit := _raycast(
		Vector3(terrain_center.x, 20.0, terrain_center.y),
		Vector3(terrain_center.x, -40.0, terrain_center.y)
	)
	_assert_true(filled_top_hit.get("collider") == apron_body, "a downward ray inside the terrain footprint must hit the filled apron top")
	environment.queue_free()
	await physics_frame


func _assert_gameplay_scene_structure() -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	_assert_true(gameplay.get_node_or_null("Ground") == null, "the legacy flat Ground mesh must be removed")
	_assert_true(gameplay.get_node_or_null("GroundBody") == null, "the legacy flat GroundBody collider must be removed")
	var environment := gameplay.get_node_or_null("BackstopEnvironment") as BackstopEnvironment
	_assert_true(environment != null and environment.visible, "gameplay must contain the visible BackstopEnvironment replacement")
	_assert_true(environment != null and environment.get_node_or_null("BackstopWallMesh") is MeshInstance3D, "the gameplay wall collider must have a visible mesh peer")
	_assert_true(environment != null and environment.get_node_or_null("ApronMesh") is MeshInstance3D, "the gameplay apron collider must have a visible mesh peer")
	gameplay.free()


func _assert_contact_contract(
		body: StaticBody3D,
		shape: CollisionShape3D,
		owner_id: StringName,
		shape_id: StringName,
		spec: ContainmentSpec
) -> void:
	_assert_true(body.collision_layer == spec.collision_layer and body.collision_mask == spec.collision_mask, "%s must use collision layer/mask 1/2" % owner_id)
	_assert_true(body.get_meta(ContainmentSpec.CONTACT_OWNER_META, &"") == owner_id, "%s must expose its stable owner metadata" % owner_id)
	_assert_true(shape.get_meta(ContainmentSpec.CONTACT_SHAPE_META, &"") == shape_id, "%s must expose its stable shape metadata" % shape_id)


func _assert_side_wall(
		environment: BackstopEnvironment,
		shape_name: String,
		side: int,
		shape_id: StringName,
		spec: ContainmentSpec
) -> void:
	var mesh_node := environment.get_node("%sMesh" % shape_name) as MeshInstance3D
	var body := environment.get_node("%sBody" % shape_name) as StaticBody3D
	var shape_node := environment.get_node("%sBody/%s" % [shape_name, shape_name]) as CollisionShape3D
	var mesh := mesh_node.mesh as BoxMesh
	var shape := shape_node.shape as BoxShape3D
	_assert_true(mesh != null and mesh.size == spec.side_wall_size(), "%s mesh must match the fixed side-wall size" % shape_name)
	_assert_true(shape != null and shape.size == spec.side_wall_size(), "%s collider must match the side-wall mesh" % shape_name)
	_assert_true(mesh_node.position == spec.side_wall_center(side) and body.position == spec.side_wall_center(side), "%s render and collision centers must match" % shape_name)
	_assert_contact_contract(body, shape_node, ContainmentSpec.SIDE_WALL_OWNER_ID, shape_id, spec)


func _assert_flat_facets(geometry: ApronGeometry) -> void:
	var arrays := geometry.render_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	_assert_true(vertices.size() == normals.size(), "every apron render vertex must have a normal")
	for index in range(0, vertices.size(), 3):
		var measured := (vertices[index + 1] - vertices[index]).cross(vertices[index + 2] - vertices[index]).normalized()
		_assert_true(measured.length_squared() > 0.99, "apron triangles must not be degenerate")
		_assert_true(normals[index].is_equal_approx(normals[index + 1]) and normals[index].is_equal_approx(normals[index + 2]), "each apron triangle must use one flat facet normal")
		_assert_true(normals[index].dot(measured) >= 0.9999, "stored apron normals must match triangle winding")


func _assert_packed_vectors_equal(actual: PackedVector3Array, expected: PackedVector3Array, message: String) -> void:
	if actual.size() != expected.size():
		_assert_true(false, "%s: size %d != %d" % [message, actual.size(), expected.size()])
		return
	for index in range(actual.size()):
		if not actual[index].is_equal_approx(expected[index]):
			_assert_true(false, "%s: vertex %d differs" % [message, index])
			return


func _raycast(start: Vector3, finish: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, finish, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return root.get_world_3d().direct_space_state.intersect_ray(query)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Containment geometry check failed: %s" % message)
