extends SceneTree

## Offline deterministic balance search. Run headlessly with --fixed-fps 60.
const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const PAINT_THRESHOLD_BYTE := 46
const INDEX_MASK := 0x3ffff
const BEAM_WIDTH := 12
const CHECKPOINT_INTERVAL := 25

var _stage: StageData
var _gameplay: Node3D
var _controller: StageController
var _cannon: CannonController
var _agent: GameplayAgentApi
var _paint: PaintSystem
var _terrain: TerrainSurface
var _evaluated: Dictionary = {}
var _candidates: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_id: StringName = &"first_descent"
	var coarse_only := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			stage_id = StringName(argument.trim_prefix("--stage="))
		elif argument == "--coarse-only":
			coarse_only = true
	var game_state := root.get_node("/root/GameState")
	game_state.persistence_enabled = false
	var save_data: Dictionary = root.get_node("/root/SaveSystem").default_data()
	save_data.unlocked_stages = ["first_descent", "burst_basin", "split_ridge"]
	game_state.initialize_from_data(save_data)
	if not game_state.select_stage(stage_id):
		push_error("Unknown solution-search stage: %s" % stage_id)
		quit(1)
		return
	_stage = StageCatalog.get_stage(stage_id)
	_gameplay = GAMEPLAY_SCENE.instantiate()
	root.add_child(_gameplay)
	await physics_frame
	await physics_frame
	_controller = _gameplay.get_node("StageController")
	_cannon = _gameplay.get_node("Cannon")
	_agent = _gameplay.get_node("GameplayAgentApi")
	_paint = _gameplay.get_node("PaintSystem")
	_terrain = _gameplay.get_node("TerrainSurface")
	_controller.begin_aiming(StageController.ActionOrigin.DEBUG)
	_load_checkpoint()

	var coarse_shots: Array[Vector3] = []
	for yaw in range(-28, 29, 4):
		for elevation in range(18, 69, 4):
			for power in range(0, 101, 10):
				coarse_shots.append(Vector3(yaw, elevation, power))
	await _evaluate_shots(coarse_shots, "coarse")
	var coarse_result := _beam_search(_candidates)
	_print_result("coarse", coarse_result)

	if not coarse_only:
		var refined_shots := _refined_shots(coarse_result.centers)
		await _evaluate_shots(refined_shots, "refined")
		var refined_result := _beam_search(_candidates)
		_print_result("refined", refined_result)
		_write_result(refined_result)
	else:
		_write_result(coarse_result)
	game_state.persistence_enabled = true
	_gameplay.queue_free()
	await process_frame
	quit(0)


func _evaluate_shots(shots: Array[Vector3], phase: String) -> void:
	var attempted := 0
	for shot in shots:
		var key := _shot_key(shot)
		if _evaluated.has(key):
			continue
		_evaluated[key] = true
		attempted += 1
		var candidate := await _evaluate_shot(shot)
		if not candidate.is_empty():
			_candidates.append(candidate)
		if attempted % CHECKPOINT_INTERVAL == 0:
			_save_checkpoint(phase)
		if attempted % 100 == 0:
			print("%s %s: %d/%d evaluated, %d paint-producing candidates" % [
				_stage.stage_id, phase, attempted, shots.size(), _candidates.size()
			])
	_save_checkpoint(phase)


func _evaluate_shot(shot: Vector3) -> Dictionary:
	if not _agent.set_aim(shot.x, shot.y, shot.z):
		return {}
	var prediction := _cannon.current_prediction()
	if prediction == null or not prediction.is_fireable():
		return {}
	if prediction.kind == TrajectoryPrediction.Kind.BOUNDS_EXIT:
		return {}
	var collider := prediction.collider as Node
	if not _terrain.is_top_collider(collider):
		# Flat glyphs are resolved after a valid terrain-top traversal. A first hit
		# on any other collider cannot produce authoritative paint or activation.
		return {}
	if not _agent.fire():
		return {}
	var fired_observation := _controller.current_shot_observation()
	if fired_observation == null or fired_observation.shot_id <= 0:
		push_error("Solution search could not identify its fired shot observation: %s" % shot)
		quit(1)
		return {}
	var fired_shot_id := fired_observation.shot_id
	var budget := 60 * 26
	var sealed_observation: ShotObservation
	while sealed_observation == null and budget > 0:
		await physics_frame
		budget -= 1
		sealed_observation = _sealed_observation_for_shot(fired_shot_id)
	if budget <= 0:
		push_error("Solution search shot did not finish its initial flight: %s" % shot)
		quit(1)
		return {}
	var observation := sealed_observation.to_dictionary()
	var paint_bytes := _paint.paint_bytes_read_only().duplicate()
	var sparse := PackedInt32Array()
	for index in range(paint_bytes.size()):
		var value := int(paint_bytes[index])
		if value > 0:
			sparse.append((value << 18) | index)
	var result := {
		"shot": shot,
		"paint": sparse,
		"coverage": float(observation.get("coverage_gain", 0.0)),
		"mechanisms": observation.get("mechanism_activation_kinds", []).duplicate(),
		"penetration_guards": int(observation.get("penetration_guard_count", 0)),
	}
	_controller.restart(false, StageController.ActionOrigin.DEBUG)
	await process_frame
	await physics_frame
	if sparse.is_empty() and result.mechanisms.is_empty():
		return {}
	return result


