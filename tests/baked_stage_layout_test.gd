extends SceneTree

const SAVED_FIXTURE_PATH := "user://baked_stage_layout_test.res"

var _failed := false

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var stage := StageData.new()
	stage.stage_id = &"terrain_test_fixture"
	stage.generation_profile = StageGenerationProfile.new()
	stage.generation_profile.profile_id = &"terrain_test_fixture"
	stage.generation_profile.generation_contract = StageGenerationContract.new()
	var layout := TerrainTestFixtureFactory.build_layout(TerrainTestFixtureFactory.Kind.FACETED)
	stage.terrain_seed = layout.terrain_seed
	layout.checksum = _height_checksum(layout.heights)
	layout.candidate_index = 7
	layout.generation_attempt = 2
	var target_mask := PackedByteArray()
	target_mask.resize(StageGenerationContract.REQUIRED_MASK_SIZE * StageGenerationContract.REQUIRED_MASK_SIZE)
	target_mask.fill(255)
	_assert(layout.install_target_mask(target_mask, TargetMaskRasterizer.byte_checksum(target_mask)), "fixture target mask must install")
	layout.generated_default_witness = _target_witness(layout)
	layout.generated_summit_witness = _summit_witness(layout)
	var burst := load("res://resources/mechanisms/burst_node.tres") as MechanismData
	stage.mechanism_loadout = [
		burst.duplicate(true) as MechanismData,
		burst.duplicate(true) as MechanismData,
	]
	for loadout_index in range(stage.mechanism_loadout.size()):
		var placement := MechanismPlacement.new()
		placement.mechanism_data = stage.mechanism_loadout[loadout_index]
		placement.anchor_id = StringName("duplicate_burst_%d" % loadout_index)
		placement.local_xz = Vector2(float(loadout_index), 0.0)
		placement.local_transform.origin = Vector3(float(loadout_index), 1.0, 0.0)
		layout.mechanism_placements.append(placement)
	layout.decoration_placements.append(DecorationPlacement.new(&"rock_smallA", Vector2(3.0, -2.0), 15.0, 0.8))
	var baked := StageLayoutBakeCodec.bake(layout, stage)
	_assert(baked != null, "valid primitive layout must bake")
	if baked != null:
		_assert(
			ResourceSaver.save(baked, SAVED_FIXTURE_PATH, ResourceSaver.FLAG_COMPRESS) == OK,
			"the primitive artifact must save as a compressed binary resource"
		)
		var reloaded := ResourceLoader.load(
			SAVED_FIXTURE_PATH,
			"",
			ResourceLoader.CACHE_MODE_REPLACE
		) as BakedStageLayoutData
		_assert(reloaded != null, "the saved primitive artifact must reload")
		var hydrated := StageLayoutBakeCodec.hydrate(reloaded, stage)
		_assert(hydrated != null, "semantic payload must hydrate")
		if hydrated != null:
			_assert(hydrated.heights == layout.heights, "height array must round-trip exactly")
			_assert(
				is_equal_approx(
					float(hydrated.metrics.get("maximum_height", -INF)),
					_maximum_height(layout.heights)
				),
				"runtime maximum height must be derived from the baked height grid"
			)
			_assert(hydrated.target_mask == layout.target_mask, "target mask must round-trip exactly")
			_assert(hydrated.checksum == layout.checksum and hydrated.target_mask_checksum == layout.target_mask_checksum, "core checksums must round-trip")
			_assert(hydrated.placement_checksum() == layout.placement_checksum(), "placement checksum must round-trip")
			_assert(
				hydrated.mechanism_placements.size() == 2 \
						and hydrated.mechanism_placements[0].mechanism_data \
								== stage.mechanism_loadout[0] \
						and hydrated.mechanism_placements[1].mechanism_data \
								== stage.mechanism_loadout[1],
				"duplicate mechanism kinds must retain their positional loadout identity"
			)
			_assert(hydrated.containment.checksum() == layout.containment.checksum(), "containment checksum must round-trip")
			_assert(hydrated.route_graph.nodes.size() == layout.route_graph.nodes.size() and hydrated.route_graph.edges.size() == layout.route_graph.edges.size(), "route graph must round-trip")
			_assert(hydrated.generated_default_witness.aim.is_equal_to(layout.generated_default_witness.aim), "default witness tuple must round-trip")
			_assert(hydrated.generated_summit_witness.aim.is_equal_to(layout.generated_summit_witness.aim), "summit witness tuple must round-trip")
			_assert(hydrated.candidate_index == 7 and hydrated.generation_attempt == 2, "candidate index must remain distinct from generation attempt")
			_assert(hydrated.decoration_placements.size() == 1, "decorations must round-trip")
			var runtime_copy := hydrated.copy_for_runtime()
			_assert(runtime_copy != null, "runtime copy requires both witnesses")
			if runtime_copy != null:
				runtime_copy.heights[0] += 1.0
				_assert(runtime_copy.heights[0] != hydrated.heights[0], "runtime height data must be isolated")
				runtime_copy.generated_default_witness.target_local_point.x += 1.0
				_assert(
					runtime_copy.generated_default_witness.target_local_point \
							!= hydrated.generated_default_witness.target_local_point,
					"runtime witness data must be isolated"
				)
		var original_hash := baked.payload_sha256
		baked.height_checksum ^= 1
		_assert(StageLayoutBakeCodec.hydrate(baked, stage) == null, "corrupt semantic payload must fail closed")
		baked.height_checksum ^= 1
		_assert(baked.payload_sha256 == original_hash, "test corruption must not rewrite the stored hash")
		var topology_cell := baked.default_predicted_cell
		baked.default_predicted_cell = Vector2i(topology_cell.x + 1, topology_cell.y)
		baked.payload_sha256 = StageLayoutBakeCodec.payload_sha256(baked)
		_assert(StageLayoutBakeCodec.hydrate(baked, stage) == null, "witness topology corruption must fail closed")
		baked.default_predicted_cell = topology_cell
		var original_impact := baked.default_predicted_local_impact
		baked.default_predicted_local_impact.x = INF
		_assert(StageLayoutBakeCodec.payload_sha256(baked).is_empty(), "non-finite payload must not receive a usable hash")
		baked.default_predicted_local_impact = original_impact
		baked.payload_sha256 = StageLayoutBakeCodec.payload_sha256(baked)
		var original_loadout_index := baked.mechanism_loadout_indices[0]
		baked.mechanism_loadout_indices[0] = 1
		baked.payload_sha256 = StageLayoutBakeCodec.payload_sha256(baked)
		_assert(
			StageLayoutBakeCodec.hydrate(baked, stage) == null,
			"duplicate or reordered mechanism loadout indices must fail closed"
		)
		baked.mechanism_loadout_indices[0] = original_loadout_index
		baked.payload_sha256 = StageLayoutBakeCodec.payload_sha256(baked)
		stage.reachability_certificate = DirectReachabilityCertificate.new()
		_assert(StageLayoutBakeCodec.hydrate(baked, stage) == null, "present invalid certificate must fail closed")
	stage.reachability_certificate = null
	_assert_catalog_paths()
	var saved_fixture_absolute := ProjectSettings.globalize_path(SAVED_FIXTURE_PATH)
	if FileAccess.file_exists(saved_fixture_absolute):
		DirAccess.remove_absolute(saved_fixture_absolute)
	quit(1 if _failed else 0)

