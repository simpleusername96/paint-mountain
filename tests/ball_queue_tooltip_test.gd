extends SceneTree

const BALL_QUEUE_SCENE := preload("res://scenes/ui/components/ball_queue.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	TranslationServer.set_locale("ko")
	var queue := BALL_QUEUE_SCENE.instantiate() as BallQueue
	root.add_child(queue)
	queue.show()
	queue.size = Vector2(420.0, 172.0)
	await process_frame
	var tokens: Array[BallToken] = [
		BallToken.new(BallKind.Value.STANDARD, PaintChannel.Value.RED),
		BallToken.new(BallKind.Value.IMPACT_BURST, PaintChannel.Value.GREEN),
		BallToken.new(BallKind.Value.APEX_SPLIT, PaintChannel.Value.RED),
	]
	queue.configure(tokens)
	await process_frame
	var views := queue.token_views()
	_assert(views.size() == 3, "queue must own current plus next two tokens")
	var card := queue.get_node("DescriptionCard") as Panel
	var description := queue.get_node("DescriptionCard/Description") as Label
	_assert(card != null and description != null, "queue must own one white detail card and its exact copy")
	_assert(queue.find_children("*", "Panel", true, false).size() == 1,
			"queue must contain exactly one white detail-card surface")
	for index in views.size():
		_assert(views[index].token().matches(tokens[index]), "token order must match the authoritative queue at %d" % index)
		_assert(views[index].focus_mode == Control.FOCUS_ALL, "every token must accept native keyboard focus")
		_assert(not views[index].accessibility_name.is_empty(), "every token must expose its full accessible description")
		_assert(views[index].tooltip_text.is_empty(), "native tooltips must not duplicate the shared description")
	_assert("현재" in views[0].description_text(), "first token must be identified as current")
	_assert("계속 칠" in views[0].description_text(), "standard token must explain continuous terrain paint")
	_assert("넓게" in views[1].description_text(), "burst token must explain its wide landing behavior")
	_assert("세 개" in views[2].description_text(), "split token must explain its three-ball behavior")

	views[0].request_description_for_test(false)
	await process_frame
	_assert(queue.description_visible(), "pointer-equivalent request must show the shared description")
	_assert(queue.description_value() == views[0].description_text(), "pointer description must equal the accessible description")
	_assert(card.get_global_rect().size.x >= 280.0,
			"pointer description must keep a readable shared width")
	_assert(card.get_global_rect().position.y >= views[0].get_global_rect().end.y,
			"pointer description must align below the queue tokens")
	_assert((queue.get_node("DescriptionCard/DescriptionIcon") as TextureRect).visible,
			"detail card must lead with the selected ball's visual mark")
	queue.set_compact(true, 2.0)
	await process_frame
	_assert(description.get_theme_font_size(&"font_size") >= 32,
			"canvas-stretched compact description must preserve physical type size")
	_assert(description.get_theme_constant(&"outline_size") == 0,
			"white detail card copy must not use a world-outline treatment")
	_assert(views[0].custom_minimum_size.y >= 104.0,
			"canvas-stretched current token must preserve its physical target")
	views[0].release_description_for_test()
	await create_timer(0.1).timeout
	_assert(not queue.description_visible(), "un-pinned pointer description must dismiss on release")

	views[1].grab_focus()
	await process_frame
	_assert(queue.description_visible(), "keyboard focus must show the same description without hover")
	_assert(queue.description_value() == views[1].description_text(), "focus description must equal the token description")
	views[1].release_focus()
	await create_timer(0.1).timeout
	_assert(not queue.description_visible(), "un-pinned focus description must dismiss on focus exit")

	views[2].request_description_for_test(true)
	views[2].release_description_for_test()
	_assert(queue.description_visible(), "press must pin the shared description")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	queue._unhandled_key_input(cancel)
	_assert(not queue.description_visible(), "Escape must dismiss a pinned description")

	queue.queue_free()
	await process_frame
	if not _failed:
		print("ball_queue_tooltip_test passed: order, hover, focus, press, accessibility, and dismiss")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Ball queue tooltip contract failed: %s" % message)
