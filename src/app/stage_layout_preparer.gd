class_name StageLayoutPreparer
extends Node

signal layout_ready(stage_id: StringName, layout: GeneratedStageLayout)
signal layout_failed(stage_id: StringName)

const MAX_CACHED_LAYOUTS := 3

## The worker calls this RefCounted job, never the scene-tree-owned preparer.
## Production jobs construct data only; render and physics objects stay main-thread.
class LayoutJob extends RefCounted:
	var stage: StageData
	var layout_strategy: RefCounted

	func _init(job_stage: StageData, job_layout_strategy: RefCounted = null) -> void:
		stage = job_stage
		layout_strategy = job_layout_strategy

	func run() -> GeneratedStageLayout:
		if layout_strategy != null:
			if not layout_strategy.has_method(&"generate"):
				return null
			return layout_strategy.call(&"generate", stage) as GeneratedStageLayout
		return SeededStageGenerator.generate(
			stage.generation_profile,
			stage.terrain_seed,
			stage
		)


var _worker: Thread
var _active_job: LayoutJob
var _active_stage: StageData
var _urgent_stage: StageData
var _prefetch_stage: StageData
var _layout_cache: Dictionary = {}
var _least_recently_used: Array[StringName] = []
var _layout_strategy: RefCounted


func _init(layout_strategy: RefCounted = null) -> void:
	_layout_strategy = layout_strategy


func _process(_delta: float) -> void:
	_collect_finished_worker()


## Queues immutable layout preparation. Urgent requests replace stale queued
## selection work, while the single low-priority slot is reserved for prefetch.
func request_layout(stage: StageData, urgent: bool = true) -> bool:
	if stage == null or stage.generation_profile == null:
		return false
	if ready_layout(stage) != null:
		if urgent:
			_urgent_stage = null
		else:
			_prefetch_stage = null
		return true
	if _same_stage_identity(_active_stage, stage):
		if urgent:
			_urgent_stage = null
		else:
			_prefetch_stage = null
		return false
	if urgent:
		_urgent_stage = stage
		if _same_stage_identity(_prefetch_stage, stage):
			_prefetch_stage = null
	else:
		_prefetch_stage = stage
	_start_next_worker()
	return false


func ready_layout(stage: StageData) -> GeneratedStageLayout:
	if stage == null:
		return null
	var cached := _layout_cache.get(stage.stage_id) as GeneratedStageLayout
	if cached == null:
		return null
	if not _layout_matches_stage(cached, stage):
		_layout_cache.erase(stage.stage_id)
		_least_recently_used.erase(stage.stage_id)
		return null
	_touch(stage.stage_id)
	return cached


func is_preparing(stage_id: StringName) -> bool:
	return (_active_stage != null and _active_stage.stage_id == stage_id) \
			or (_urgent_stage != null and _urgent_stage.stage_id == stage_id) \
			or (_prefetch_stage != null and _prefetch_stage.stage_id == stage_id)


func cached_layout_count() -> int:
	return _layout_cache.size()


func _start_next_worker() -> void:
	if _worker != null:
		return
	var next_stage := _urgent_stage
	if next_stage != null:
		_urgent_stage = null
	else:
		next_stage = _prefetch_stage
		_prefetch_stage = null
	if next_stage == null:
		return
	_active_stage = next_stage
	_active_job = LayoutJob.new(next_stage, _layout_strategy)
	_worker = Thread.new()
	var start_error := _worker.start(_active_job.run)
	if start_error == OK:
		return
	var failed_stage_id := next_stage.stage_id
	_worker = null
	_active_job = null
	_active_stage = null
	layout_failed.emit(failed_stage_id)
	_start_next_worker.call_deferred()


func _collect_finished_worker() -> void:
	if _worker == null or _worker.is_alive():
		return
	var completed_stage := _active_stage
	var completed_layout := _worker.wait_to_finish() as GeneratedStageLayout
	_worker = null
	_active_job = null
	_active_stage = null
	if completed_stage != null \
			and completed_layout != null \
			and _layout_matches_stage(completed_layout, completed_stage):
		_cache_layout(completed_stage.stage_id, completed_layout)
		layout_ready.emit(completed_stage.stage_id, completed_layout)
	elif completed_stage != null:
		layout_failed.emit(completed_stage.stage_id)
	_start_next_worker()


func _cache_layout(stage_id: StringName, layout: GeneratedStageLayout) -> void:
	_layout_cache[stage_id] = layout
	_touch(stage_id)
	while _least_recently_used.size() > MAX_CACHED_LAYOUTS:
		var evicted_stage_id := StringName(_least_recently_used.pop_front())
		_layout_cache.erase(evicted_stage_id)


func _touch(stage_id: StringName) -> void:
	_least_recently_used.erase(stage_id)
	_least_recently_used.append(stage_id)


func _same_stage_identity(left: StageData, right: StageData) -> bool:
	if left == null or right == null \
			or left.generation_profile == null or right.generation_profile == null:
		return false
	return left.stage_id == right.stage_id \
			and left.stage_version == right.stage_version \
			and left.terrain_seed == right.terrain_seed \
			and left.generation_profile.profile_id == right.generation_profile.profile_id \
			and left.generation_profile.profile_version == right.generation_profile.profile_version


func _layout_matches_stage(layout: GeneratedStageLayout, stage: StageData) -> bool:
	if _layout_strategy != null:
		if not _layout_strategy.has_method(&"matches"):
			return false
		return bool(_layout_strategy.call(&"matches", layout, stage))
	return layout != null and layout.matches_stage_identity(stage)


func _exit_tree() -> void:
	if _worker != null and _worker.is_started():
		_worker.wait_to_finish()
	_worker = null
	_active_job = null
	_active_stage = null
