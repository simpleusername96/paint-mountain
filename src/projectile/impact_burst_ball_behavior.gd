extends RefCounted

var _activated := false


func on_valid_terrain_contact() -> Dictionary:
	if _activated:
		return {}
	_activated = true
	return {"emit_burst": true, "consume": true}


func note_valid_terrain_contact() -> void:
	pass


func on_airborne_velocity(_previous_velocity: Vector3, _current_velocity: Vector3) -> Array[Vector3]:
	return []
