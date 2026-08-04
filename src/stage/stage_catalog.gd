class_name StageCatalog
extends RefCounted

## The first three legacy IDs remain valid save/replay aliases. New stages use
## stable stage_04..stage_30 IDs and are generated once per process from the
## shared deterministic profiles.

const STAGE_ORDER: Array[StringName] = [
	&"first_descent", &"burst_basin", &"split_ridge",
	&"stage_04", &"stage_05", &"stage_06", &"stage_07", &"stage_08", &"stage_09", &"stage_10",
	&"stage_11", &"stage_12", &"stage_13", &"stage_14", &"stage_15", &"stage_16", &"stage_17", &"stage_18", &"stage_19", &"stage_20",
	&"stage_21", &"stage_22", &"stage_23", &"stage_24", &"stage_25", &"stage_26", &"stage_27", &"stage_28", &"stage_29", &"stage_30",
]

const STAGE_PATHS := {
	&"first_descent": "res://resources/stages/first_descent.tres",
	&"burst_basin": "res://resources/stages/burst_basin.tres",
	&"split_ridge": "res://resources/stages/split_ridge.tres",
}
const BASE_STAGE_PATHS := [
	"res://resources/stages/first_descent.tres",
	"res://resources/stages/burst_basin.tres",
	"res://resources/stages/split_ridge.tres",
]

static var _generated_cache: Dictionary = {}
static var _all_stages_cache: Array[StageData] = []


static func canonical_id(stage_id: StringName) -> StringName:
	match stage_id:
		&"stage_01":
			return &"first_descent"
		&"stage_02":
			return &"burst_basin"
		&"stage_03":
			return &"split_ridge"
		_:
			return stage_id


static func get_stage(stage_id: StringName) -> StageData:
	stage_id = canonical_id(stage_id)
	var path: String = STAGE_PATHS.get(stage_id, "")
	if not path.is_empty():
		return load(path) as StageData
	var stage_name := String(stage_id)
	if not stage_name.begins_with("stage_"):
		return null
	var number := stage_name.trim_prefix("stage_").to_int()
	if number < 4 or number > 30:
		return null
	if _generated_cache.has(stage_id):
		return _generated_cache[stage_id] as StageData
	var template := load(BASE_STAGE_PATHS[StageProgressionData.profile_band(number)]) as StageData
	if template == null:
		return null
	var stage := template.duplicate(true) as StageData
	stage.stage_id = stage_id
	stage.stage_version = 6
	stage.stage_number = number
	stage.display_name_key = StringName("stage.generated_%02d.name" % number)
	stage.objective_key = StringName("stage.generated_%02d.objective" % number)
	stage.target_coverage = StageProgressionData.target_for(number)
	stage.maximum_shots = StageProgressionData.shots_for(number)
	stage.star_thresholds = Vector3(
		stage.target_coverage,
		stage.target_coverage + 2.5,
		stage.target_coverage + 5.0
	)
	stage.terrain_seed = StageProgressionData.requested_seed_for(number)
	var profile := stage.generation_profile.duplicate(true) as StageGenerationProfile
	profile.profile_id = StringName("generated_stage_%02d_v6" % number)
	profile.nominal_peak = StageProgressionData.nominal_peak_for(number)
	profile.accepted_height_range = Vector2(profile.nominal_peak - 4.0, profile.nominal_peak + 10.0)
	profile.target_ratio_range = Vector2(0.18, 0.72)
	profile.target_mean_slope_range = Vector2(12.0, 45.0)
	profile.target_p95_slope_max = 60.0
	profile.target_maximum_slope = 68.0
	profile.route_core_p95_slope_max = 60.0
	profile.corridor_lip_maximum_slope = 50.0
	stage.generation_profile = profile
	stage.mechanism_loadout = _progressive_mechanisms(number)
	stage.reliable_solution = []
	_generated_cache[stage_id] = stage
	return stage


static func all_stages() -> Array[StageData]:
	if not _all_stages_cache.is_empty():
		return _all_stages_cache.duplicate()
	var stages: Array[StageData] = []
	for stage_id in STAGE_ORDER:
		var stage := get_stage(stage_id)
		if stage != null:
			stages.append(stage)
	_all_stages_cache = stages
	return _all_stages_cache.duplicate()


static func all_stage_ids() -> Array[StringName]:
	return STAGE_ORDER.duplicate()


static func next_stage_id(stage_id: StringName) -> StringName:
	var index := STAGE_ORDER.find(stage_id)
	if index < 0:
		index = STAGE_ORDER.find(canonical_id(stage_id))
	if index < 0 or index + 1 >= STAGE_ORDER.size():
		return &""
	return STAGE_ORDER[index + 1]


static func _progressive_mechanisms(stage_number: int) -> Array[MechanismData]:
	var templates: Array[MechanismData] = [
		load("res://resources/mechanisms/burst_node.tres") as MechanismData,
		load("res://resources/mechanisms/splitter_node.tres") as MechanismData,
		load("res://resources/mechanisms/bumper_node.tres") as MechanismData,
	]
	var result: Array[MechanismData] = []
	if stage_number <= 5:
		return result
	if stage_number <= 20:
		result.append(templates[MechanismData.Kind.BURST].duplicate(true) as MechanismData)
		return result
	result.append(templates[MechanismData.Kind.SPLITTER].duplicate(true) as MechanismData)
	result.append(templates[MechanismData.Kind.BUMPER].duplicate(true) as MechanismData)
	return result
