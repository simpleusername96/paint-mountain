extends SceneTree

## Headless-only offline certification entry point. It materializes each exact
## deterministic candidate, rejects on predictor or real-body parity failure,
## and writes a certificate only when --write-certificate is explicit.

const TERRAIN_SCENE := preload("res://tests/fixtures/terrain_surface_fixture.tscn")
const BACKSTOP_SCENE := preload("res://scenes/gameplay/backstop_environment.tscn")
const CANNON_SCENE := preload("res://scenes/gameplay/cannon.tscn")
const BURST_SCENE := preload("res://scenes/mechanisms/burst_node.tscn")
const SPLITTER_SCENE := preload("res://scenes/mechanisms/splitter_node.tscn")
const BUMPER_SCENE := preload("res://scenes/mechanisms/bumper_node.tscn")
const STAGE_PATHS := {
	&"first_descent": "res://resources/stages/first_descent.tres",
	&"burst_basin": "res://resources/stages/burst_basin.tres",
	&"split_ridge": "res://resources/stages/split_ridge.tres",
}
const CERTIFICATE_DIRECTORY := "res://resources/stages/certificates/"

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	var arguments := _parse_arguments()
	if not bool(arguments.valid):
		push_error("Stage generation certifier arguments are invalid: %s" % arguments.rejection)
		quit(2)
		return
	var stage_ids: Array[StringName] = arguments.stage_ids
	for stage_id in stage_ids:
		var stage := load(STAGE_PATHS[stage_id]) as StageData
		if stage == null:
			_failed = true
			push_error("Could not load stage %s." % stage_id)
			continue
		var result := await _certify_stage(stage)
		if not bool(result.get("valid", false)):
			_failed = true
			push_error("Certification failed for %s: %s" % [stage_id, str(result)])
			continue
		var certificate: DirectReachabilityCertificate = result.certificate
		if bool(arguments.verify_only):
			var expected_path := CERTIFICATE_DIRECTORY + "%s_v4.tres" % stage_id
			var expected := ResourceLoader.load(
				expected_path,
				"DirectReachabilityCertificate",
				ResourceLoader.CACHE_MODE_REPLACE
			) as DirectReachabilityCertificate
			if not DirectReachabilityValidator.certificate_matches(expected, certificate):
				_failed = true
				push_error("Stored certificate does not reproduce for %s." % stage_id)
				continue
		if not String(arguments.write_path).is_empty():
			var write_path := String(arguments.write_path)
			var directory := write_path.get_base_dir()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
			var save_error := ResourceSaver.save(certificate, write_path)
			if save_error != OK:
				_failed = true
				push_error("Could not save certificate %s: error %d." % [write_path, save_error])
				continue
		print(
			(
				"Certified %s: seed=%d attempt=%d target=%d witnesses=%d "
				+ "checksums=%d/%d/%d predictor_ms=%d rigidbody_ms=%d"
			) % [
				stage_id,
				result.layout.accepted_seed,
				result.layout.generation_attempt,
				result.predictor.target_count,
				certificate.witness_count(),
				certificate.reachable_target_checksum,
				certificate.predictor_reachability_checksum,
				certificate.rigidbody_reachability_checksum,
				result.predictor.elapsed_ms,
				result.rigidbody.elapsed_ms,
			]
		)
	quit(1 if _failed else 0)


