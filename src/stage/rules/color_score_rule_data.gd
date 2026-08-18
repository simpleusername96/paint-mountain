class_name ColorScoreRuleData
extends Resource

enum Pattern {
	BOTH_ADD,
	GREEN_ADD_RED_SUBTRACT,
	RED_ADD_GREEN_SUBTRACT,
	GREEN_ADD_RED_NEUTRAL,
	RED_ADD_GREEN_NEUTRAL,
}

@export var green_weight: int = 1
@export var red_weight: int = 1


static func from_pattern(pattern: Pattern) -> ColorScoreRuleData:
	var rule := ColorScoreRuleData.new()
	match pattern:
		Pattern.BOTH_ADD:
			rule.green_weight = 1
			rule.red_weight = 1
		Pattern.GREEN_ADD_RED_SUBTRACT:
			rule.green_weight = 1
			rule.red_weight = -1
		Pattern.RED_ADD_GREEN_SUBTRACT:
			rule.green_weight = -1
			rule.red_weight = 1
		Pattern.GREEN_ADD_RED_NEUTRAL:
			rule.green_weight = 1
			rule.red_weight = 0
		Pattern.RED_ADD_GREEN_NEUTRAL:
			rule.green_weight = 0
			rule.red_weight = 1
	return rule


func is_valid() -> bool:
	return [green_weight, red_weight] in [[1, 1], [1, -1], [-1, 1], [1, 0], [0, 1]]


func score(coverage: PaintCoverageSnapshot) -> float:
	assert(coverage != null and coverage.is_valid() and is_valid())
	return coverage.green_percent * green_weight + coverage.red_percent * red_weight
