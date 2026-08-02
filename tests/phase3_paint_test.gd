extends SceneTree

const PAINT_SHADER := preload("res://src/paint/terrain_paint.gdshader")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var paint_system := PaintSystem.new()
	root.add_child(paint_system)
	var material := ShaderMaterial.new()
	material.shader = PAINT_SHADER
	var bounds := Rect2(Vector2(-90.0, -172.0), Vector2(180.0, 120.0))
	paint_system.configure(0, bounds, -2.0, material)
	_assert_true(paint_system.total_eligible_pixels() > 0, "eligible mask must contain countable terrain")
	_assert_true(paint_system.paint_texture().get_width() == 512, "paint mask must remain 512 pixels wide")
	_assert_true(paint_system.recent_texture().get_width() == 512, "recent-stamp debug view must match mask resolution")
	_assert_true(paint_system.excluded_texture().get_width() == 512, "excluded-mask debug view must match mask resolution")
	_assert_true(material.get_shader_parameter(&"paint_mask") == paint_system.paint_texture(), "terrain shader must use the authoritative mask texture")

	var summit := Vector3(0.0, -2.0 + TerrainMeshFactory.height_at(0, 0.0, 0.0), -112.0)
	paint_system.queue_stamp(&"impact", summit, 4.0, 22.0, false)
	paint_system.flush_pending()
	var first_coverage := paint_system.coverage_percent()
	_assert_true(first_coverage > 0.0, "an eligible impact must increase coverage")

	paint_system.queue_stamp(&"overlap", summit, 4.0, 22.0, false)
	paint_system.flush_pending()
	_assert_true(is_equal_approx(first_coverage, paint_system.coverage_percent()), "overlap must not double-count coverage")

	paint_system.queue_stamp(&"excluded_height", Vector3(0.0, -20.0, -112.0), 8.0, 22.0, false)
	paint_system.flush_pending()
	_assert_true(is_equal_approx(first_coverage, paint_system.coverage_percent()), "off-surface paint must be excluded")

	paint_system.clear()
	var flow_start := Vector3(20.0, -2.0 + TerrainMeshFactory.height_at(0, 20.0, 0.0), -112.0)
	paint_system.queue_stamp(&"direct", flow_start, 0.8, 18.0, false)
	paint_system.flush_pending()
	var direct_coverage := paint_system.coverage_percent()
	paint_system.clear()
	paint_system.queue_stamp(&"flow", flow_start, 0.8, 18.0, true)
	paint_system.flush_pending()
	print("Phase 3 flow probe: direct %.6f%%, with flow %.6f%%." % [direct_coverage, paint_system.coverage_percent()])
	_assert_true(paint_system.pending_work_count() == 0, "finite downhill flow must settle in one bounded batch")
	_assert_true(paint_system.coverage_percent() > direct_coverage, "bounded downhill flow must add a finite route below the impact")

	paint_system.clear()
	_assert_true(is_zero_approx(paint_system.coverage_percent()), "clear must reset authoritative coverage")
	print("Phase 3 paint checks passed: overlap stable at %.4f%%." % first_coverage)
	paint_system.queue_free()
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
