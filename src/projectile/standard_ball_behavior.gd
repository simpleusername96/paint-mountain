extends RefCounted


func on_valid_terrain_contact() -> Dictionary:
	return {}


func note_valid_terrain_contact() -> void:
	pass


func on_airborne_velocity(_previous_velocity: Vector3, _current_velocity: Vector3) -> Array[Vector3]:
	return []