func _sealed_observation_for_shot(shot_id: int) -> ShotObservation:
	for observation in _controller.sealed_shot_observations():
		if observation.shot_id == shot_id:
			return observation
	return null


func _beam_search(candidates: Array[Dictionary]) -> Dictionary:
	var empty_mask := PackedByteArray()
	empty_mask.resize(PaintSystem.MASK_SIZE * PaintSystem.MASK_SIZE)
	empty_mask.fill(0)
	var beam: Array[Dictionary] = [{
		"mask": empty_mask,
		"painted": 0,
		"coverage": 0.0,
		"mechanisms": {},
		"sequence": [],
	}]
	var retained_centers: Dictionary = {}
	var winner: Dictionary = {}
	for depth in range(1, _stage.maximum_shots + 1):
		var proposals: Array[Dictionary] = []
		for state in beam:
			for candidate in candidates:
				if _repeats_spent_burst(state.mechanisms, candidate.mechanisms):
					continue
				var painted := int(state.painted) + _newly_painted(state.mask, candidate.paint)
				var mechanisms: Dictionary = state.mechanisms.duplicate()
				for kind in candidate.mechanisms:
					mechanisms[int(kind)] = true
				var sequence: Array = state.sequence.duplicate()
				sequence.append(candidate.shot)
				proposals.append({
					"parent": state,
					"candidate": candidate,
					"painted": painted,
					"coverage": 100.0 * float(painted) / float(_paint.total_target_pixels()),
					"mechanisms": mechanisms,
					"sequence": sequence,
				})
		proposals.sort_custom(_state_precedes)
		if proposals.size() > BEAM_WIDTH:
			proposals.resize(BEAM_WIDTH)
		beam.clear()
		for proposal in proposals:
			var mask: PackedByteArray = proposal.parent.mask.duplicate()
			_apply_sparse(mask, proposal.candidate.paint)
			beam.append({
				"mask": mask,
				"painted": proposal.painted,
				"coverage": proposal.coverage,
				"mechanisms": proposal.mechanisms,
				"sequence": proposal.sequence,
			})
			for shot in proposal.sequence:
				retained_centers[_shot_key(shot)] = shot
		if not beam.is_empty():
			print("%s depth %d best %.3f%% mechanisms=%d sequence=%s" % [
				_stage.stage_id, depth, beam[0].coverage,
				_required_activation_count(beam[0].mechanisms), beam[0].sequence
			])
		for state in beam:
			if float(state.coverage) >= _stage.target_coverage and _has_all_required_mechanisms(state.mechanisms):
				winner = state
				break
		if not winner.is_empty():
			break
	return {"winner": winner, "beam": beam, "centers": retained_centers.values()}


func _refined_shots(centers: Array) -> Array[Vector3]:
	var shots_by_key: Dictionary = {}
	for center_variant in centers:
		var center: Vector3 = center_variant
		for yaw in range(int(center.x) - 4, int(center.x) + 5):
			if yaw < -28 or yaw > 28:
				continue
			for elevation in range(int(center.y) - 4, int(center.y) + 5):
				if elevation < 18 or elevation > 68:
					continue
				for power in range(int(center.z) - 10, int(center.z) + 11, 2):
					if power < 0 or power > 100:
						continue
					var shot := Vector3(yaw, elevation, power)
					shots_by_key[_shot_key(shot)] = shot
	var shots: Array[Vector3] = []
	for value in shots_by_key.values():
		shots.append(value)
	shots.sort_custom(_shot_precedes)
	return shots


