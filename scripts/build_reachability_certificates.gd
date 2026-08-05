extends SceneTree

## Offline target/summit certificate worker. It may inspect one stage for a
## bounded proof run, but it only writes a bundle after all thirty stages pass;
## partial results are never promoted or presented as runtime certificates.

const TERRAIN_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const BACKSTOP_SCENE := preload("res://scenes/gameplay/backstop_environment.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const CATALOG_PATH := "res://resources/stages/catalog.tres"
const OUTPUT_ROOT := "res://resources/generated_stage_certificates"

var _failed := false
var _results: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_ids := _requested_stage_ids()
	for stage_id in stage_ids:
		var stage := StageCatalog.get_stage(stage_id)
		if stage == null:
			push_error("Certificate worker could not resolve %s." % stage_id)
			_failed = true
			break
		var result := await _certify_stage(stage)
		if not bool(result.get("valid", false)):
			push_error("Certificate worker rejected %s: %s" % [stage_id, str(result)])
			_failed = true
			break
		_results[String(stage_id)] = result
		print(
			"Certificate stage passed: %s targets=%d witnesses=%d predictor_ms=%d rigidbody_ms=%d" % [
				stage_id,
				int(result.target_count),
				int(result.certificate.witness_count()),
				int(result.predictor_ms),
				int(result.rigidbody_ms),
			]
		)

	if not _failed and "--write" in OS.get_cmdline_user_args():
		if stage_ids.size() != StageProgressionData.STAGE_COUNT:
			push_error("Refusing to write a partial reachability bundle; select all thirty stages.")
			_failed = true
		elif not _write_bundle(stage_ids):
			push_error("Could not promote the complete reachability certificate bundle.")
			_failed = true
	quit(1 if _failed else 0)


func _certify_stage(stage: StageData) -> Dictionary:
	var layout := SeededStageGenerator.generate(
		stage.generation_profile,
		stage.terrain_seed,
		stage
	)
	if layout == null or not layout.is_valid() or not layout.has_valid_target_mask():
		return {"valid": false, "rejection": &"layout"}
	var fixture_root := Node3D.new()
	fixture_root.name = "ReachabilityCertificateFixture"
	root.add_child(fixture_root)
	var terrain_surface := TERRAIN_SCENE.instantiate() as TerrainSurface
	terrain_surface.position = stage.terrain_center
	fixture_root.add_child(terrain_surface)
	terrain_surface.configure(layout)
	var backstop := BACKSTOP_SCENE.instantiate() as BackstopEnvironment
	fixture_root.add_child(backstop)
	backstop.configure(layout.containment, stage.paint_world_bounds(), stage.terrain_center.y)
	var cannon := CANNON_SCENE.instantiate() as CannonController
	fixture_root.add_child(cannon)
	cannon.global_transform = stage.cannon_transform
	await physics_frame

	var summit := DirectReachabilityValidator.validate_summit(
		root.get_world_3d().direct_space_state,
		cannon,
		terrain_surface,
		layout,
		layout.containment.containment_bounds
	)
	if not bool(summit.get("valid", false)):
		fixture_root.queue_free()
		await physics_frame
		return {"valid": false, "rejection": &"summit", "summit": summit}
	var summit_rigidbody := await DirectReachabilityValidator.validate_rigidbody_batches(
		self,
		fixture_root,
		cannon,
		terrain_surface,
		layout,
		layout.containment.containment_bounds,
		summit
	)
	if not bool(summit_rigidbody.get("valid", false)):
		fixture_root.queue_free()
		await physics_frame
		return {"valid": false, "rejection": &"summit_rigidbody", "result": summit_rigidbody}

	var predictor := DirectReachabilityValidator.validate_predictor(
		root.get_world_3d().direct_space_state,
		cannon,
		terrain_surface,
		layout,
		layout.containment.containment_bounds,
		DirectReachabilityValidator.MAXIMUM_UNCOVERED_DIAGNOSTICS,
		func(progress: Dictionary) -> void:
			print(
				"Certificate progress %s: visited=%d witnesses=%d reused=%d predictor_calls=%d elapsed_ms=%d" % [
					stage.stage_id,
					int(progress.visited_target_count),
					int(progress.witness_count),
					int(progress.reused_target_count),
					int(progress.predictor_call_count),
					int(progress.elapsed_ms),
				]
			)
	)
	if not bool(predictor.get("valid", false)):
		fixture_root.queue_free()
		await physics_frame
		return {"valid": false, "rejection": &"predictor", "result": predictor}
	var rigidbody := await DirectReachabilityValidator.validate_rigidbody_batches(
		self,
		fixture_root,
		cannon,
		terrain_surface,
		layout,
		layout.containment.containment_bounds,
		predictor
	)
	if not bool(rigidbody.get("valid", false)):
		fixture_root.queue_free()
		await physics_frame
		return {"valid": false, "rejection": &"rigidbody", "result": rigidbody}
	var certificate := DirectReachabilityValidator.build_certificate(
		stage.stage_id,
		layout,
		predictor,
		rigidbody,
		summit,
		summit_rigidbody
	)
	var target_count := int(predictor.get("target_count", 0))
	var certificate_valid: bool = certificate != null and certificate.is_valid() \
			and predictor.target_witness_indices.size() == target_count
	fixture_root.queue_free()
	await physics_frame
	if not certificate_valid:
		return {
			"valid": false,
			"rejection": &"certificate_integrity",
			"target_count": target_count,
		}
	return {
		"valid": true,
		"certificate": certificate,
		"target_count": target_count,
		"predictor_ms": int(predictor.get("elapsed_ms", 0)),
		"rigidbody_ms": int(rigidbody.get("elapsed_ms", 0)),
	}


func _write_bundle(stage_ids: Array[StringName]) -> bool:
	var catalog := load(CATALOG_PATH) as StageCatalogData
	if catalog == null or not catalog.is_valid() or _results.size() != stage_ids.size():
		return false
	var manifest_context := HashingContext.new()
	manifest_context.start(HashingContext.HASH_SHA256)
	for stage_id in stage_ids:
		var result: Dictionary = _results.get(String(stage_id), {})
		var certificate := result.get("certificate") as DirectReachabilityCertificate
		if certificate == null or not certificate.is_valid():
			return false
		manifest_context.update(
			("%s|%d|%d|%d" % [
				stage_id,
				certificate.reachable_target_checksum,
				certificate.predictor_reachability_checksum,
				certificate.rigidbody_reachability_checksum,
			]).to_utf8_buffer()
		)
	var bundle_hash := manifest_context.finish().hex_encode()
	var final_root := "%s/v7-%s" % [OUTPUT_ROOT, bundle_hash]
	var final_absolute := ProjectSettings.globalize_path(final_root)
	if DirAccess.dir_exists_absolute(final_absolute):
		return FileAccess.file_exists(ProjectSettings.globalize_path("%s/manifest.json" % final_root))
	var staging_root := "%s/.v7-%s.staging" % [OUTPUT_ROOT, bundle_hash]
	var staging_absolute := ProjectSettings.globalize_path(staging_root)
	DirAccess.make_dir_recursive_absolute(staging_absolute)
	var paths: Array[String] = []
	for stage_id in stage_ids:
		var certificate: DirectReachabilityCertificate = _results[String(stage_id)].certificate
		var relative_path := "%s/%s_certificate.tres" % [staging_root, stage_id]
		if ResourceSaver.save(certificate, relative_path) != OK:
			return false
		paths.append(relative_path.trim_prefix("res://"))
	var manifest := {
		"catalog_manifest_sha256": catalog.manifest_sha256,
		"certificate_bundle_sha256": bundle_hash,
		"stage_ids": stage_ids,
		"certificate_paths": paths,
		"previews_ready": false,
		"complete": true,
	}
	var file := FileAccess.open("%s/manifest.json" % staging_root, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest, "\t"))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(staging_absolute, final_absolute) == OK


func _requested_stage_ids() -> Array[StringName]:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			var requested := StageCatalog.canonical_id(StringName(argument.trim_prefix("--stage=")))
			return [requested]
	var ids: Array[StringName] = []
	for stage_id in StageCatalog.all_stage_ids():
		ids.append(stage_id)
	return ids
