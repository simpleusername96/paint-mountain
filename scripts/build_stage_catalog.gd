extends SceneTree

## Offline catalog writer. The first version deliberately emits the typed
## catalog pointer from the already-reviewed deterministic profile builder; the
## runtime then consumes only the serialized result.

const CATALOG_PATH := "res://resources/stages/catalog.tres"
const BUNDLE_FORMAT_VERSION := 5
const CATALOG_DATA_SCRIPT := preload("res://src/stage/stage_catalog_data.gd")
const TERRAIN_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const OPEN_ENVIRONMENT_SCENE := preload("res://scenes/gameplay/open_play_environment.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const BURST_DATA: MechanismData = preload("res://resources/mechanisms/burst_node.tres")
const SPLITTER_DATA: MechanismData = preload("res://resources/mechanisms/splitter_node.tres")
const UPHILL_REBOUND_DATA: MechanismData = preload(
	"res://resources/mechanisms/uphill_rebound_node.tres"
)
const SOURCE_STAGE_PATHS := [
	"res://resources/stages/first_descent.tres",
	"res://resources/stages/burst_basin.tres",
	"res://resources/stages/split_ridge.tres",
]


func _initialize() -> void:
	var promotion_root := _bundle_promotion_argument()
	if not promotion_root.is_empty():
		var promotion_catalog := load("%s/catalog.tres" % promotion_root) as StageCatalogData
		if promotion_catalog == null:
			push_error("Bundle promotion could not load catalog: %s" % promotion_root)
			quit(1)
			return
		if not _promote_staged_bundle(promotion_catalog, promotion_root) \
				or not _publish_catalog_pointer(promotion_catalog):
			quit(1)
			return
		print("Stage bundle and catalog pointer promoted: manifest=%s" % promotion_catalog.manifest_sha256)
		quit()
		return
	var verification_root := _bundle_verification_argument()
	if not verification_root.is_empty():
		var verification_catalog := load("%s/catalog.tres" % verification_root) as StageCatalogData
		if verification_catalog == null:
			push_error("Bundle verification could not load catalog: %s" % verification_root)
			quit(1)
			return
		var verification_passed := _verify_catalog_bundle(
			verification_catalog, verification_root
		)
		if verification_passed:
			print("Stage bundle verification passed: %s" % verification_root)
		quit(0 if verification_passed else 1)
		return
	var diagnostic_stage := _diagnostic_stage_argument()
	if not diagnostic_stage.is_empty():
		var diagnostic_passed := await _diagnose_stage(diagnostic_stage)
		quit(0 if diagnostic_passed else 3)
		return
	var write := "--write" in OS.get_cmdline_user_args()
	var dry_build := "--dry-build" in OS.get_cmdline_user_args()
	if not write and not dry_build:
		_check_active_catalog()
		return
	var build = await _build_catalog()
	var catalog: StageCatalogData = build.get("catalog") if build is Dictionary else null
	var layouts: Array[BakedStageLayoutData] = []
	if build is Dictionary:
		var raw_layouts: Variant = build.get("layouts")
		if raw_layouts is Array:
			for value in raw_layouts:
				var baked := value as BakedStageLayoutData
				if baked == null:
					push_error("Stage catalog build returned a non-baked layout.")
					quit(1)
					return
				layouts.append(baked)
	if catalog == null or not catalog.is_valid(false) or layouts.size() != catalog.stages.size():
		push_error("Stage catalog build failed validation.")
		quit(1)
		return
	if dry_build:
		print("Stage catalog dry build passed: %d stages manifest=%s" % [
			catalog.stages.size(), catalog.manifest_sha256,
		])
		quit()
		return
	if not _write_bundle_manifest(catalog, layouts):
		push_error("Could not promote the content-addressed stage bundle.")
		quit(1)
		return
	if not _publish_catalog_pointer(catalog):
		quit(1)
		return
	print("Stage catalog written: %s manifest=%s" % [CATALOG_PATH, catalog.manifest_sha256])
	quit()


## Offline/no-publish diagnostic for one exact canonical stage.
func _diagnose_stage(stage_id: String) -> bool:
	var existing := load(CATALOG_PATH) as StageCatalogData
	if existing == null:
		push_error("Offline exact-stage diagnostic requires the current source catalog.")
		return false
	var source_stage := existing.get_stage(StringName(stage_id)) as StageData
	if source_stage == null:
		push_error("Offline exact-stage diagnostic requested unknown stage: %s" % stage_id)
		return false
	var stage := _materialize_stage(source_stage, source_stage.stage_number)
	if stage == null:
		push_error("Offline exact-stage diagnostic could not materialize %s." % stage_id)
		return false
	var result := await _generate_and_bake(stage)
	if result.is_empty():
		push_error("Exact-stage diagnostic rejected stage=%s seed=%d" % [
			stage_id, StageProgressionData.CANONICAL_TERRAIN_SEED,
		])
		return false
	print("Exact-stage diagnostic passed: stage=%s seed=%d" % [
		stage_id, StageProgressionData.CANONICAL_TERRAIN_SEED,
	])
	return true


func _diagnostic_stage_argument() -> String:
	var arguments := OS.get_cmdline_user_args()
	var index := arguments.find("--diagnose-stage")
	return String(arguments[index + 1]) if index >= 0 and index + 1 < arguments.size() else ""


func _bundle_verification_argument() -> String:
	var arguments := OS.get_cmdline_user_args()
	var index := arguments.find("--verify-bundle")
	return String(arguments[index + 1]) if index >= 0 and index + 1 < arguments.size() else ""


func _bundle_promotion_argument() -> String:
	var arguments := OS.get_cmdline_user_args()
	var index := arguments.find("--promote-bundle")
	return String(arguments[index + 1]) if index >= 0 and index + 1 < arguments.size() else ""


func _check_active_catalog() -> void:
	var existing := load(CATALOG_PATH) as StageCatalogData
	if existing == null or not _verify_catalog_bundle(existing):
		push_error("Serialized format-4 catalog pointer is missing or invalid.")
		quit(1); return
	print("Stage catalog check passed: %d stages manifest=%s" % [existing.stages.size(), existing.manifest_sha256])
	quit()


func _build_catalog() -> Dictionary:
	var result = CATALOG_DATA_SCRIPT.new()
	result.catalog_version = StageGenerationContract.CONTRACT_VERSION
	result.progression = load(_progression_path()) as StageProgressionData
	var source_stages: Array[StageData] = []
	var existing = load(CATALOG_PATH)
	if existing != null and existing.has_method("ordered_stages"):
		source_stages = existing.ordered_stages()
	if source_stages.size() < StageProgressionData.STAGE_COUNT:
		for path in SOURCE_STAGE_PATHS:
			var legacy_stage := load(path) as StageData
			if legacy_stage != null:
				source_stages.append(legacy_stage)
		if source_stages.size() < StageProgressionData.STAGE_COUNT:
			push_error("The offline builder needs the reviewed thirty-stage source catalog.")
			return {}
	var manifest_parts: Array[String] = []
	var layouts: Array[BakedStageLayoutData] = []
	for source_index in range(StageProgressionData.STAGE_COUNT):
		var stage := _materialize_stage(source_stages[source_index], source_index + 1)
		if stage == null:
			return {}
		var built := await _generate_and_bake(stage)
		if built.is_empty():
			return {}
		stage = built.stage as StageData
		var baked := built.baked as BakedStageLayoutData
		var hydrated := StageLayoutBakeCodec.hydrate(baked, stage)
		if hydrated == null:
			return {}
		result.stage_ids.append(stage.stage_id)
		result.stages.append(stage.duplicate(true) as StageData)
		manifest_parts.append(_manifest_stage_descriptor(stage))
		manifest_parts.append("layout=%s|%s" % [
			"layouts/%s_layout.res" % stage.stage_id, baked.payload_sha256
		])
		manifest_parts.append("play_bounds_checksum=%d" % baked.play_bounds_checksum)
		manifest_parts.append("default_witness=%s" % _witness_manifest_descriptor(
			hydrated.generated_default_witness
		))
		manifest_parts.append("summit_witness=%s" % _witness_manifest_descriptor(
			hydrated.generated_summit_witness
		))
		layouts.append(baked)
	manifest_parts.append("bundle_format=%d" % BUNDLE_FORMAT_VERSION)
	manifest_parts.append("baked_schema=%d" % BakedStageLayoutData.BAKED_LAYOUT_SCHEMA_VERSION)
	result.manifest_sha256 = _sha256("\n".join(manifest_parts))
	result.bundle_manifest_path = CATALOG_DATA_SCRIPT.generated_bundle_manifest_path(
		result.manifest_sha256
	)
	for stage_id in result.stage_ids:
		result.layout_paths.append("%s/layouts/%s_layout.res" % [
			CATALOG_DATA_SCRIPT.generated_bundle_root(result.manifest_sha256), stage_id
		])
	return {"catalog": result, "layouts": layouts}


## One exact canonical identity either builds completely or fails closed.
func _generate_and_bake(stage: StageData) -> Dictionary:
	var exact_stage := stage.duplicate(true) as StageData
	exact_stage.terrain_seed = StageProgressionData.CANONICAL_TERRAIN_SEED
	exact_stage.generation_profile.base_seed = StageProgressionData.CANONICAL_TERRAIN_SEED
	_place_cannon_from_contract(exact_stage)
	var layout := SeededStageGenerator.generate_exact(
		exact_stage.generation_profile,
		exact_stage.terrain_seed,
		exact_stage
	)
	if layout == null or layout.terrain_seed != StageProgressionData.CANONICAL_TERRAIN_SEED:
		push_error("Exact canonical generation failed for %s." % stage.stage_id)
		return {}
	var witness_result := await _install_entry_witnesses_diagnostic(exact_stage, layout)
	if not bool(witness_result.get("valid", false)):
		push_error("Bounded entry witnesses failed for %s: %s/%s." % [
			stage.stage_id,
			String(witness_result.get("phase", "unknown")),
			String(witness_result.get("reason", "unknown")),
		])
		return {}
	var baked := StageLayoutBakeCodec.bake(layout, exact_stage)
	if baked == null:
		push_error(
			"Baking failed for %s: readiness=%s placement_count=%d placement_checksum=%d default=%s summit=%s." % [
				stage.stage_id,
				str(layout.runtime_readiness_diagnostic()),
				layout.mechanism_placements.size(),
				layout.placement_checksum(),
				layout.generated_default_witness != null and layout.generated_default_witness.is_valid(),
				layout.generated_summit_witness != null and layout.generated_summit_witness.is_valid(true),
			]
		)
		return {}
	return {"stage": exact_stage, "baked": baked}


static func _place_cannon_from_contract(stage: StageData) -> void:
	var front_world_z := stage.terrain_center.z \
			+ stage.generation_profile.generation_contract.local_bounds.end.y
	var origin := stage.cannon_transform.origin
	origin.x = stage.terrain_center.x
	origin.z = front_world_z + StageGenerationContract.FIXED_CANNON_STANDOFF
	stage.cannon_transform = Transform3D(stage.cannon_transform.basis, origin)


## Exactly two predictor/real-body checks: target-centroid and summit band.
func _install_entry_witnesses(stage: StageData, layout: GeneratedStageLayout) -> bool:
	return bool((await _install_entry_witnesses_diagnostic(stage, layout)).get("valid", false))


## The production caller consumes only validity. The offline diagnostic retains
## the first failed predictor/body boundary without changing either validator.
func _install_entry_witnesses_diagnostic(stage: StageData, layout: GeneratedStageLayout) -> Dictionary:
	var fixture := Node3D.new()
	root.add_child(fixture)
	var terrain := TERRAIN_SCENE.instantiate() as TerrainSurface
	terrain.position = stage.terrain_center
	fixture.add_child(terrain)
	await process_frame
	terrain.configure(layout)
	var open_environment := OPEN_ENVIRONMENT_SCENE.instantiate() as OpenPlayEnvironment
	fixture.add_child(open_environment)
	open_environment.configure(layout.play_bounds, stage.paint_world_bounds(), stage.terrain_center.y)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	fixture.add_child(cannon)
	cannon.global_transform = stage.cannon_transform
	await physics_frame
	var default_sample := _stable_default_sample(layout)
	var default_result := _single_target_result(cannon, terrain, layout, default_sample)
	if not bool(default_result.get("valid", false)):
		var default_predictor_reason := _diagnostic_result_reason(default_result, "invalid_default_prediction")
		fixture.queue_free()
		await physics_frame
		return {"valid": false, "phase": "default_predictor", "reason": default_predictor_reason}
	var default_body := await DirectReachabilityValidator.validate_rigidbody_batches(
		self, fixture, cannon, terrain, layout, layout.play_bounds.bounds, default_result, 1
	)
	if not bool(default_body.get("valid", false)):
		var default_body_reason := _diagnostic_result_reason(default_body, "default_rigidbody_parity")
		default_body_reason += " predicted_duration=%.3f" % float(default_result.get("prediction_duration", -1.0))
		fixture.queue_free()
		await physics_frame
		return {"valid": false, "phase": "default_body", "reason": default_body_reason}
	var summit_result := DirectReachabilityValidator.validate_summit(
		root.get_world_3d().direct_space_state, cannon, terrain, layout, layout.play_bounds.bounds
	)
	if not bool(summit_result.get("valid", false)):
		var summit_predictor_reason := _diagnostic_result_reason(summit_result, "invalid_summit_prediction")
		fixture.queue_free()
		await physics_frame
		return {"valid": false, "phase": "summit_predictor", "reason": summit_predictor_reason}
	var summit_body := await DirectReachabilityValidator.validate_rigidbody_batches(
		self, fixture, cannon, terrain, layout, layout.play_bounds.bounds, summit_result, 1
	)
	if not bool(summit_body.get("valid", false)):
		var summit_body_reason := _diagnostic_result_reason(summit_body, "summit_rigidbody_parity")
		summit_body_reason += " predicted_duration=%.3f" % float(summit_result.get("prediction_duration", -1.0))
		fixture.queue_free()
		await physics_frame
		return {"valid": false, "phase": "summit_body", "reason": summit_body_reason}
	layout.generated_default_witness = _witness_from_results(default_result, default_body, terrain, default_sample, 0)
	layout.generated_summit_witness = _witness_from_results(summit_result, summit_body, terrain, {}, layout.summit_region_checksum())
	var valid := layout.generated_default_witness != null and layout.generated_summit_witness != null
	fixture.queue_free()
	await physics_frame
	var reason := ""
	if not valid:
		reason = "invalid_default_witness" if layout.generated_default_witness == null \
				else "invalid_summit_witness"
	return {"valid": valid, "phase": "witness_payload", "reason": reason}


func _diagnostic_result_reason(result: Dictionary, default_reason: String) -> String:
	var rejection := String(result.get("rejection", ""))
	var reason := rejection if not rejection.is_empty() else default_reason
	var failures: Array = result.get("failure_diagnostics", [])
	return "%s %s" % [reason, JSON.stringify(failures)] if not failures.is_empty() else reason


func _single_target_result(cannon: CannonController, terrain: TerrainSurface, layout: GeneratedStageLayout, sample: Dictionary) -> Dictionary:
	if sample.is_empty(): return {"valid": false}
	var target := terrain.to_global(sample.point as Vector3)
	var normal := (terrain.global_transform.basis.inverse().transposed() * (sample.normal as Vector3)).normalized()
	var solved := DirectReachabilityValidator.solve_one_target(
		root.get_world_3d().direct_space_state,
		cannon,
		layout,
		layout.play_bounds.bounds,
		target,
		normal,
		sample,
		true
	)
	if not bool(solved.get("valid", false)): return solved
	var prediction := solved.prediction as TrajectoryPrediction
	return {"valid": prediction != null and prediction.hit_identity != null, "prediction_duration": prediction.duration, "witnesses": [solved.aim], "witness_identities": [prediction.hit_identity], "witness_impacts": PackedVector3Array([prediction.endpoint]), "target_points": PackedVector3Array([target]), "target_witness_indices": PackedInt32Array([0]), "minimum_distance_margins": PackedFloat32Array([maxf(DirectReachabilityValidator.TARGET_DISTANCE_TOLERANCE - prediction.endpoint.distance_to(target), 0.0)]), "minimum_range_margins": PackedFloat32Array([float(solved.get("range_margin", 0.0))])}


func _stable_default_sample(layout: GeneratedStageLayout) -> Dictionary:
	var sample := layout.target_sample_nearest_centroid()
	if sample.is_empty():
		return sample
	var indices := layout.top_topology.triangle_vertex_indices(
		sample.cell as Vector2i,
		int(sample.triangle)
	)
	var vertices := layout.top_topology.canonical_vertices_read_only()
	if indices.x < 0 or indices.y < 0 or indices.z < 0 \
			or indices.x >= vertices.size() or indices.y >= vertices.size() \
			or indices.z >= vertices.size():
		return {}
	# Aim at the selected target triangle's interior, not a mask-pixel center that
	# may sit exactly on the cell diagonal and make equivalent physics hits report
	# adjacent triangle IDs.
	sample["point"] = (vertices[indices.x] + vertices[indices.y] + vertices[indices.z]) / 3.0
	sample["normal"] = layout.top_topology.triangle_normal(
		sample.cell as Vector2i,
		int(sample.triangle)
	)
	return sample


func _witness_from_results(predictor: Dictionary, body: Dictionary, terrain: TerrainSurface, sample: Dictionary, summit_checksum: int) -> StageEntryAimWitness:
	var outcomes: Array = body.get("outcomes", [])
	var identities: Array = predictor.get("witness_identities", [])
	var impacts: PackedVector3Array = predictor.get("witness_impacts", PackedVector3Array())
	var physical: PackedVector3Array = body.get("physical_witness_impacts", PackedVector3Array())
	var aims: Array = predictor.get("witnesses", [])
	var targets: PackedVector3Array = predictor.get("target_points", PackedVector3Array())
	if aims.size() != 1 or identities.size() != 1 or outcomes.size() != 1 \
			or impacts.size() != 1 or physical.size() != 1 or targets.size() != 1: return null
	var outcome: Dictionary = outcomes[0]
	var witness := StageEntryAimWitness.new()
	witness.aim = aims[0] as AimTuple; witness.predicted_identity = identities[0] as TrajectoryHitIdentity; witness.physical_identity = outcome.get("identity") as TrajectoryHitIdentity
	witness.predicted_local_impact = terrain.to_local(impacts[0]); witness.physical_local_impact = terrain.to_local(physical[0]); witness.target_local_point = sample.get("point", terrain.to_local(targets[0]))
	witness.target_pixel_index = int(sample.get("target_pixel_index", -1)); witness.summit_region_checksum = summit_checksum
	witness.distance_margin = float((body.get("minimum_distance_margins", PackedFloat32Array([0.0])) as PackedFloat32Array)[0]); witness.range_margin = float((predictor.get("minimum_range_margins", PackedFloat32Array([0.0])) as PackedFloat32Array)[0]); witness.height_margin = float(predictor.get("minimum_height_margin", 0.0))
	if not witness.is_valid(summit_checksum != 0):
		push_error("Witness payload invalid: summit=%s target_pixel=%d distance=%.4f range=%.4f height=%.4f predicted=%s physical=%s" % [
			summit_checksum != 0,
			witness.target_pixel_index,
			witness.distance_margin,
			witness.range_margin,
			witness.height_margin,
			str(witness.predicted_identity.terrain_cell if witness.predicted_identity != null else Vector2i(-1, -1)),
			str(witness.physical_identity.terrain_cell if witness.physical_identity != null else Vector2i(-1, -1)),
		])
		return null
	return witness


func _manifest_stage_descriptor(stage: StageData) -> String:
	var profile := stage.generation_profile
	var contract := profile.generation_contract
	var route_parts: Array[String] = []
	for route in profile.routes:
		route_parts.append("%d,%s,%.3f,%s,%s,%s,%s,%s,%s,%s" % [
			route.role,
		str(route.endpoint_x),
		route.width,
		str(route.grade_signs),
		str(route.drop_range),
		str(route.rise_range),
		str(route.lateral_bend_range),
		str(route.mechanism_kinds),
		str(route.mechanism_pad_ts),
		str(route.mechanism_pad_radii),
	])
	var loadout_parts: Array[String] = []
	for mechanism in stage.mechanism_loadout:
		loadout_parts.append(_mechanism_manifest_descriptor(mechanism))
	var stage_line := "|".join([
		str(stage.stage_id), str(stage.stage_number), str(stage.stage_version), str(stage.terrain_seed),
		str(stage.terrain_center), str(stage.terrain_size), str(stage.target_coverage), str(stage.maximum_shots),
		str(profile.profile_id), str(profile.profile_version), str(profile.nominal_peak),
		str(profile.accepted_height_range), str(profile.ridge_count), str(profile.basin_count),
		str(profile.pass_count), str(profile.undulation_amplitude), str(profile.route_width),
		str(contract.cell_count), str(contract.local_bounds), str(contract.route_station_z),
	])
	return "\n".join([
		stage_line,
		"routes=" + "|".join(route_parts),
		"loadout=" + "|".join(loadout_parts),
	])


func _mechanism_manifest_descriptor(mechanism: MechanismData) -> String:
	if mechanism == null:
		return "null"
	return ",".join([
		str(int(mechanism.canonical_kind())), str(mechanism.glyph_radius),
		str(mechanism.maximum_charges), str(mechanism.cooldown_seconds),
		str(mechanism.burst_radius), str(mechanism.child_count),
		str(mechanism.maximum_split_generation), str(mechanism.child_radius_multiplier),
		str(mechanism.child_speed_multiplier), str(mechanism.child_minimum_route_speed),
		str(mechanism.child_target_lift), str(mechanism.child_target_t),
		str(mechanism.child_target_route_roles), str(mechanism.uphill_sample_distance),
		str(mechanism.minimum_uphill_rise), str(mechanism.rebound_speed_multiplier),
		str(mechanism.rebound_minimum_speed), str(mechanism.rebound_maximum_speed),
		str(mechanism.rebound_lift_ratio),
	])


static func _materialize_stage(source: StageData, stage_number: int) -> StageData:
	if source == null:
		return null
	var stage := source.duplicate(true) as StageData
	var stage_id := StringName("stage_%02d" % stage_number)
	stage.stage_id = stage_id
	stage.stage_version = StageGenerationContract.CONTRACT_VERSION
	stage.stage_number = stage_number
	stage.target_coverage = StageProgressionData.target_for(stage_number)
	stage.maximum_shots = StageProgressionData.shots_for(stage_number)
	stage.star_thresholds = Vector3(
		stage.target_coverage,
		stage.target_coverage + 2.5,
		stage.target_coverage + 5.0
	)
	stage.terrain_seed = StageProgressionData.terrain_seed_for(stage_number)
	stage.terrain_size = StageProgressionData.terrain_size_for(stage_number)
	# One shared world anchor keeps the independent mountain distant while its
	# depth expands in both directions instead of growing toward the cannon.
	stage.terrain_center = Vector3(0.0, -2.0, -130.0)
	stage.mechanism_loadout = _materialize_mechanisms(source.mechanism_loadout, stage_number)
	if stage.mechanism_loadout.size() != StageProgressionData.mechanism_count_for(stage_number):
		return null
	stage.generation_profile = _materialize_profile(
		stage.generation_profile,
		stage_number,
		stage_id,
		stage.terrain_seed
	)
	if stage.generation_profile == null \
			or not _materialize_route_mechanism_slots(
				stage.generation_profile, stage.mechanism_loadout, stage_number
			) \
			or not stage.generation_profile.is_valid():
		return null
	return stage


static func _materialize_profile(
	source: StageGenerationProfile,
	stage_number: int,
	stage_id: StringName,
	terrain_seed: int
) -> StageGenerationProfile:
	if source == null:
		return null
	var profile := source.duplicate(true) as StageGenerationProfile
	profile.profile_id = StageGenerationProfile.profile_id_for_stage(stage_id)
	profile.profile_version = StageGenerationContract.CONTRACT_VERSION
	profile.base_seed = terrain_seed
	profile.nominal_peak = StageProgressionData.nominal_peak_for(stage_number)
	profile.accepted_height_range = Vector2(
		profile.nominal_peak - (12.0 if stage_number == 3 else 4.0),
		profile.nominal_peak + 10.0
	)
	profile.ridge_count = StageProgressionData.ridge_count_for(stage_number)
	profile.basin_count = StageProgressionData.basin_count_for(stage_number)
	profile.pass_count = StageProgressionData.pass_count_for(stage_number)
	profile.undulation_amplitude = StageProgressionData.undulation_for(stage_number)
	profile.route_width = StageProgressionData.route_width_for(stage_number)
	profile.generation_contract = _materialize_contract(
		profile.generation_contract, stage_number
	)
	if profile.generation_contract == null:
		return null
	if stage_number <= 3:
		profile.target_ratio_range = Vector2(0.18, 0.72)
		profile.target_mean_slope_range = Vector2(12.0, 45.0)
		profile.target_p95_slope_max = 60.0
		profile.target_maximum_slope = 68.0
		profile.route_core_p95_slope_max = 60.0
		profile.corridor_lip_maximum_slope = 50.0
		profile.routes = _intro_routes(stage_number, profile.route_width)
	return profile


static func _materialize_contract(
		source: StageGenerationContract,
		stage_number: int
) -> StageGenerationContract:
	if source == null:
		return null
	var contract := source.duplicate(true) as StageGenerationContract
	contract.generation_version = StageGenerationContract.CONTRACT_VERSION
	contract.profile_version = StageGenerationContract.CONTRACT_VERSION
	contract.layout_version = StageGenerationContract.CONTRACT_VERSION
	var terrain_size := StageProgressionData.terrain_size_for(stage_number)
	contract.cell_count = StageProgressionData.cell_count_for(stage_number)
	contract.local_bounds = Rect2(-terrain_size * 0.5, terrain_size)
	contract.maximum_top_triangle_count = contract.cell_count.x * contract.cell_count.y * 2
	var station_count := StageProgressionData.station_count_for(stage_number)
	var stations := PackedFloat32Array()
	var route_start_z := contract.local_bounds.position.y + contract.outer_band_width + 4.0
	var route_end_z := contract.local_bounds.end.y - contract.outer_band_width - 4.0
	for index in range(station_count):
		stations.append(lerpf(route_start_z, route_end_z, float(index) / float(station_count - 1)))
	contract.route_station_z = stations
	return contract


static func _intro_routes(stage_number: int, width: float) -> Array[StageRouteProfile]:
	var routes: Array[StageRouteProfile] = []
	if stage_number <= 2:
		routes.append(_intro_route(
			stage_number,
			width,
			StageRouteProfile.Role.PRIMARY,
			0.0
		))
		return routes
	# Splitter's three children need three distinct, authoritative route roles.
	# Stage 03 teaches that fan-out explicitly; later stages keep their reviewed
	# catalog profiles rather than inheriting this tutorial topology.
	routes.append(_intro_route(
		stage_number,
		width,
		StageRouteProfile.Role.SAFE,
		-48.0
	))
	routes.append(_intro_route(
		stage_number,
		width,
		StageRouteProfile.Role.SPLITTER,
		0.0,
		MechanismData.Kind.SPLITTER,
		0.42,
		10.0
	))
	routes.append(_intro_route(
		stage_number,
		width,
		StageRouteProfile.Role.BUMPER,
		48.0,
		MechanismData.Kind.UPHILL_REBOUND,
		0.76,
		1.5
	))
	return routes


static func _intro_route(
		stage_number: int,
		width: float,
		role: StageRouteProfile.Role,
		endpoint_x: float,
		mechanism_kind: int = -1,
		mechanism_pad_t: float = -1.0,
		mechanism_pad_radius: float = 0.0
) -> StageRouteProfile:
	var route := StageRouteProfile.new()
	route.role = role
	route.endpoint_x = endpoint_x
	route.width = width
	route.grade_signs = PackedInt32Array([-1, -1, -1, -1, -1, -1, -1])
	route.drop_range = Vector2(5.5 + float(stage_number - 1) * 0.35, 7.0 + float(stage_number - 1) * 0.45)
	route.rise_range = Vector2.ZERO
	route.lateral_bend_range = Vector2(-8.0 - float(stage_number), 8.0 + float(stage_number))
	if stage_number == 3:
		# Keep the three tutorial branches readable and inside the per-station
		# movement limit. The route width, not this legacy pad radius, supports
		# the terrain-conforming glyph footprint.
		route.lateral_bend_range = Vector2(-4.0, 4.0)
	if stage_number == 2:
		route.mechanism_kinds = PackedInt32Array([MechanismData.Kind.BURST])
		# Keep the tutorial glyph on the broad upper shelf. The former midpoint
		# crossed the sharp bank and could not render as a readable surface mark.
		route.mechanism_pad_ts = PackedFloat32Array([0.25])
		route.mechanism_pad_radii = PackedFloat32Array([10.0])
	elif mechanism_kind >= 0:
		route.mechanism_kinds = PackedInt32Array([mechanism_kind])
		route.mechanism_pad_ts = PackedFloat32Array([mechanism_pad_t])
		route.mechanism_pad_radii = PackedFloat32Array([mechanism_pad_radius])
	return route


static func _materialize_mechanisms(source: Array[MechanismData], stage_number: int) -> Array[MechanismData]:
	var result: Array[MechanismData] = []
	var desired := StageProgressionData.mechanism_count_for(stage_number)
	if stage_number == 1:
		return result
	if stage_number == 2:
		_append_canonical_mechanism(result, MechanismData.Kind.BURST)
		return result
	if stage_number == 3:
		_append_canonical_mechanism(result, MechanismData.Kind.SPLITTER)
		_append_canonical_mechanism(result, MechanismData.Kind.UPHILL_REBOUND)
		return result

	var route_count := StageProgressionData.route_count_for(stage_number)
	var safe_early_kinds := [MechanismData.Kind.BURST, MechanismData.Kind.UPHILL_REBOUND]
	var three_route_default_kinds := [
		MechanismData.Kind.BURST,
		MechanismData.Kind.SPLITTER,
		MechanismData.Kind.UPHILL_REBOUND,
	]
	for index in range(desired):
		var kind: MechanismData.Kind
		if route_count < 3:
			kind = safe_early_kinds[index % safe_early_kinds.size()]
		elif index < source.size() and source[index] != null and source[index].is_valid():
			kind = source[index].canonical_kind()
		else:
			kind = three_route_default_kinds[index % three_route_default_kinds.size()]
		_append_canonical_mechanism(result, kind)
	return result


static func _append_canonical_mechanism(
		result: Array[MechanismData],
		kind: MechanismData.Kind
) -> void:
	var canonical := _canonical_mechanism_data(kind)
	if canonical != null:
		result.append(canonical.duplicate(true) as MechanismData)


static func _materialize_route_mechanism_slots(
		profile: StageGenerationProfile,
		loadout: Array[MechanismData],
		stage_number: int = -1
) -> bool:
	if profile == null:
		return false
	var slot_count := 0
	for route in profile.routes:
		if route != null:
			slot_count += route.mechanism_slots().size()
	if slot_count != loadout.size():
		return false

	var loadout_index := 0
	for route in profile.routes:
		if route == null:
			return false
		var source_slots := route.mechanism_slots()
		if source_slots.is_empty():
			continue
		var kinds := PackedInt32Array()
		var pad_ts := PackedFloat32Array()
		var pad_radii := PackedFloat32Array()
		for source_slot in source_slots:
			var mechanism := loadout[loadout_index]
			if mechanism == null:
				return false
			var kind := mechanism.canonical_kind()
			kinds.append(int(kind))
			pad_ts.append(_mechanism_pad_t(
				kind, float(source_slot.get("t", -1.0)), stage_number
			))
			pad_radii.append(_mechanism_pad_radius(kind, stage_number))
			loadout_index += 1
		route.mechanism_kind = -1
		route.mechanism_pad_t = -1.0
		route.mechanism_pad_radius = 0.0
		route.mechanism_kinds = kinds
		route.mechanism_pad_ts = pad_ts
		route.mechanism_pad_radii = pad_radii
	return loadout_index == loadout.size()


static func _mechanism_pad_t(
	kind: MechanismData.Kind,
	source_t: float,
	stage_number: int = -1
) -> float:
	# Stage 04's reviewed route has a natural uphill witness on its upper shelf;
	# the old late-route anchor sits on the sharp terminal descent instead.
	if stage_number == 4 and kind == MechanismData.Kind.UPHILL_REBOUND:
		return 0.30
	return source_t


static func _mechanism_pad_radius(kind: MechanismData.Kind, stage_number: int = -1) -> float:
	match int(kind):
		int(MechanismData.Kind.SPLITTER):
			return 10.0
		int(MechanismData.Kind.UPHILL_REBOUND):
			# Stages 04 and 08 use already-planar natural slopes, where even a
			# narrow artificial shelf erases the ascent witness.
			return 0.25 if stage_number in [4, 8] else 1.5
	# Burst's full ring must stay on its broad shelf instead of crossing the
	# sharp support blend at the edge of the old 8 m anchor.
	return 10.0


static func _canonical_mechanism_data(kind: MechanismData.Kind) -> MechanismData:
	match int(kind):
		int(MechanismData.Kind.BURST):
			return BURST_DATA
		int(MechanismData.Kind.SPLITTER):
			return SPLITTER_DATA
		int(MechanismData.Kind.UPHILL_REBOUND):
			return UPHILL_REBOUND_DATA
	return null


func _sha256(value: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()


func _write_bundle_manifest(catalog: StageCatalogData, layouts: Array[BakedStageLayoutData]) -> bool:
	if layouts.size() != catalog.stages.size():
		return false
	var bundle_root := CATALOG_DATA_SCRIPT.generated_bundle_root(catalog.manifest_sha256)
	var final_absolute := ProjectSettings.globalize_path(bundle_root)
	# A matching immutable bundle is already the desired output. Never rewrite it
	# in place: the catalog pointer can continue to refer to the old bundle if a
	# later write fails.
	if DirAccess.dir_exists_absolute(final_absolute):
		if _verify_catalog_bundle(catalog, bundle_root):
			return true
		push_error("Refusing to overwrite an invalid content-addressed bundle: %s" % bundle_root)
		return false
	var staging_root := "res://resources/generated_stage_catalogs/.%s-%s.%d.staging" % [
		StageGenerationContract.version_tag(),
		catalog.manifest_sha256,
		Time.get_ticks_usec(),
	]
	var staging_absolute := ProjectSettings.globalize_path(staging_root)
	DirAccess.make_dir_recursive_absolute(staging_absolute)
	var bundle_catalog := "%s/catalog.tres" % staging_root
	if ResourceSaver.save(catalog, bundle_catalog) != OK:
		return false
	for subdirectory in ["stages", "profiles", "layouts", "certificates", "previews"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [staging_root, subdirectory]))
	var certificate_paths: Array[String] = []
	var preview_paths: Array[String] = []
	var play_bounds_checksums: Array[int] = []
	var default_witnesses: Array[Dictionary] = []
	var summit_witnesses: Array[Dictionary] = []
	for index in range(catalog.stages.size()):
		var stage: StageData = catalog.stages[index]
		var numeric_id := "stage_%02d" % maxi(stage.stage_number, index + 1)
		if ResourceSaver.save(stage, "%s/stages/%s.tres" % [staging_root, numeric_id]) != OK:
			return false
		if ResourceSaver.save(stage.generation_profile, "%s/profiles/%s_profile.tres" % [staging_root, numeric_id]) != OK:
			return false
		var layout_path := "%s/layouts/%s_layout.res" % [staging_root, numeric_id]
		if ResourceSaver.save(layouts[index], layout_path, ResourceSaver.FLAG_COMPRESS) != OK:
			return false
		var reloaded := load(layout_path) as BakedStageLayoutData
		var hydrated := StageLayoutBakeCodec.hydrate(reloaded, stage)
		if hydrated == null:
			return false
		play_bounds_checksums.append(reloaded.play_bounds_checksum)
		default_witnesses.append(_witness_manifest_summary(hydrated.generated_default_witness))
		summit_witnesses.append(_witness_manifest_summary(hydrated.generated_summit_witness))
		if stage.reachability_certificate != null:
			var certificate_path := "%s/certificates/%s_certificate.tres" % [staging_root, numeric_id]
			if ResourceSaver.save(stage.reachability_certificate, certificate_path) != OK:
				return false
			certificate_paths.append("%s/certificates/%s_certificate.tres" % [bundle_root, numeric_id])
	var manifest := {
		"catalog_version": catalog.catalog_version,
		"bundle_format": BUNDLE_FORMAT_VERSION,
		"baked_schema": BakedStageLayoutData.BAKED_LAYOUT_SCHEMA_VERSION,
		"manifest_sha256": catalog.manifest_sha256,
		"bundle_manifest_path": catalog.bundle_manifest_path,
		"stage_ids": catalog.stage_ids,
		"terrain_seeds": catalog.stages.map(func(stage: StageData) -> int: return stage.terrain_seed),
		"profile_ids": catalog.stages.map(func(stage: StageData) -> String: return String(stage.generation_profile.profile_id)),
		"layout_paths": catalog.layout_paths,
		"layout_payload_sha256": layouts.map(func(layout: BakedStageLayoutData) -> String: return layout.payload_sha256),
		"play_bounds_checksums": play_bounds_checksums,
		"default_witnesses": default_witnesses,
		"summit_witnesses": summit_witnesses,
		"certificate_paths": certificate_paths,
		"preview_paths": preview_paths,
		"previews_ready": false,
	}
	var file := FileAccess.open("%s/manifest.json" % staging_root, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest, "\t"))
	file.flush()
	file.close()
	# Promote the complete bundle only after every resource and manifest write has
	# succeeded. A failed run leaves the last catalog pointer and final bundle
	# untouched; the positively named staging directory is safe to inspect.
	if not _verify_catalog_bundle(catalog, staging_root):
		push_error("Stage-bundle staging validation failed: %s" % staging_root)
		return false
	if DirAccess.rename_absolute(staging_absolute, final_absolute) != OK:
		push_error("Could not promote stage bundle %s" % bundle_root)
		return false
	return _verify_catalog_bundle(catalog, bundle_root)


