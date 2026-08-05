extends SceneTree

## Offline catalog writer. The first version deliberately emits the typed
## catalog pointer from the already-reviewed deterministic profile builder; the
## runtime then consumes only the serialized result.

const CATALOG_PATH := "res://resources/stages/catalog.tres"
const BUNDLE_FORMAT_VERSION := 3
const CATALOG_DATA_SCRIPT := preload("res://src/stage/stage_catalog_data.gd")
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
	var write := "--write" in OS.get_cmdline_user_args()
	var dry_build := "--dry-build" in OS.get_cmdline_user_args()
	var catalog = _build_catalog()
	if catalog == null or not catalog.is_valid(false):
		push_error("Stage catalog build failed validation.")
		quit(1)
		return
	if dry_build:
		print("Stage catalog dry build passed: %d stages manifest=%s" % [
			catalog.stages.size(), catalog.manifest_sha256,
		])
		quit()
		return
	if not write:
		var existing = load(CATALOG_PATH)
		if existing == null or not existing.is_valid() \
				or existing.manifest_sha256 != catalog.manifest_sha256:
			push_error("Serialized catalog pointer is missing or differs from the deterministic build.")
			quit(1)
			return
		print("Stage catalog check passed: %d stages manifest=%s" % [catalog.stages.size(), catalog.manifest_sha256])
		quit()
		return
	if not _write_bundle_manifest(catalog):
		push_error("Could not promote the content-addressed stage bundle.")
		quit(1)
		return
	var staging_path := _catalog_staging_path()
	var staging_error := ResourceSaver.save(catalog, staging_path)
	if staging_error != OK:
		push_error("Could not write catalog staging resource: %s" % staging_error)
		quit(1)
		return
	var promoted := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(staging_path),
		ProjectSettings.globalize_path(CATALOG_PATH)
	)
	if promoted != OK:
		push_error("Could not promote catalog resource: %s" % promoted)
		quit(1)
		return
	print("Stage catalog written: %s manifest=%s" % [CATALOG_PATH, catalog.manifest_sha256])
	quit()