func _target_witness(layout: GeneratedStageLayout) -> StageEntryAimWitness:
	var sample := layout.target_sample_nearest_centroid()
	return _witness(layout, sample, int(sample.target_pixel_index), 0)

func _summit_witness(layout: GeneratedStageLayout) -> StageEntryAimWitness:
	var summit := layout.summit_sample()
	var sample := layout.surface_sample_at_local((summit.point as Vector3).x, (summit.point as Vector3).z, false)
	return _witness(layout, sample, -1, layout.summit_region_checksum())

func _witness(layout: GeneratedStageLayout, sample: Dictionary, pixel: int, summit_checksum: int) -> StageEntryAimWitness:
	var witness := StageEntryAimWitness.new()
	witness.aim = AimTuple.new(0.0, 38.0, 68)
	var identity := TrajectoryHitIdentity.terrain_top(&"TerrainTopShape", 0, sample.cell, int(sample.triangle), sample.barycentric)
	witness.predicted_identity = identity
	witness.physical_identity = identity
	witness.predicted_local_impact = sample.point
	witness.physical_local_impact = sample.point
	witness.target_local_point = sample.point
	witness.target_pixel_index = pixel
	witness.summit_region_checksum = summit_checksum
	witness.distance_margin = 0.0
	witness.range_margin = 0.0
	witness.height_margin = 0.0
	return witness

func _assert_catalog_paths() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	_assert(catalog != null, "catalog data must load")
	if catalog == null: return
	var paths: Array[String] = []
	for item in catalog.ordered_stages(): paths.append("%s/layouts/%s_layout.res" % [StageCatalogData.generated_bundle_root(catalog.manifest_sha256), item.stage_id])
	catalog.layout_paths = paths
	_assert(catalog.get_layout_path(catalog.stage_ids[0]) == paths[0], "canonical positional path lookup must resolve")
	catalog.layout_paths = []
	_assert(not catalog.is_valid(false), "a catalog without one path per stage must be invalid")
	catalog.layout_paths = paths
	catalog.layout_paths[0] = paths[1]
	_assert(not catalog.is_valid(false), "wrong-stage path must invalidate catalog")

func _assert(condition: bool, message: String) -> void:
	if condition: return
	push_error("Baked stage layout test failed: %s" % message)
	_failed = true

func _height_checksum(heights: PackedFloat32Array) -> int:
	var hash := 2166136261
	for height in heights:
		var quantized := roundi(height * 1000.0)
		for shift in [0, 8, 16, 24]:
			hash = hash ^ ((quantized >> shift) & 0xff)
			hash = int((hash * 16777619) & 0xffffffff)
	return hash

func _maximum_height(heights: PackedFloat32Array) -> float:
	var result := -INF
	for height in heights:
		result = maxf(result, height)
	return result