func _promote_staged_bundle(catalog: StageCatalogData, staging_root: String) -> bool:
	if catalog == null or staging_root.is_empty():
		return _bundle_validation_failure("staged-bundle promotion input is empty")
	var final_root := CATALOG_DATA_SCRIPT.generated_bundle_root(catalog.manifest_sha256)
	var expected_prefix := "res://resources/generated_stage_catalogs/.%s-%s." % [
		StageGenerationContract.version_tag(), catalog.manifest_sha256,
	]
	if not staging_root.begins_with(expected_prefix) or not staging_root.ends_with(".staging"):
		return _bundle_validation_failure(
			"promotion path is not the matching content-addressed staging directory"
		)
	if not _verify_catalog_bundle(catalog, staging_root):
		return false
	var staging_absolute := ProjectSettings.globalize_path(staging_root)
	var final_absolute := ProjectSettings.globalize_path(final_root)
	if DirAccess.dir_exists_absolute(final_absolute):
		if _verify_catalog_bundle(catalog, final_root):
			return true
		return _bundle_validation_failure("matching final bundle exists but is invalid")
	if DirAccess.rename_absolute(staging_absolute, final_absolute) != OK:
		return _bundle_validation_failure("could not promote verified staging directory")
	if _verify_catalog_bundle(catalog, final_root):
		return true
	var rollback_error := DirAccess.rename_absolute(final_absolute, staging_absolute)
	if rollback_error != OK:
		push_error("Invalid promoted bundle remains recoverable at %s" % final_root)
	return _bundle_validation_failure("promoted bundle failed final-path verification")


