class_name StageLayoutRepository
extends Node

## App-owned immutable baked-layout loader. It never generates or solves.
signal layout_ready(stage_id: StringName, layout: GeneratedStageLayout)
signal layout_failed(stage_id: StringName)

const MAX_CACHED_LAYOUTS := 3

## Hydration validates immutable persisted data and constructs RefCounted layout
## objects only. Scene-tree, renderer, physics, mesh, and texture work stay on
## the main thread after publication.
class HydrationJob extends RefCounted:
	var baked: BakedStageLayoutData
	var stage: StageData

	func _init(job_baked: BakedStageLayoutData, job_stage: StageData) -> void:
		baked = job_baked
		stage = job_stage

	func run() -> GeneratedStageLayout:
		return StageLayoutBakeCodec.hydrate(baked, stage)


var _active_selected_request: Dictionary = {}
var _active_prefetch_request: Dictionary = {}
var _queued_selected_request: Dictionary = {}
var _queued_prefetch_request: Dictionary = {}
var _hydration_worker: Thread
var _active_hydration_job: HydrationJob
var _active_hydration_request: Dictionary = {}
var _queued_selected_hydration: Dictionary = {}
var _queued_prefetch_hydration: Dictionary = {}
var _desired_selected_stage_id: StringName = &""
var _layout_cache: Dictionary = {}
var _least_recently_used: Array[StringName] = []


func _process(_delta: float) -> void:
	_collect_finished_hydration()
	_poll_active_request(true)
	_poll_active_request(false)
	_start_queued_requests()
	_start_next_hydration()


## A selection and a prefetch can load independently. ResourceLoader requests
## cannot be cancelled, so each role retains one active handle and one latest
## queued desire until the active work has been polled to completion.
func request_layout(stage: StageData, layout_path: String, selected: bool = true) -> bool:
	if stage == null:
		return false
	if selected:
		nominate_selected_stage(stage)
	if ready_layout(stage) != null:
		return true
	if layout_path.is_empty():
		layout_failed.emit(stage.stage_id)
		return false
	var request := _request_for(stage, layout_path)
	if selected:
		if _request_matches(_active_selected_request, stage, layout_path):
			_queued_selected_request = {}
			return false
		if _request_matches(_queued_selected_request, stage, layout_path):
			return false
		if _request_matches(_active_prefetch_request, stage, layout_path):
			# Keep both outstanding handles, but make the requested one authoritative.
			var previous_selected := _active_selected_request
			_active_selected_request = _active_prefetch_request
			_active_prefetch_request = previous_selected
			_queued_selected_request = {}
			return false
		if _active_selected_request.is_empty():
			return _start_request(request, true)
		_queued_selected_request = request
	else:
		if _request_matches(_active_prefetch_request, stage, layout_path) \
				or _request_matches(_queued_prefetch_request, stage, layout_path) \
				or _request_matches(_active_selected_request, stage, layout_path) \
				or _request_matches(_queued_selected_request, stage, layout_path):
			return false
		if _active_prefetch_request.is_empty():
			return _start_request(request, false)
		_queued_prefetch_request = request
	return false


## Records the latest selected identity even when a downstream artifact cache
## means no persisted layout request is necessary.
func nominate_selected_stage(stage: StageData) -> void:
	if stage != null:
		_desired_selected_stage_id = stage.stage_id


func ready_layout(stage: StageData) -> GeneratedStageLayout:
	if stage == null:
		return null
	var cached := _layout_cache.get(stage.stage_id) as GeneratedStageLayout
	if cached == null or not _layout_matches_stage(cached, stage):
		_layout_cache.erase(stage.stage_id)
		_least_recently_used.erase(stage.stage_id)
		return null
	_touch(stage.stage_id)
	return cached


func is_preparing(stage_id: StringName) -> bool:
	return _request_stage_id(_active_selected_request) == stage_id \
			or _request_stage_id(_active_prefetch_request) == stage_id \
			or _request_stage_id(_queued_selected_request) == stage_id \
			or _request_stage_id(_queued_prefetch_request) == stage_id \
			or _request_stage_id(_active_hydration_request) == stage_id \
			or _request_stage_id(_queued_selected_hydration) == stage_id \
			or _request_stage_id(_queued_prefetch_hydration) == stage_id


func active_request_count() -> int:
	return int(not _active_selected_request.is_empty()) + int(not _active_prefetch_request.is_empty())


func cached_layout_count() -> int:
	return _layout_cache.size()


func _poll_active_request(selected: bool) -> void:
	var request: Dictionary = _active_selected_request if selected else _active_prefetch_request
	if request.is_empty():
		return
	var path := String(request.path)
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(path, progress)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	if selected:
		_active_selected_request = {}
	else:
		_active_prefetch_request = {}
	var stage := request.stage as StageData
	if status != ResourceLoader.THREAD_LOAD_LOADED or stage == null:
		if selected and stage != null and _desired_selected_stage_id == stage.stage_id:
			layout_failed.emit(stage.stage_id)
		return
	var baked := ResourceLoader.load_threaded_get(path) as BakedStageLayoutData
	_queue_hydration(request, baked, selected)


func _queue_hydration(
		request: Dictionary,
		baked: BakedStageLayoutData,
		selected: bool
) -> void:
	var stage := request.get("stage") as StageData
	if selected and (stage == null or _desired_selected_stage_id != stage.stage_id):
		return
	var hydration_request := request.duplicate()
	hydration_request.baked = baked
	hydration_request.selected = selected
	if selected:
		_queued_selected_hydration = hydration_request
	else:
		_queued_prefetch_hydration = hydration_request
	_start_next_hydration()


