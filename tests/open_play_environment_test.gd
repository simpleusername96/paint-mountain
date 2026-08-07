extends SceneTree

const ENVIRONMENT_SCENE := preload("res://scenes/gameplay/open_play_environment.tscn")

var _failed := false


func _initialize() -> void:
	var environment := ENVIRONMENT_SCENE.instantiate() as OpenPlayEnvironment
	root.add_child(environment)
	environment.configure(PlayBoundsSpec.new(), Rect2(Vector2(-105, -190), Vector2(210, 120)), -2.0)
	_assert(environment.is_configured(), "open environment must configure its apron")
	_assert(environment.get_node_or_null("BackstopWallMesh") == null \
			and environment.get_node_or_null("SideWallLeft") == null \
			and environment.get_node_or_null("SideWallRight") == null, "open environment must contain no rear or side wall")
	var bodies := environment.find_children("*", "StaticBody3D", true, false)
	_assert(bodies.size() == 1 and bodies[0].name == "ApronBody", "the apron must be the only environment collider")
	var apron_body := environment.get_node("ApronBody") as StaticBody3D
	var apron_shape := environment.get_node("ApronBody/ApronShape") as CollisionShape3D
	_assert(apron_body.get_meta(PlayBoundsSpec.CONTACT_OWNER_META, &"") == PlayBoundsSpec.APRON_OWNER_ID, "apron owner identity must be stable")
	_assert(apron_shape.get_meta(PlayBoundsSpec.CONTACT_SHAPE_META, &"") == PlayBoundsSpec.APRON_SHAPE_ID, "apron shape identity must be stable")
	_assert(environment.apron_geometry_read_only().terrain_join_gap <= 0.001, "apron and terrain join must align")
	environment.queue_free()
	if not _failed:
		print("open_play_environment_test passed: apron only, no backstop or side walls")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
