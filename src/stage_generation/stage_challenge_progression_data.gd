class_name StageChallengeProgressionData
extends Resource

## Typed five-chapter challenge table. Stage 01-06 remain authored in the
## catalog materializer; this resource owns only the explicit Stage 07-30 rows.

const SCHEMA_VERSION := 1
const FIRST_LATE_STAGE := 7
const LATE_STAGE_COUNT := 24

@export var schema_version: int = SCHEMA_VERSION
@export var challenges: Array[Resource] = []


func is_valid() -> bool:
	if schema_version != SCHEMA_VERSION or challenges.size() != LATE_STAGE_COUNT:
		return false
	for index in challenges.size():
		var challenge := challenges[index]
		if challenge == null or not challenge.is_valid() \
				or challenge.stage_number != FIRST_LATE_STAGE + index:
			return false
	return true


func challenge_for_stage(stage_number: int) -> Resource:
	if not is_valid() or stage_number < FIRST_LATE_STAGE \
			or stage_number >= FIRST_LATE_STAGE + challenges.size():
		return null
	return challenges[stage_number - FIRST_LATE_STAGE]