func _start_next_hydration() -> void:
	if _hydration_worker != null:
		return
	var next_request: Dictionary = {}
	if not _queued_selected_hydration.is_empty():
		next_request = _queued_selected_hydration
		_queued_selected_hydration = {}
	elif not _queued_prefetch_hydration.is_empty():
		next_request = _queued_prefetch_hydration
		_queued_prefetch_hydration = {}
	if next_request.is_empty():
		return
	var stage := next_request.stage as StageData
	var baked := next_request.baked as BakedStageLayoutData
	if stage == null or baked == null:
		_publish_hydration_failure(next_request)
		_start_next_hydration.call_deferred()
		return
	_active_hydration_request = next_request
	_active_hydration_job = HydrationJob.new(baked, stage)
	_hydration_worker = Thread.new()
	var start_error := _hydration_worker.start(_active_hydration_job.run)
	if start_error == OK:
		return
	_hydration_worker = null
	_active_hydration_job = null
	_active_hydration_request = {}
	_publish_hydration_failure(next_request)
	_start_next_hydration.call_deferred()


func _collect_finished_hydration() -> void:
	if _hydration_worker == null or _hydration_worker.is_alive():
		return
	var completed_request := _active_hydration_request
	var layout := _hydration_worker.wait_to_finish() as GeneratedStageLayout
	_hydration_worker = null
	_active_hydration_job = null
	_active_hydration_request = {}
	var stage := completed_request.get("stage") as StageData
	if stage == null or not _layout_matches_stage(layout, stage):
		_publish_hydration_failure(completed_request)
		_start_next_hydration()
		return
	_cache_layout(stage.stage_id, layout)
	var selected := bool(completed_request.get("selected", false))
	# Obsolete selected work may finish and enter the bounded cache, but only the
	# latest selected identity may trigger preview/gameplay preparation.
	if not selected or _desired_selected_stage_id == stage.stage_id:
		layout_ready.emit(stage.stage_id, layout)
	_start_next_hydration()


func _publish_hydration_failure(request: Dictionary) -> void:
	var stage := request.get("stage") as StageData
	if stage == null:
		return
	var selected := bool(request.get("selected", false))
	if selected and _desired_selected_stage_id == stage.stage_id:
		layout_failed.emit(stage.stage_id)


func _start_queued_requests() -> void:
	if _active_selected_request.is_empty() and not _queued_selected_request.is_empty():
		var selected_request := _queued_selected_request
		_queued_selected_request = {}
		if _request_matches(_active_prefetch_request, selected_request.stage as StageData, String(selected_request.path)):
			_active_selected_request = _active_prefetch_request
			_active_prefetch_request = {}
		else:
			_start_request(selected_request, true)
	if _active_prefetch_request.is_empty() and not _queued_prefetch_request.is_empty():
		var prefetch_request := _queued_prefetch_request
		_queued_prefetch_request = {}
		_start_request(prefetch_request, false)


func _start_request(request: Dictionary, selected: bool) -> bool:
	var stage := request.stage as StageData
	var error := ResourceLoader.load_threaded_request(
		String(request.path), "", false, ResourceLoader.CACHE_MODE_REUSE
	)
	if error != OK:
		if selected and stage != null:
			layout_failed.emit(stage.stage_id)
		return false
	if selected:
		_active_selected_request = request
	else:
		_active_prefetch_request = request
	return false


func _request_for(stage: StageData, layout_path: String) -> Dictionary:
	return {"stage": stage, "path": layout_path}


func _request_matches(request: Dictionary, stage: StageData, layout_path: String) -> bool:
	return not request.is_empty() and request.get("path", "") == layout_path \
			and _same_stage_identity(request.get("stage") as StageData, stage)


func _request_stage_id(request: Dictionary) -> StringName:
	var stage := request.get("stage") as StageData
	return stage.stage_id if stage != null else &""


func _cache_layout(stage_id: StringName, layout: GeneratedStageLayout) -> void:
	_layout_cache[stage_id] = layout
	_touch(stage_id)
	while _least_recently_used.size() > MAX_CACHED_LAYOUTS:
		_layout_cache.erase(StringName(_least_recently_used.pop_front()))


func _touch(stage_id: StringName) -> void:
	_least_recently_used.erase(stage_id)
	_least_recently_used.append(stage_id)


func _same_stage_identity(left: StageData, right: StageData) -> bool:
	if left == null or right == null or left.generation_profile == null \
			or right.generation_profile == null:
		return false
	return left.stage_id == right.stage_id \
			and left.stage_version == right.stage_version \
			and left.terrain_seed == right.terrain_seed \
			and left.generation_profile.profile_id == right.generation_profile.profile_id \
			and left.generation_profile.profile_version == right.generation_profile.profile_version


func _layout_matches_stage(layout: GeneratedStageLayout, stage: StageData) -> bool:
	return layout != null and layout.matches_stage_identity(stage) and layout.is_runtime_ready() \
			and layout.terrain_seed == StageProgressionData.CANONICAL_TERRAIN_SEED \
			and stage.terrain_seed == StageProgressionData.CANONICAL_TERRAIN_SEED


func _exit_tree() -> void:
	if _hydration_worker != null and _hydration_worker.is_started():
		_hydration_worker.wait_to_finish()
	_hydration_worker = null
	_active_hydration_job = null
	_active_hydration_request = {}
