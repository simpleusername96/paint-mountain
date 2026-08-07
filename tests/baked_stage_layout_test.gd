extends SceneTree

var _failed := false


func _initialize() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	var stage := catalog.get_stage(&"stage_01") if catalog != null else null
	var stored := load(catalog.get_layout_path(&"stage_01")) as BakedStageLayoutData if catalog != null else null
	var layout := StageLayoutBakeCodec.hydrate(stored, stage)
	_assert(stored != null and layout != null and layout.is_runtime_ready(), "stored v9 layout must hydrate")
	if stored != null and layout != null:
		var rebaked := StageLayoutBakeCodec.bake(layout, stage)
		_assert(rebaked != null and rebaked.schema_version == 2, "rebaked layout must use schema 2")
		_assert(rebaked.payload_sha256 == stored.payload_sha256, "semantic payload hash must round-trip")
		_assert(rebaked.terrain_seed == StageProgressionData.CANONICAL_TERRAIN_SEED, "baked terrain seed must be canonical")
		_assert(rebaked.play_bounds_checksum == PlayBoundsSpec.new().checksum(), "baked layout must identify open play bounds")
		_assert(rebaked.default_aim_power == stored.default_aim_power \
				and rebaked.summit_aim_power == stored.summit_aim_power, "bounded witness aims must round-trip")
		var corrupt := stored.duplicate(true) as BakedStageLayoutData
		corrupt.height_checksum += 1
		_assert(StageLayoutBakeCodec.hydrate(corrupt, stage) == null, "payload mutation must fail closed")
	if not _failed:
		print("baked_stage_layout_test passed: schema-2 payload, play bounds, witnesses, and fail-closed hash")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