func _publish_catalog_pointer(catalog: StageCatalogData) -> bool:
	if catalog == null or not _verify_catalog_bundle(catalog):
		push_error("Refusing to publish a catalog pointer for an invalid final bundle.")
		return false
	var staging_path := _catalog_staging_path()
	var staging_error := ResourceSaver.save(catalog, staging_path)
	if staging_error != OK:
		push_error("Could not write catalog staging resource: %s" % staging_error)
		return false
	var promoted := _replace_catalog_pointer(staging_path, CATALOG_PATH)
	if promoted != OK:
		push_error("Could not promote catalog resource: %s" % promoted)
		return false
	return true


func _verify_catalog_bundle(catalog: StageCatalogData, bundle_root: String = "") -> bool:
	if catalog == null:
		return _bundle_validation_failure("catalog is null")
	if not catalog.is_valid(false):
		return _bundle_validation_failure("catalog failed StageCatalogData.is_valid(false)")
	if catalog.layout_paths.size() != catalog.stages.size():
		return _bundle_validation_failure("layout-path count differs from stage count")
	var resolved_root := bundle_root if not bundle_root.is_empty() \
		else CATALOG_DATA_SCRIPT.generated_bundle_root(catalog.manifest_sha256)
	var manifest_path := "%s/manifest.json" % resolved_root
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return _bundle_validation_failure("manifest is unreadable: %s" % manifest_path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return _bundle_validation_failure("manifest JSON is not a Dictionary")
	var manifest: Dictionary = parsed
	if int(manifest.get("bundle_format", -1)) != BUNDLE_FORMAT_VERSION \
			or int(manifest.get("baked_schema", -1)) \
					!= BakedStageLayoutData.BAKED_LAYOUT_SCHEMA_VERSION \
			or int(manifest.get("catalog_version", -1)) != catalog.catalog_version \
			or String(manifest.get("manifest_sha256", "")) != catalog.manifest_sha256 \
			or String(manifest.get("bundle_manifest_path", "")) != catalog.bundle_manifest_path:
		return _bundle_validation_failure("manifest header does not match catalog identity")
	if not _manifest_array_matches(manifest.get("stage_ids", []), _catalog_stage_ids(catalog)):
		return _bundle_validation_failure("manifest stage IDs differ from catalog")
	if not _manifest_array_matches(manifest.get("terrain_seeds", []), _catalog_seeds(catalog)):
		return _bundle_validation_failure("manifest terrain seeds differ from catalog")
	if not _manifest_array_matches(manifest.get("profile_ids", []), _catalog_profile_ids(catalog)):
		return _bundle_validation_failure("manifest profile IDs differ from catalog")
	if not _manifest_array_matches(manifest.get("layout_paths", []), catalog.layout_paths):
		return _bundle_validation_failure("manifest layout paths differ from catalog")
	var payload_hashes: Array = manifest.get("layout_payload_sha256", [])
	var play_bounds_checksums: Array = manifest.get("play_bounds_checksums", [])
	var default_witnesses: Array = manifest.get("default_witnesses", [])
	var summit_witnesses: Array = manifest.get("summit_witnesses", [])
	if payload_hashes.size() != catalog.stages.size():
		return _bundle_validation_failure("manifest payload-hash count differs from stage count")
	if play_bounds_checksums.size() != catalog.stages.size():
		return _bundle_validation_failure("manifest play-bounds count differs from stage count")
	if default_witnesses.size() != catalog.stages.size():
		return _bundle_validation_failure("manifest default-witness count differs from stage count")
	if summit_witnesses.size() != catalog.stages.size():
		return _bundle_validation_failure("manifest summit-witness count differs from stage count")
	if not _manifest_optional_paths_are_valid(manifest, catalog):
		return _bundle_validation_failure("manifest optional artifact paths are invalid")
	var bundled_catalog := load("%s/catalog.tres" % resolved_root) as StageCatalogData
	if bundled_catalog == null:
		return _bundle_validation_failure("bundled catalog cannot be loaded")
	if not _catalog_identity_matches(catalog, bundled_catalog):
		return _bundle_validation_failure("bundled catalog identity differs from expected catalog")
	var manifest_parts: Array[String] = []
	for index in range(catalog.stages.size()):
		var stage: StageData = catalog.stages[index]
		var stage_id := String(catalog.stage_ids[index])
		var baked := load("%s/layouts/%s_layout.res" % [resolved_root, stage_id]) as BakedStageLayoutData
		if baked == null:
			return _bundle_validation_failure("%s layout cannot be loaded" % stage_id)
		if baked.payload_sha256 != String(payload_hashes[index]):
			return _bundle_validation_failure("%s payload hash differs from manifest" % stage_id)
		if baked.payload_sha256 != StageLayoutBakeCodec.payload_sha256(baked):
			return _bundle_validation_failure("%s serialized payload hash is not reproducible" % stage_id)
		var hydrated := StageLayoutBakeCodec.hydrate(baked, stage)
		if hydrated == null:
			return _bundle_validation_failure("%s layout hydration failed" % stage_id)
		if not hydrated.is_runtime_ready():
			return _bundle_validation_failure("%s hydrated layout is not runtime-ready" % stage_id)
		if baked.terrain_seed != StageProgressionData.CANONICAL_TERRAIN_SEED:
			return _bundle_validation_failure("%s terrain seed identity is invalid" % stage_id)
		if baked.play_bounds_checksum != int(play_bounds_checksums[index]) \
				or baked.play_bounds_checksum != PlayBoundsSpec.new().checksum():
			return _bundle_validation_failure("%s play bounds differ from manifest" % stage_id)
		if not _witness_manifest_matches(
			default_witnesses[index], hydrated.generated_default_witness
		):
			return _bundle_validation_failure(
				"%s default witness differs from manifest: stored=%s hydrated=%s" % [
					stage_id,
					JSON.stringify(default_witnesses[index]),
					JSON.stringify(_witness_manifest_summary(hydrated.generated_default_witness)),
				]
			)
		if not _witness_manifest_matches(
			summit_witnesses[index], hydrated.generated_summit_witness
		):
			return _bundle_validation_failure(
				"%s summit witness differs from manifest: stored=%s hydrated=%s" % [
					stage_id,
					JSON.stringify(summit_witnesses[index]),
					JSON.stringify(_witness_manifest_summary(hydrated.generated_summit_witness)),
				]
			)
		manifest_parts.append(_manifest_stage_descriptor(stage))
		manifest_parts.append("layout=%s|%s" % [
			"layouts/%s_layout.res" % stage.stage_id,
			baked.payload_sha256,
		])
		manifest_parts.append("play_bounds_checksum=%d" % baked.play_bounds_checksum)
		manifest_parts.append("default_witness=%s" % _witness_manifest_descriptor(
			hydrated.generated_default_witness
		))
		manifest_parts.append("summit_witness=%s" % _witness_manifest_descriptor(
			hydrated.generated_summit_witness
		))
	manifest_parts.append("bundle_format=%d" % BUNDLE_FORMAT_VERSION)
	manifest_parts.append(
		"baked_schema=%d" % BakedStageLayoutData.BAKED_LAYOUT_SCHEMA_VERSION
	)
	if _sha256("\n".join(manifest_parts)) != catalog.manifest_sha256:
		return _bundle_validation_failure("reconstructed bundle manifest hash differs from catalog")
	return true


func _bundle_validation_failure(reason: String) -> bool:
	push_error("Stage-bundle validation failed: %s" % reason)
	return false


func _catalog_identity_matches(expected: StageCatalogData, bundled: StageCatalogData) -> bool:
	if expected == null or bundled == null or not bundled.is_valid(false) \
			or bundled.manifest_sha256 != expected.manifest_sha256 \
			or bundled.bundle_manifest_path != expected.bundle_manifest_path \
			or bundled.catalog_version != expected.catalog_version \
			or not _manifest_array_matches(_catalog_stage_ids(bundled), _catalog_stage_ids(expected)) \
			or not _manifest_array_matches(bundled.layout_paths, expected.layout_paths):
		return false
	for index in range(expected.stages.size()):
		if _manifest_stage_descriptor(bundled.stages[index]) \
				!= _manifest_stage_descriptor(expected.stages[index]):
			return false
	return true


func _manifest_optional_paths_are_valid(manifest: Dictionary, catalog: StageCatalogData) -> bool:
	var certificate_paths: Array = manifest.get("certificate_paths", [])
	var preview_paths: Array = manifest.get("preview_paths", [])
	if not certificate_paths is Array or not preview_paths is Array:
		return false
	var expected_certificates: Array[String] = []
	var final_root := CATALOG_DATA_SCRIPT.generated_bundle_root(catalog.manifest_sha256)
	for index in range(catalog.stages.size()):
		if catalog.stages[index].reachability_certificate != null:
			expected_certificates.append("%s/certificates/%s_certificate.tres" % [
				final_root, String(catalog.stage_ids[index]),
			])
	return _manifest_array_matches(certificate_paths, expected_certificates) \
			and preview_paths.is_empty() and not bool(manifest.get("previews_ready", true))


func _catalog_stage_ids(catalog: StageCatalogData) -> Array[String]:
	var ids: Array[String] = []
	for stage_id in catalog.stage_ids:
		ids.append(String(stage_id))
	return ids


func _catalog_seeds(catalog: StageCatalogData) -> Array[int]:
	var seeds: Array[int] = []
	for stage in catalog.stages:
		seeds.append(stage.terrain_seed)
	return seeds


func _catalog_profile_ids(catalog: StageCatalogData) -> Array[String]:
	var ids: Array[String] = []
	for stage in catalog.stages:
		ids.append(String(stage.generation_profile.profile_id))
	return ids


func _manifest_array_matches(actual: Variant, expected: Array) -> bool:
	if not actual is Array or actual.size() != expected.size():
		return false
	for index in range(expected.size()):
		if actual[index] != expected[index]:
			return false
	return true


func _witness_manifest_descriptor(witness: StageEntryAimWitness) -> String:
	return JSON.stringify(_witness_manifest_summary(witness))


func _witness_manifest_summary(witness: StageEntryAimWitness) -> Dictionary:
	if witness == null:
		return {}
	return {
		"predicted": _identity_manifest_summary(witness.predicted_identity),
		"physical": _identity_manifest_summary(witness.physical_identity),
	}


func _identity_manifest_summary(identity: TrajectoryHitIdentity) -> Dictionary:
	if identity == null:
		return {}
	return {
		"owner": String(identity.contact_owner_id),
		"shape": String(identity.contact_shape_id),
		"body_shape": identity.body_shape_index,
		"cell_x": identity.terrain_cell.x,
		"cell_y": identity.terrain_cell.y,
		"triangle": identity.terrain_triangle,
	}


func _witness_manifest_matches(value: Variant, witness: StageEntryAimWitness) -> bool:
	if not value is Dictionary:
		return false
	if witness == null:
		return value.is_empty()
	if value.size() != 2 or not value.has("predicted") or not value.has("physical"):
		return false
	return _identity_manifest_matches(value.get("predicted", {}), witness.predicted_identity) \
			and _identity_manifest_matches(value.get("physical", {}), witness.physical_identity)


func _identity_manifest_matches(value: Variant, identity: TrajectoryHitIdentity) -> bool:
	if not value is Dictionary:
		return false
	if identity == null:
		return value.is_empty()
	if value.size() != 6:
		return false
	return String(value.get("owner", "")) == String(identity.contact_owner_id) \
			and String(value.get("shape", "")) == String(identity.contact_shape_id) \
			and _manifest_integer_matches(
				value.get("body_shape"), identity.body_shape_index
			) \
			and _manifest_integer_matches(value.get("cell_x"), identity.terrain_cell.x) \
			and _manifest_integer_matches(value.get("cell_y"), identity.terrain_cell.y) \
			and _manifest_integer_matches(value.get("triangle"), identity.terrain_triangle)


func _manifest_integer_matches(value: Variant, expected: int) -> bool:
	if not value is int and not value is float:
		return false
	return float(value) == float(expected)


func _replace_catalog_pointer(staging_path: String, destination_path: String) -> Error:
	var staging_absolute := ProjectSettings.globalize_path(staging_path)
	var destination_absolute := ProjectSettings.globalize_path(destination_path)
	if not FileAccess.file_exists(staging_absolute):
		return ERR_FILE_NOT_FOUND
	if not FileAccess.file_exists(destination_absolute):
		return DirAccess.rename_absolute(staging_absolute, destination_absolute)
	# Windows does not replace an existing destination with rename. Preserve the
	# live pointer until the staging resource is ready, then restore it on failure.
	var backup_absolute := "%s.%d.previous" % [destination_absolute, Time.get_ticks_usec()]
	var backup_error := DirAccess.rename_absolute(destination_absolute, backup_absolute)
	if backup_error != OK:
		return backup_error
	var replace_error := DirAccess.rename_absolute(staging_absolute, destination_absolute)
	if replace_error != OK:
		var restore_error := _restore_catalog_pointer(backup_absolute, destination_absolute)
		return restore_error if restore_error != OK else replace_error
	DirAccess.remove_absolute(backup_absolute)
	return OK


static func _restore_catalog_pointer(backup_absolute: String, destination_absolute: String) -> Error:
	if FileAccess.file_exists(destination_absolute):
		return OK
	var rename_error := DirAccess.rename_absolute(backup_absolute, destination_absolute)
	if rename_error == OK and FileAccess.file_exists(destination_absolute):
		return OK
	# Keep the recoverable backup when rename cannot restore it. A verified copy
	# is the last safe recovery step that leaves the live pointer present on Windows.
	var copy_error := DirAccess.copy_absolute(backup_absolute, destination_absolute)
	if copy_error == OK and FileAccess.file_exists(destination_absolute):
		return OK
	push_error(
		"Catalog pointer restore failed; recoverable backup remains at %s." \
				% backup_absolute
	)
	return copy_error if copy_error != OK else rename_error


static func _catalog_staging_path() -> String:
	return "res://resources/stages/.catalog-%s.staging.tres" % \
			StageGenerationContract.version_tag()


static func _progression_path() -> String:
	return "res://resources/stage_generation/version%d_progression.tres" % \
			StageGenerationContract.CONTRACT_VERSION