func _newly_painted(mask: PackedByteArray, sparse: PackedInt32Array) -> int:
	var newly := 0
	for packed in sparse:
		var index := packed & INDEX_MASK
		var updated := mini(255, int(mask[index]) + (packed >> 18))
		if int(mask[index]) < PAINT_THRESHOLD_BYTE and updated >= PAINT_THRESHOLD_BYTE:
			newly += 1
	return newly


func _apply_sparse(mask: PackedByteArray, sparse: PackedInt32Array) -> void:
	for packed in sparse:
		var index := packed & INDEX_MASK
		mask[index] = mini(255, int(mask[index]) + (packed >> 18))


func _state_precedes(a: Dictionary, b: Dictionary) -> bool:
	if not is_equal_approx(float(a.coverage), float(b.coverage)):
		return float(a.coverage) > float(b.coverage)
	var a_required := _required_activation_count(a.mechanisms)
	var b_required := _required_activation_count(b.mechanisms)
	if a_required != b_required:
		return a_required > b_required
	return _sequence_precedes(a.sequence, b.sequence)


func _sequence_precedes(a: Array, b: Array) -> bool:
	for index in range(mini(a.size(), b.size())):
		var a_shot: Vector3 = a[index]
		var b_shot: Vector3 = b[index]
		if a_shot != b_shot:
			return _shot_precedes(a_shot, b_shot)
	return a.size() < b.size()


func _shot_precedes(a: Vector3, b: Vector3) -> bool:
	if not is_equal_approx(a.x, b.x):
		return a.x < b.x
	if not is_equal_approx(a.y, b.y):
		return a.y < b.y
	return a.z < b.z


func _required_activation_count(mechanisms: Dictionary) -> int:
	var count := 0
	for data in _stage.mechanism_loadout:
		if mechanisms.has(data.kind):
			count += 1
	return count


func _has_all_required_mechanisms(mechanisms: Dictionary) -> bool:
	return _required_activation_count(mechanisms) == _stage.mechanism_loadout.size()


func _repeats_spent_burst(existing: Dictionary, additions: Array) -> bool:
	return existing.has(MechanismData.Kind.BURST) and additions.has(MechanismData.Kind.BURST)


func _shot_key(shot: Vector3) -> String:
	return "%d/%d/%d" % [roundi(shot.x), roundi(shot.y), roundi(shot.z)]


func _print_result(label: String, result: Dictionary) -> void:
	if not result.winner.is_empty():
		print("%s %s winner %.3f%%: %s" % [
			_stage.stage_id, label, result.winner.coverage, result.winner.sequence
		])
	elif not result.beam.is_empty():
		print("%s %s failed; best %.3f%%: %s" % [
			_stage.stage_id, label, result.beam[0].coverage, result.beam[0].sequence
		])


func _write_result(result: Dictionary) -> void:
	var best: Dictionary = result.winner if not result.winner.is_empty() else result.beam[0]
	var output := {
		"stage_id": String(_stage.stage_id),
		"target": _stage.target_coverage,
		"coverage": best.coverage,
		"mechanisms": best.mechanisms.keys(),
		"sequence": best.sequence,
		"evaluated_shots": _evaluated.size(),
	}
	var directory := ProjectSettings.globalize_path("res://.godot/solution-search")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory.path_join("%s.json" % _stage.stage_id), FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  "))
	file.close()


func _checkpoint_path() -> String:
	return "res://.godot/solution-search/%s.checkpoint" % _stage.stage_id


func _load_checkpoint() -> void:
	var path := _checkpoint_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var checkpoint = file.get_var()
	file.close()
	if not checkpoint is Dictionary \
			or checkpoint.get("stage_id", "") != String(_stage.stage_id) \
			or int(checkpoint.get("physics_hz", 0)) != 60:
		return
	_evaluated = checkpoint.get("evaluated", {}).duplicate()
	_candidates.assign(checkpoint.get("candidates", []))
	print("%s resumed %d evaluated shots and %d candidates" % [
		_stage.stage_id, _evaluated.size(), _candidates.size()
	])


func _save_checkpoint(phase: String) -> void:
	var directory := ProjectSettings.globalize_path("res://.godot/solution-search")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(_checkpoint_path(), FileAccess.WRITE)
	file.store_var({
		"stage_id": String(_stage.stage_id),
		"physics_hz": 60,
		"phase": phase,
		"evaluated": _evaluated,
		"candidates": _candidates,
	})
	file.close()
