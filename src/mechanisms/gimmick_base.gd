class_name GimmickBase
extends TerrainGlyphMechanism

## Transitional type alias for StageController, HUD, replay, and agent callers.
## Delete this class after those shared owners accept TerrainGlyphMechanism.


static func contact_owner_id_for_kind(kind: MechanismData.Kind) -> StringName:
	return StringName("mechanism/%s" % String(MechanismData.Kind.keys()[int(kind)]).to_lower())


static func contact_shape_id_for_kind(
		kind: MechanismData.Kind,
		shape_name: StringName
) -> StringName:
	return StringName("%s/%s" % [contact_owner_id_for_kind(kind), String(shape_name)])
