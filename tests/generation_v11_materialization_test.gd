extends SceneTree

const V10_ROOT := "res://resources/generated_stage_catalogs/v10-fe93d0ac68c6fd877b65f8e53e980dcb455aeb4408576ef9e8dbb0308a1d3f01"

var _failed := false


func _initialize() -> void:
	var previous := load("%s/catalog.tres" % V10_ROOT) as StageCatalogData
	var current := load("res://resources/stages/catalog.tres") as StageCatalogData
	_assert(previous != null and current != null, "v10 source and v11 catalog must load")
	if previous == null or current == null:
		quit(1)
		return
	# v10 text resources omitted values equal to their then-default version, so
	# the immutable root and baked payload versions carry the migration identity.
	_assert(current.catalog_version == 11,
		"the active catalog must identify v11")
	_assert(current.is_valid(), "v11 catalog and content-addressed bundle must validate")
	_assert(previous.stages.size() == 30 and current.stages.size() == 30,
		"both catalog generations must contain thirty stages")
	for index in range(mini(previous.stages.size(), current.stages.size())):
		_compare_stage(index, previous, current)
	if not _failed:
		print("Generation v11 migration passed: v10 terrain/layout bytes remain semantically identical and all active stages use target-band rules.")
	quit(1 if _failed else 0)


func _compare_stage(index: int, previous: StageCatalogData, current: StageCatalogData) -> void:
	var stage_id := "stage_%02d" % (index + 1)
	var old_stage := previous.stages[index]
	var new_stage := current.stages[index]
	var old_layout := load("%s/layouts/%s_layout.res" % [V10_ROOT, stage_id]) as BakedStageLayoutData
	var new_layout := load(current.layout_paths[index]) as BakedStageLayoutData
	_assert(old_stage != null and new_stage != null and old_layout != null and new_layout != null,
		"%s resources must load" % stage_id)
	if old_stage == null or new_stage == null or old_layout == null or new_layout == null:
		return
	_assert(old_layout.profile_version == 10 and old_layout.layout_version == 10 \
			and new_stage.stage_version == 11,
		"%s baked contract must advance exactly once" % stage_id)
	_assert(new_stage.uses_target_band() and new_stage.has_valid_rule_contract(),
		"%s must use the valid all-stage target-band rule" % stage_id)
	_assert(old_stage.terrain_seed == new_stage.terrain_seed \
			and old_stage.terrain_center == new_stage.terrain_center \
			and old_stage.terrain_size == new_stage.terrain_size \
			and old_stage.cannon_transform == new_stage.cannon_transform \
			and old_stage.mechanism_loadout.size() == new_stage.mechanism_loadout.size(),
		"%s world identity and mechanisms must be preserved" % stage_id)
	_assert(_layout_content_matches(old_layout, new_layout),
		"%s migrated layout content must preserve v10 geometry and witnesses" % stage_id)
	_assert(new_layout.profile_version == 11 and new_layout.layout_version == 11 \
			and String(new_layout.profile_id).ends_with("_v11") \
			and new_layout.payload_sha256 == StageLayoutBakeCodec.payload_sha256(new_layout),
		"%s v11 payload identity must be reproducible" % stage_id)
	_assert(StageLayoutBakeCodec.hydrate(new_layout, new_stage) != null,
		"%s v11 layout must hydrate against its target-band stage" % stage_id)


func _layout_content_matches(old: BakedStageLayoutData, current: BakedStageLayoutData) -> bool:
	return old.terrain_seed == current.terrain_seed \
			and old.cell_count == current.cell_count \
			and old.local_bounds == current.local_bounds \
			and old.heights == current.heights \
			and old.footprint == current.footprint \
			and old.height_checksum == current.height_checksum \
			and old.target_mask == current.target_mask \
			and old.target_checksum == current.target_checksum \
			and old.coverage_metric_version == current.coverage_metric_version \
			and is_equal_approx(old.total_target_surface_area, current.total_target_surface_area) \
			and old.target_surface_area_checksum == current.target_surface_area_checksum \
			and old.route_node_ids == current.route_node_ids \
			and old.route_node_positions == current.route_node_positions \
			and old.route_edge_ids == current.route_edge_ids \
			and old.route_edge_from_ids == current.route_edge_from_ids \
			and old.route_edge_to_ids == current.route_edge_to_ids \
			and old.play_bounds_checksum == current.play_bounds_checksum \
			and old.mechanism_anchor_ids == current.mechanism_anchor_ids \
			and old.mechanism_transforms == current.mechanism_transforms \
			and old.placement_checksum == current.placement_checksum \
			and old.decoration_model_ids == current.decoration_model_ids \
			and old.decoration_local_xz == current.decoration_local_xz \
			and old.default_aim_yaw == current.default_aim_yaw \
			and old.default_aim_elevation == current.default_aim_elevation \
			and old.default_aim_power == current.default_aim_power \
			and old.summit_aim_yaw == current.summit_aim_yaw \
			and old.summit_aim_elevation == current.summit_aim_elevation \
			and old.summit_aim_power == current.summit_aim_power


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Generation v11 materialization failed: %s" % message)