func _build_catalog():
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
			return null
	var manifest_parts: Array[String] = []
	for source_index in range(StageProgressionData.STAGE_COUNT):
		var stage := _materialize_stage(source_stages[source_index], source_index + 1)
		if stage == null:
			return null
		result.stage_ids.append(stage.stage_id)
		result.stages.append(stage.duplicate(true) as StageData)
		manifest_parts.append(_manifest_stage_descriptor(stage))
	manifest_parts.append("bundle_format=%d" % BUNDLE_FORMAT_VERSION)
	result.manifest_sha256 = _sha256("\n".join(manifest_parts))
	result.bundle_manifest_path = CATALOG_DATA_SCRIPT.generated_bundle_manifest_path(
		result.manifest_sha256
	)
	return result


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
	stage.terrain_seed = StageProgressionData.requested_seed_for(stage_number)
	stage.terrain_size = StageProgressionData.terrain_size_for(stage_number)
	# Keep the rear edge of every persisted terrain at the fixed wall join while
	# the stage grows toward the cannon. Leaving the StageData default here makes
	# Stage 02/03 apron geometry use a one/two-metre-shifted join and fail closed
	# before reachability can even be evaluated.
	stage.terrain_center = Vector3(
		0.0,
		-2.0,
		-172.0 + stage.terrain_size.y * 0.5
	)
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
				stage.generation_profile, stage.mechanism_loadout
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
	profile.fallback_seed = StageProgressionData.candidate_seed_for(stage_number, 31)
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
	var three_route_fallback_kinds := [
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
			kind = three_route_fallback_kinds[index % three_route_fallback_kinds.size()]
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
		loadout: Array[MechanismData]
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
			pad_ts.append(float(source_slot.get("t", -1.0)))
			pad_radii.append(_mechanism_pad_radius(kind))
			loadout_index += 1
		route.mechanism_kind = -1
		route.mechanism_pad_t = -1.0
		route.mechanism_pad_radius = 0.0
		route.mechanism_kinds = kinds
		route.mechanism_pad_ts = pad_ts
		route.mechanism_pad_radii = pad_radii
	return loadout_index == loadout.size()


static func _mechanism_pad_radius(kind: MechanismData.Kind) -> float:
	match int(kind):
		int(MechanismData.Kind.SPLITTER):
			return 10.0
		int(MechanismData.Kind.UPHILL_REBOUND):
			# This glyph conforms to a natural slope. Even a small shelf can erase
			# the nearby ascent witness or create a sharp ring around the decal.
			return 0.25
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


func _write_bundle_manifest(catalog) -> bool:
	var bundle_root := CATALOG_DATA_SCRIPT.generated_bundle_root(catalog.manifest_sha256)
	var final_absolute := ProjectSettings.globalize_path(bundle_root)
	var final_manifest_path := "%s/manifest.json" % bundle_root
	# A matching immutable bundle is already the desired output. Never rewrite it
	# in place: the catalog pointer can continue to refer to the old bundle if a
	# later write fails.
	if DirAccess.dir_exists_absolute(final_absolute):
		if FileAccess.file_exists(ProjectSettings.globalize_path(final_manifest_path)):
			return true
		push_error("Refusing to overwrite an incomplete content-addressed bundle: %s" % bundle_root)
		return false
	var staging_root := "res://resources/generated_stage_catalogs/.%s-%s.staging" % [
		StageGenerationContract.version_tag(), catalog.manifest_sha256,
	]
	var staging_absolute := ProjectSettings.globalize_path(staging_root)
	DirAccess.make_dir_recursive_absolute(staging_absolute)
	var bundle_catalog := "%s/catalog.tres" % staging_root
	if ResourceSaver.save(catalog, bundle_catalog) != OK:
		return false
	for subdirectory in ["stages", "profiles", "certificates", "previews"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [staging_root, subdirectory]))
	var certificate_paths: Array[String] = []
	var preview_paths: Array[String] = []
	for index in range(catalog.stages.size()):
		var stage: StageData = catalog.stages[index]
		var numeric_id := "stage_%02d" % maxi(stage.stage_number, index + 1)
		if ResourceSaver.save(stage, "%s/stages/%s.tres" % [staging_root, numeric_id]) != OK:
			return false
		if ResourceSaver.save(stage.generation_profile, "%s/profiles/%s_profile.tres" % [staging_root, numeric_id]) != OK:
			return false
		if stage.reachability_certificate != null:
			var certificate_path := "%s/certificates/%s_certificate.tres" % [staging_root, numeric_id]
			if ResourceSaver.save(stage.reachability_certificate, certificate_path) != OK:
				return false
			certificate_paths.append(certificate_path.trim_prefix("res://"))
	var manifest := {
		"catalog_version": catalog.catalog_version,
		"bundle_format": BUNDLE_FORMAT_VERSION,
		"manifest_sha256": catalog.manifest_sha256,
		"bundle_manifest_path": catalog.bundle_manifest_path,
		"stage_ids": catalog.stage_ids,
		"accepted_seeds": catalog.stages.map(func(stage: StageData) -> int: return stage.terrain_seed),
		"profile_ids": catalog.stages.map(func(stage: StageData) -> String: return String(stage.generation_profile.profile_id)),
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
	if DirAccess.rename_absolute(staging_absolute, final_absolute) != OK:
		push_error("Could not promote stage bundle %s" % bundle_root)
		return false
	return FileAccess.file_exists(ProjectSettings.globalize_path(final_manifest_path))


static func _catalog_staging_path() -> String:
	return "res://resources/stages/.catalog-%s.staging.tres" % \
			StageGenerationContract.version_tag()


static func _progression_path() -> String:
	return "res://resources/stage_generation/version%d_progression.tres" % \
			StageGenerationContract.CONTRACT_VERSION
