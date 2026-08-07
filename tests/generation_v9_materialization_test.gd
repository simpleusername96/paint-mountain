extends SceneTree

var _failed := false


func _initialize() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	var stage := catalog.get_stage(&"stage_01") if catalog != null else null
	_assert(stage != null, "Stage 01 must exist")
	if stage == null:
		quit(1)
		return
	var first := SeededStageGenerator.generate_exact(
		stage.generation_profile,
		StageProgressionData.CANONICAL_TERRAIN_SEED,
		stage
	)
	var repeated := SeededStageGenerator.generate_exact(
		stage.generation_profile,
		StageProgressionData.CANONICAL_TERRAIN_SEED,
		stage
	)
	var baked := load(catalog.get_layout_path(stage.stage_id)) as BakedStageLayoutData
	var persisted := StageLayoutBakeCodec.hydrate(baked, stage)
	_assert(first != null and repeated != null and persisted != null, "exact v9 Stage 01 must materialize")
	if first != null and repeated != null and persisted != null:
		_assert(first.terrain_seed == StageProgressionData.CANONICAL_TERRAIN_SEED, "materialized seed must be canonical")
		_assert(first.checksum == repeated.checksum and first.checksum == persisted.checksum, "height checksum must match repeated and persisted materialization")
		_assert(first.target_mask_checksum == repeated.target_mask_checksum \
				and first.target_mask_checksum == persisted.target_mask_checksum, "target checksum must match persisted data")
		_assert(first.footprint_cells_read_only() == repeated.footprint_cells_read_only() \
				and first.footprint_cells_read_only() == persisted.footprint_cells_read_only(), "footprint must match persisted data")
		_assert(first.play_bounds.checksum() == persisted.play_bounds.checksum(), "open play bounds must materialize identically")
	if not _failed:
		print("generation_v9_materialization_test passed: one exact identity matches persisted Stage 01")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
