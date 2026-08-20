class_name StageData
extends Resource

enum RuleKind {
	LEGACY_COVERAGE,
	TARGET_BAND,
}

@export_category("Identity")
@export var stage_id: StringName = &"stage_01"
@export var stage_version: int = StageGenerationContract.CONTRACT_VERSION
@export var display_name_key: StringName = &"stage.first_descent.name"
@export var stage_number: int = 1

@export_category("Rules")
@export_range(0.01, 100.0, 0.01) var target_coverage: float = 10.0
@export_range(1, 12, 1) var maximum_shots: int = 4
@export_range(0.0, 300.0, 1.0) var duration_seconds: float = 0.0
@export var paint_color: Color = Color(0.03, 0.38, 1.0, 1.0)
@export var star_thresholds := Vector3(10.0, 18.0, 28.0)
@export var objective_key: StringName = &"stage.first_descent.objective"

@export_category("Prototype Target Band")
@export var rule_kind: RuleKind = RuleKind.LEGACY_COVERAGE
@export var color_score_rule: ColorScoreRuleData
@export var target_band: TargetBandData
@export var ball_deal_profile: BallDealProfile
@export var default_deal_seed: int = 1
@export var red_paint_color: Color = PaintChannel.RED_COLOR
@export var green_paint_color: Color = PaintChannel.GREEN_COLOR
@export var require_both_paint_channels_for_clear := false
@export var required_ball_kinds_for_clear: Array[int] = []

@export_category("World")
@export var generation_profile: StageGenerationProfile
@export var terrain_seed: int = 0
@export var terrain_center := Vector3(0.0, -2.0, -112.0)
@export var terrain_size := Vector2(180.0, 120.0)
@export var cannon_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 5.0))
@export var reachability_certificate: DirectReachabilityCertificate
@export var mechanism_loadout: Array[MechanismData] = []

@export_category("Camera Bookmarks")
@export var briefing_camera_position := Vector3(92.0, 62.0, 24.0)
@export var briefing_camera_target := Vector3(0.0, 24.0, -112.0)
@export var aiming_camera_position := Vector3(5.0, 3.2, 18.0)
@export var aiming_camera_target := Vector3(0.0, 18.0, -102.0)
@export var wide_camera_position := Vector3(82.0, 52.0, 8.0)
@export var wide_camera_target := Vector3(0.0, 22.0, -112.0)
@export var result_camera_position := Vector3(-78.0, 50.0, 4.0)
@export var result_camera_target := Vector3(0.0, 22.0, -112.0)
@export_range(24.0, 160.0, 1.0) var follow_camera_max_distance: float = 96.0


func resolved_duration_seconds() -> float:
	# Zero keeps existing serialized stages compatible while the progression
	# resource supplies the canonical duration tier.
	if duration_seconds > 0.0:
		return duration_seconds
	return float(StageProgressionData.duration_seconds_for(stage_number))


func uses_target_band() -> bool:
	return rule_kind == RuleKind.TARGET_BAND


func has_valid_rule_contract() -> bool:
	if not uses_target_band():
		return target_coverage > 0.0
	return color_score_rule != null and color_score_rule.is_valid() \
			and target_band != null and target_band.is_valid() \
			and ball_deal_profile != null and ball_deal_profile.is_valid() \
			and default_deal_seed > 0 and _clear_requirements_are_valid()


func has_late_clear_requirements() -> bool:
	return uses_target_band() and (
		require_both_paint_channels_for_clear or not required_ball_kinds_for_clear.is_empty()
	)


func _clear_requirements_are_valid() -> bool:
	var seen := {}
	for kind in required_ball_kinds_for_clear:
		if not BallKind.is_special(kind) or seen.has(kind) \
				or not ball_deal_profile.required_kinds.has(kind):
			return false
		seen[kind] = true
	return true


func paint_world_bounds() -> Rect2:
	return Rect2(
		Vector2(terrain_center.x - terrain_size.x * 0.5, terrain_center.z - terrain_size.y * 0.5),
		terrain_size
	)
