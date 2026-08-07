class_name CannonWindFlag
extends Node3D

## Non-colliding world cue beside the cannon. It presents the authoritative
## wind snapshot; it never calculates wind or applies projectile force.
const POLE_HEIGHT := 5.5
const STREAMER_LENGTH := 5.0

var _wind_controller: WindController
var _streamer: MeshInstance3D
var _anchor := Vector3.ZERO
var _visual_time := 0.0
var _reduced_motion := false
var _display_direction := Vector3.RIGHT
var _display_strength := 0.0


func _ready() -> void:
	_build_visuals()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(game_state.settings)


func configure(cannon: CannonController, wind_controller: WindController) -> void:
	assert(cannon != null and wind_controller != null)
	_wind_controller = wind_controller
	_anchor = cannon.global_position + Vector3(-6.0, 0.0, 1.5)
	global_position = _anchor
	_apply_snapshot(_wind_controller.current_snapshot(), 0.0)


func displayed_direction() -> Vector3:
	return _display_direction


func displayed_strength() -> float:
	return _display_strength


func _physics_process(delta: float) -> void:
	if _wind_controller == null:
		return
	_visual_time += delta
	_apply_snapshot(_wind_controller.current_snapshot(), delta)


func _build_visuals() -> void:
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.10
	pole_mesh.bottom_radius = 0.14
	pole_mesh.height = POLE_HEIGHT
	pole_mesh.radial_segments = 10
	pole_mesh.material = _material(Color("36445A"))
	var pole := MeshInstance3D.new()
	pole.name = "FlagPole"
	pole.mesh = pole_mesh
	pole.position.y = POLE_HEIGHT * 0.5
	add_child(pole)

	var streamer_mesh := BoxMesh.new()
	streamer_mesh.size = Vector3(STREAMER_LENGTH, 1.25, 0.10)
	streamer_mesh.material = _material(Color("F25B4B"))
	_streamer = MeshInstance3D.new()
	_streamer.name = "WindStreamer"
	_streamer.mesh = streamer_mesh
	_streamer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_streamer)


func _apply_snapshot(snapshot: WindSnapshot, _delta: float) -> void:
	if snapshot == null or _streamer == null:
		return
	var direction := snapshot.push_direction()
	if not direction.is_zero_approx():
		_display_direction = Vector3(direction.x, 0.0, direction.z).normalized()
	_display_strength = snapshot.normalized_strength
	var yaw := atan2(-_display_direction.z, _display_direction.x)
	var flutter := 0.0 if _reduced_motion else sin(_visual_time * 5.0) \
			* lerpf(0.03, 0.14, _display_strength)
	_streamer.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, flutter)
	var length_scale := lerpf(0.72, 1.0, _display_strength)
	_streamer.scale = Vector3(length_scale, lerpf(0.82, 1.0, _display_strength), 1.0)
	_streamer.position = Vector3.UP * (POLE_HEIGHT - 0.65) \
			+ _display_direction * (STREAMER_LENGTH * length_scale * 0.5)


func _on_settings_changed(settings: Dictionary) -> void:
	_reduced_motion = bool(settings.get("reduced_motion", false))


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