func _certify_stage(stage: StageData) -> Dictionary:
	if stage.generation_profile == null or not stage.generation_profile.is_valid():
		return {"valid": false, "rejection": &"invalid_stage_profile"}
	var profile := stage.generation_profile
	var contract := profile.generation_contract
	var candidates: Array[Dictionary] = []
	for attempt_index in range(contract.attempt_count):
		candidates.append({
			"attempt": attempt_index,
			"seed": int((stage.terrain_seed + attempt_index * contract.attempt_seed_stride) & 0x7fffffff),
		})
	candidates.append({"attempt": -1, "seed": profile.fallback_seed})
	var rejection_evidence: Array[Dictionary] = []
	for candidate in candidates:
		var layout := SeededStageGenerator._build_attempt(
			stage.stage_id,
			profile,
			stage.terrain_seed,
			int(candidate.seed),
			int(candidate.attempt)
		)
		if not SeededStageGenerator._validate(profile, layout) \
				or not SeededStageGenerator._finalize_layout(profile, stage, layout):
			rejection_evidence.append({
				"attempt": candidate.attempt,
				"seed": candidate.seed,
				"rejection": layout.metrics.get("rejection", &"structural") if layout != null else &"graph",
			})
			continue
		var materialized := await _materialize(stage, layout)
		if not bool(materialized.get("valid", false)):
			return materialized
		var certification_root: Node3D = materialized.certification_root
		var terrain_surface: TerrainSurface = materialized.terrain_surface
		var cannon: CannonController = materialized.cannon
		var containment_proof := ContainmentDomainProof.evaluate(
			cannon,
			layout.containment
		)
		if not bool(containment_proof.get("valid", false)):
			rejection_evidence.append({
				"attempt": candidate.attempt,
				"seed": candidate.seed,
				"rejection": containment_proof.get("rejection", &"containment_domain"),
				"containment_proof": containment_proof,
			})
			await _free_materialized(certification_root)
			continue
		var predictor := DirectReachabilityValidator.validate_predictor(
			root.get_world_3d().direct_space_state,
			cannon,
			terrain_surface,
			layout,
			layout.containment.containment_bounds,
			DirectReachabilityValidator.MAXIMUM_UNCOVERED_DIAGNOSTICS,
			func(progress: Dictionary) -> void:
				print(
					(
						"Reachability progress %s attempt=%d visited=%d witnesses=%d "
						+ "reused=%d predictor_calls=%d elapsed_ms=%d"
					) % [
						stage.stage_id,
						layout.generation_attempt,
						progress.visited_target_count,
						progress.witness_count,
						progress.reused_target_count,
						progress.predictor_call_count,
						progress.elapsed_ms,
					]
				)
		)
		if not bool(predictor.get("valid", false)):
			rejection_evidence.append({
				"attempt": candidate.attempt,
				"seed": candidate.seed,
				"rejection": predictor.get("rejection", &"predictor"),
				"uncovered_count": predictor.get("uncovered_count", 0),
				"visited_target_count": predictor.get("visited_target_count", 0),
				"uncovered_diagnostics": predictor.get("uncovered_diagnostics", []),
				"elapsed_ms": predictor.get("elapsed_ms", 0),
			})
			await _free_materialized(certification_root)
			continue
		var rigidbody := await DirectReachabilityValidator.validate_rigidbody_batches(
			self,
			certification_root,
			cannon,
			terrain_surface,
			layout,
			layout.containment.containment_bounds,
			predictor
		)
		if not bool(rigidbody.get("valid", false)):
			rejection_evidence.append({
				"attempt": candidate.attempt,
				"seed": candidate.seed,
				"rejection": rigidbody.get("rejection", &"rigidbody"),
				"failure_diagnostics": rigidbody.get("failure_diagnostics", []),
				"elapsed_ms": rigidbody.get("elapsed_ms", 0),
			})
			await _free_materialized(certification_root)
			continue
		var certificate := DirectReachabilityValidator.build_certificate(
			stage.stage_id,
			layout,
			predictor,
			rigidbody
		)
		await _free_materialized(certification_root)
		if certificate == null:
			return {"valid": false, "rejection": &"certificate_build"}
		return {
			"valid": true,
			"layout": layout,
			"predictor": predictor,
			"rigidbody": rigidbody,
			"containment_proof": containment_proof,
			"certificate": certificate,
			"rejections": rejection_evidence,
		}
	return {
		"valid": false,
		"rejection": &"all_candidates_rejected",
		"rejections": rejection_evidence,
	}


