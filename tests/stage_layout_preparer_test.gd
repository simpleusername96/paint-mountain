extends SceneTree

const STAGE_LAYOUT_PREPARER_SCRIPT := preload("res://src/app/stage_layout_preparer.gd")
const LAYOUT_TIMEOUT_MS := 45000

class TestLayoutStrategy extends RefCounted:
	func generate(stage: StageData) -> GeneratedStageLayout:
		OS.delay_msec(5)
		var layout := GeneratedStageLayout.new()
		layout.profile_id = stage.generation_profile.profile_id
		layout.profile_version = stage.generation_profile.profile_version
		layout.layout_version = stage.generation_profile.generation_contract.layout_version
		layout.terrain_seed = stage.terrain_seed \
				if stage.terrain_seed != 0 else stage.generation_profile.base_seed
		layout.checksum = stage.stage_number + 1
		return layout

	func matches(layout: GeneratedStageLayout, stage: StageData) -> bool:
		if layout == null or stage == null or stage.generation_profile == null:
			return false
		var expected_seed := stage.terrain_seed \
				if stage.terrain_seed != 0 else stage.generation_profile.base_seed
		return layout.profile_id == stage.generation_profile.profile_id \
				and layout.profile_version == stage.generation_profile.profile_version \
				and layout.layout_version \
						== stage.generation_profile.generation_contract.layout_version \
				and layout.terrain_seed == expected_seed \
				and layout.checksum == stage.stage_number + 1


var _failed := false
var _failed_stage_ids: Array[StringName] = []
var _previous_max_fps := 0


func _initialize() -> void:
	_previous_max_fps = Engine.max_fps
	Engine.max_fps = 60
	call_deferred("_run_checks")


func _run_checks() -> void:
	var layout_strategy := TestLayoutStrategy.new()
	var preparer := STAGE_LAYOUT_PREPARER_SCRIPT.new(layout_strategy) as StageLayoutPreparer
	preparer.name = "StageLayoutPreparerUnderTest"
	root.add_child(preparer)
	preparer.layout_failed.connect(func(stage_id: StringName) -> void:
		_failed_stage_ids.append(stage_id)
	)
	var stages := _test_stages()

	var first_stage := stages[0]
	_assert_true(
		not preparer.request_layout(first_stage, true),
		"a cold request must report that its layout is not ready"
	)
	_assert_true(
		preparer.ready_layout(first_stage) == null and preparer.is_preparing(first_stage.stage_id),
		"a cold request must return immediately while one worker owns generation"
	)

	for index in range(4):
		var stage := stages[index]
		preparer.request_layout(stage, true)
		var layout := await _wait_for_layout(preparer, stage)
		_assert_true(
			layout_strategy.matches(layout, stage),
			"prepared layout %s must match its immutable stage identity" % stage.stage_id
		)

	_assert_true(
		_failed_stage_ids.is_empty(),
		"valid stage identities must not emit layout preparation failures"
	)
	_assert_true(
		preparer.cached_layout_count() == STAGE_LAYOUT_PREPARER_SCRIPT.MAX_CACHED_LAYOUTS,
		"the layout cache must stay bounded to three entries"
	)
	_assert_true(
		preparer.ready_layout(first_stage) == null,
		"the least-recently-used layout must be evicted after a fourth stage"
	)
	for index in range(1, 4):
		_assert_true(
			preparer.ready_layout(stages[index]) != null,
			"the three most recently prepared layouts must remain cached"
		)

	if not _failed:
		print("Stage layout preparation passed: non-blocking worker, identity, and 3-entry LRU cache.")
	await _finish(preparer)


func _test_stages() -> Array[StageData]:
	var result: Array[StageData] = []
	for index in range(4):
		var profile := StageGenerationProfile.new()
		profile.profile_id = StringName("test_stage_%02d_v7" % (index + 1))
		profile.profile_version = StageGenerationContract.CONTRACT_VERSION
		profile.base_seed = 1000 + index
		profile.generation_contract = StageGenerationContract.new()
		var stage := StageData.new()
		stage.stage_id = StringName("test_stage_%02d" % (index + 1))
		stage.stage_version = StageGenerationContract.CONTRACT_VERSION
		stage.stage_number = index + 1
		stage.generation_profile = profile
		stage.terrain_seed = 2000 + index
		result.append(stage)
	return result


func _wait_for_layout(
		preparer: StageLayoutPreparer,
		stage: StageData
) -> GeneratedStageLayout:
	var deadline := Time.get_ticks_msec() + LAYOUT_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		var layout := preparer.ready_layout(stage)
		if layout != null:
			return layout
		await create_timer(0.01).timeout
	return null


func _finish(preparer: StageLayoutPreparer) -> void:
	preparer.queue_free()
	await process_frame
	Engine.max_fps = _previous_max_fps
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
