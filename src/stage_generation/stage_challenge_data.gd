class_name StageChallengeData
extends Resource

## One authored late-stage scoring and deal requirement. Geometry and mechanisms
## remain owned by StageProgressionData and the generated catalog.

@export_range(7, 30, 1) var stage_number: int = 7
@export_range(2, 5, 1) var chapter_number: int = 2
@export var role_id: StringName = &""
@export_enum(
	"Both Add",
	"Green Add / Red Subtract",
	"Red Add / Green Subtract"
) var score_pattern: int = ColorScoreRuleData.Pattern.BOTH_ADD
@export var target_range := Vector2(1.0, 5.0)
@export var required_kinds: Array[int] = [BallKind.Value.IMPACT_BURST]


func is_valid() -> bool:
	if stage_number < 7 or stage_number > StageProgressionData.STAGE_COUNT \
			or chapter_number != floori(float(stage_number - 1) / 6.0) + 1 \
			or role_id.is_empty() \
			or score_pattern not in [
				ColorScoreRuleData.Pattern.BOTH_ADD,
				ColorScoreRuleData.Pattern.GREEN_ADD_RED_SUBTRACT,
				ColorScoreRuleData.Pattern.RED_ADD_GREEN_SUBTRACT,
			] \
			or not is_finite(target_range.x) or not is_finite(target_range.y) \
			or target_range.x <= 0.0 or target_range.y > 100.0 \
			or not is_equal_approx(target_range.y - target_range.x, 4.0) \
			or required_kinds.is_empty() or required_kinds.size() > 2:
		return false
	var seen := {}
	for kind in required_kinds:
		if not BallKind.is_special(kind) or seen.has(kind):
			return false
		seen[kind] = true
	var rule := ColorScoreRuleData.from_pattern(score_pattern)
	return rule != null and rule.red_weight != 0 and rule.green_weight != 0