func _materialize(stage: StageData, layout: GeneratedStageLayout) -> Dictionary:
	var certification_root := Node3D.new()
	certification_root.name = "StageGenerationCertificationRoot"
	root.add_child(certification_root)

	var terrain_surface := TERRAIN_SCENE.instantiate() as TerrainSurface
	terrain_surface.name = "TerrainSurface"
	terrain_surface.position = stage.terrain_center
	certification_root.add_child(terrain_surface)
	terrain_surface.configure(layout)

	var backstop := BACKSTOP_SCENE.instantiate() as BackstopEnvironment
	backstop.name = "BackstopEnvironment"
	certification_root.add_child(backstop)
	backstop.configure(
		layout.containment,
		stage.paint_world_bounds(),
		stage.terrain_center.y + TerrainGeometryFactory.DEFAULT_BASE_Y
	)

	var cannon := CANNON_SCENE.instantiate() as CannonController
	cannon.name = "Cannon"
	certification_root.add_child(cannon)
	cannon.global_transform = stage.cannon_transform

	var mechanisms := Node3D.new()
	mechanisms.name = "Mechanisms"
	certification_root.add_child(mechanisms)
	for placement_index in range(layout.mechanism_placements.size()):
		var placement := layout.mechanism_placements[placement_index]
		var packed_scene := _mechanism_scene(placement.mechanism_data.kind)
		if packed_scene == null:
			await _free_materialized(certification_root)
			return {"valid": false, "rejection": &"mechanism_scene"}
		var mechanism := packed_scene.instantiate() as GimmickBase
		mechanism.name = "CertificationMechanism%02d" % placement_index
		mechanism.data = placement.mechanism_data
		mechanism.transform = placement.local_transform
		mechanism.position += stage.terrain_center
		mechanisms.add_child(mechanism)

	await physics_frame
	return {
		"valid": true,
		"certification_root": certification_root,
		"terrain_surface": terrain_surface,
		"cannon": cannon,
	}


func _free_materialized(certification_root: Node3D) -> void:
	if is_instance_valid(certification_root):
		certification_root.queue_free()
	await physics_frame


func _mechanism_scene(kind: MechanismData.Kind) -> PackedScene:
	match kind:
		MechanismData.Kind.BURST:
			return BURST_SCENE
		MechanismData.Kind.SPLITTER:
			return SPLITTER_SCENE
		MechanismData.Kind.BUMPER:
			return BUMPER_SCENE
	return null


func _parse_arguments() -> Dictionary:
	var stage_value := "first_descent"
	var verify_only := false
	var write_path := ""
	var seen: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if argument == "--verify-only":
			if seen.has("verify"):
				return {"valid": false, "rejection": &"duplicate_verify"}
			seen["verify"] = true
			verify_only = true
		elif argument.begins_with("--stage="):
			if seen.has("stage"):
				return {"valid": false, "rejection": &"duplicate_stage"}
			seen["stage"] = true
			stage_value = argument.trim_prefix("--stage=")
		elif argument.begins_with("--write-certificate="):
			if seen.has("write"):
				return {"valid": false, "rejection": &"duplicate_write"}
			seen["write"] = true
			write_path = argument.trim_prefix("--write-certificate=")
		else:
			return {"valid": false, "rejection": &"unknown_argument"}
	if verify_only and not write_path.is_empty():
		return {"valid": false, "rejection": &"verify_and_write"}
	var stage_ids: Array[StringName] = []
	if stage_value == "all":
		stage_ids.assign(STAGE_PATHS.keys())
	else:
		var stage_id := StringName(stage_value)
		if not STAGE_PATHS.has(stage_id):
			return {"valid": false, "rejection": &"unknown_stage"}
		stage_ids.append(stage_id)
	if not write_path.is_empty():
		if stage_ids.size() != 1 or not write_path.begins_with(CERTIFICATE_DIRECTORY) \
				or write_path != CERTIFICATE_DIRECTORY + "%s_v4.tres" % stage_ids[0]:
			return {"valid": false, "rejection": &"invalid_write_path"}
	return {
		"valid": true,
		"stage_ids": stage_ids,
		"verify_only": verify_only,
		"write_path": write_path,
	}
