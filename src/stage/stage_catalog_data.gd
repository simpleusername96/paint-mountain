class_name StageCatalogData
extends Resource

## Immutable catalog pointer written by the offline builder. Runtime lookup only
## reads these serialized StageData entries; it never synthesizes a profile or
## searches for a replacement seed.

@export var catalog_version: int = StageGenerationContract.CONTRACT_VERSION
@export var manifest_sha256: String = ""
@export var bundle_manifest_path: String = ""
@export var progression: StageProgressionData
@export var stage_ids: Array[StringName] = []
@export var stages: Array[StageData] = []
@export var legacy_aliases: Dictionary = {
	"first_descent": "stage_01",
	"burst_basin": "stage_02",
	"split_ridge": "stage_03",
}


func is_valid() -> bool:
	if catalog_version != StageGenerationContract.CONTRACT_VERSION:
		return false
	if progression == null \
			or progression.progression_version != catalog_version \
			or progression.stage_count != StageProgressionData.STAGE_COUNT:
		return false
	if stage_ids.is_empty() or stage_ids.size() != stages.size():
		return false
	var seen := {}
	for index in range(stage_ids.size()):
		var stage_id := stage_ids[index]
		var stage := stages[index]
		if String(stage_id).is_empty() or seen.has(stage_id) or stage == null:
			return false
		if stage_id != StringName("stage_%02d" % (index + 1)) \
				or stage.stage_number != index + 1:
			return false
		if stage.stage_id != stage_id or stage.stage_version != catalog_version:
			return false
		if stage.generation_profile == null or not stage.generation_profile.is_valid():
			return false
		seen[stage_id] = true
	return not manifest_sha256.is_empty() \
			and bundle_manifest_path == "res://resources/generated_stage_catalogs/v7-%s/manifest.json" % manifest_sha256 \
			and FileAccess.file_exists(bundle_manifest_path) \
			and legacy_aliases.get("first_descent", "") == "stage_01" \
			and legacy_aliases.get("burst_basin", "") == "stage_02" \
			and legacy_aliases.get("split_ridge", "") == "stage_03"


func get_stage(stage_id: StringName) -> StageData:
	var requested := String(stage_id)
	if legacy_aliases.has(requested):
		requested = String(legacy_aliases[requested])
	for index in range(stage_ids.size()):
		if String(stage_ids[index]) == requested:
			return stages[index]
	return null


func ordered_stages() -> Array[StageData]:
	return stages.duplicate()
