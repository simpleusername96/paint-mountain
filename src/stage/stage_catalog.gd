class_name StageCatalog
extends RefCounted

const STAGE_ORDER: Array[StringName] = [&"first_descent", &"burst_basin", &"split_ridge"]
const STAGE_PATHS := {
	&"first_descent": "res://resources/stages/first_descent.tres",
	&"burst_basin": "res://resources/stages/burst_basin.tres",
	&"split_ridge": "res://resources/stages/split_ridge.tres",
}


static func get_stage(stage_id: StringName) -> StageData:
	var path: String = STAGE_PATHS.get(stage_id, "")
	if path.is_empty():
		return null
	return load(path) as StageData


static func all_stages() -> Array[StageData]:
	var stages: Array[StageData] = []
	for stage_id in STAGE_ORDER:
		stages.append(get_stage(stage_id))
	return stages


static func next_stage_id(stage_id: StringName) -> StringName:
	var index := STAGE_ORDER.find(stage_id)
	if index < 0 or index + 1 >= STAGE_ORDER.size():
		return &""
	return STAGE_ORDER[index + 1]
