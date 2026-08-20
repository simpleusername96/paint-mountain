extends SceneTree

const EXPECTED_STAGE_COUNT := 30
const EXPECTED_DEAL_COUNT := 480

var _failed := false


func _initialize() -> void:
	var catalog := load("res://resources/stages/catalog.tres") as StageCatalogData
	_assert(catalog != null and catalog.is_valid(), "active catalog must load")
	if catalog == null:
		quit(1)
		return
	_assert(catalog.feasibility_certificate_paths.size() == EXPECTED_STAGE_COUNT,
		"every stage must expose one feasibility sidecar")
	var certified_deals := 0
	for index in range(catalog.stages.size()):
		var stage := catalog.stages[index]
		var baked := load(catalog.layout_paths[index]) as BakedStageLayoutData
		var certificate := load(
			catalog.feasibility_certificate_paths[index]
		) as StageClearFeasibilityCertificate
		_assert(certificate != null and certificate.is_valid(),
			"%s sidecar must be sealed and valid" % stage.stage_id)
		_assert(StageClearFeasibilityAnalyzer.matches(certificate, stage, baked),
			"%s sidecar must reproduce from immutable inputs" % stage.stage_id)
		if certificate != null:
			certified_deals += certificate.deal_count
	_assert(certified_deals == EXPECTED_DEAL_COUNT,
		"the sidecars must cover 30 stages x 16 deterministic deals")

	var first_stage := catalog.stages[0].duplicate(true) as StageData
	var first_baked := load(catalog.layout_paths[0]) as BakedStageLayoutData
	var stored := load(
		catalog.feasibility_certificate_paths[0]
	) as StageClearFeasibilityCertificate
	first_stage.target_band.target_min += 0.25
	_assert(not StageClearFeasibilityAnalyzer.matches(stored, first_stage, first_baked),
		"rule tampering must invalidate the stored sidecar")

	var deal_tamper := catalog.stages[0].duplicate(true) as StageData
	deal_tamper.maximum_shots -= 1
	_assert(not StageClearFeasibilityAnalyzer.matches(stored, deal_tamper, first_baked),
		"deal-size tampering must invalidate the stored sidecar")

	var target_tamper := first_baked.duplicate(true) as BakedStageLayoutData
	var target_mask := target_tamper.target_mask.duplicate()
	target_mask[0] = 255 - target_mask[0]
	target_tamper.target_mask = target_mask
	_assert(not StageClearFeasibilityAnalyzer.matches(stored, catalog.stages[0], target_tamper),
		"target-mask tampering must invalidate the stored sidecar")

	var coverage_tamper := first_baked.duplicate(true) as BakedStageLayoutData
	coverage_tamper.total_target_surface_area += 0.01
	_assert(not StageClearFeasibilityAnalyzer.matches(stored, catalog.stages[0], coverage_tamper),
		"coverage-metadata tampering must invalidate the stored sidecar")

	var seal_tamper := stored.duplicate(true) as StageClearFeasibilityCertificate
	seal_tamper.maximum_minimum_cover_shots += 1
	_assert(not StageClearFeasibilityAnalyzer.matches(seal_tamper, catalog.stages[0], first_baked),
		"certificate tampering must invalidate its content seal")
	_assert(_capability_contract_is_complete(),
		"every allowed ball kind must keep its certified target-paint capability")
	if not _failed:
		print("Stage clear feasibility passed: 30 sealed sidecars, 480 deals, zero gameplay scenes.")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Stage clear feasibility failed: %s" % message)


func _capability_contract_is_complete() -> bool:
	return BallKind.target_paint_capability_id(BallKind.Value.STANDARD) == &"direct_contact" \
			and BallKind.target_paint_contributor_count(BallKind.Value.STANDARD) == 1 \
			and BallKind.target_paint_capability_id(BallKind.Value.IMPACT_BURST) == &"impact_radial" \
			and BallKind.target_paint_contributor_count(BallKind.Value.IMPACT_BURST) == 1 \
			and BallKind.target_paint_capability_id(BallKind.Value.APEX_SPLIT) == &"apex_child_fan" \
			and BallKind.target_paint_contributor_count(BallKind.Value.APEX_SPLIT) == 3
