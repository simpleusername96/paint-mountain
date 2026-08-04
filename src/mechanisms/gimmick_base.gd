class_name GimmickBase
extends Node3D

signal mechanism_activated(
	mechanism: GimmickBase,
	projectile: PaintProjectile,
	kind: MechanismData.Kind
)
signal mechanism_selected(mechanism: GimmickBase)

@export var data: MechanismData

var remaining_charges: int = 0
var cooldown_remaining: float = 0.0
var _projectile_manager: ProjectileManager
var _paint_system: PaintSystem
var _activated_projectile_ids: Dictionary = {}
var _visual_root: Node3D
var _mechanism_body: StaticBody3D
var _selection_body: StaticBody3D
var _label: Label3D


func _ready() -> void:
	assert(data != null, "%s requires MechanismData before entering the tree." % name)
	_visual_root = get_node_or_null("Visual") as Node3D
	_mechanism_body = get_node_or_null("MechanismBody") as StaticBody3D
	_selection_body = get_node_or_null("SelectionBody") as StaticBody3D
	assert(_visual_root != null, "%s requires its authored Visual node." % name)
	assert(_mechanism_body != null, "%s requires its compound MechanismBody." % name)
	assert(_selection_body != null, "%s requires its separate SelectionBody." % name)
	assert(_mechanism_body.collision_layer == 4, "MechanismBody must use physics layer 3 only.")
	assert(_selection_body.collision_layer == 8, "SelectionBody must use query layer 4 only.")
	_install_contact_identity()
	_selection_body.input_event.connect(_on_selection_input_event)
	_build_label()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.settings_changed.connect(_on_settings_changed)
	reset_state()


static func contact_owner_id_for_kind(kind: MechanismData.Kind) -> StringName:
	return StringName("mechanism/%s" % String(MechanismData.Kind.keys()[kind]).to_lower())


static func contact_shape_id_for_kind(
		kind: MechanismData.Kind,
		shape_name: StringName
) -> StringName:
	return StringName("%s/%s" % [contact_owner_id_for_kind(kind), String(shape_name)])


func _install_contact_identity() -> void:
	# Prediction and rigid-body contact resolve the same stable IDs. Without this
	# metadata, a real paintball correctly rejects the mechanism as ambiguous.
	_mechanism_body.set_meta(
		ContainmentSpec.CONTACT_OWNER_META,
		contact_owner_id_for_kind(data.kind)
	)
	for child in _mechanism_body.get_children():
		var collision := child as CollisionShape3D
		if collision == null:
			continue
		collision.set_meta(
			ContainmentSpec.CONTACT_SHAPE_META,
			contact_shape_id_for_kind(data.kind, collision.name)
		)


func configure(projectile_manager: ProjectileManager, paint_system: PaintSystem) -> void:
	assert(projectile_manager != null and paint_system != null, "Mechanisms require projectile and paint owners.")
	if _projectile_manager != null \
			and _projectile_manager.projectile_contact_reported.is_connected(_on_projectile_contact_reported):
		_projectile_manager.projectile_contact_reported.disconnect(_on_projectile_contact_reported)
	_projectile_manager = projectile_manager
	_paint_system = paint_system
	if not _projectile_manager.projectile_contact_reported.is_connected(_on_projectile_contact_reported):
		_projectile_manager.projectile_contact_reported.connect(_on_projectile_contact_reported)


func _exit_tree() -> void:
	if _projectile_manager != null \
			and _projectile_manager.projectile_contact_reported.is_connected(_on_projectile_contact_reported):
		_projectile_manager.projectile_contact_reported.disconnect(_on_projectile_contact_reported)


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func struck(projectile: PaintProjectile, contact: ProjectileContact) -> bool:
	if not _can_strike(projectile, contact):
		return false
	_activated_projectile_ids[projectile.get_instance_id()] = true
	if data.has_finite_charges():
		remaining_charges -= 1
	cooldown_remaining = data.cooldown_seconds
	_apply_effect(projectile, contact)
	_update_visual_state()
	mechanism_activated.emit(self, projectile, data.kind)
	return true


func can_strike(projectile: PaintProjectile, contact: ProjectileContact) -> bool:
	return _can_strike(projectile, contact)


func _can_strike(projectile: PaintProjectile, contact: ProjectileContact) -> bool:
	if projectile == null or not is_instance_valid(projectile) or contact == null:
		return false
	if _projectile_manager == null or _paint_system == null or _mechanism_body == null:
		return false
	if contact.collider != _mechanism_body:
		return false
	if cooldown_remaining > 0.0:
		return false
	if data.has_finite_charges() and remaining_charges <= 0:
		return false
	if _activated_projectile_ids.has(projectile.get_instance_id()):
		return false
	return _effect_can_activate(projectile, contact)


func reset_state() -> void:
	remaining_charges = data.maximum_charges
	cooldown_remaining = 0.0
	_activated_projectile_ids.clear()
	_update_visual_state()


func is_spent() -> bool:
	return data.has_finite_charges() and remaining_charges <= 0


func state_snapshot() -> Dictionary:
	return {
		"kind": MechanismData.Kind.keys()[data.kind],
		"display_name_key": data.display_name_key,
		"description_key": data.description_key,
		"position": global_position,
		"remaining_charges": remaining_charges,
		"cooldown": cooldown_remaining,
		"spent": is_spent(),
	}


func mechanism_body() -> StaticBody3D:
	return _mechanism_body


func selection_body() -> StaticBody3D:
	return _selection_body


func set_label_visible(value: bool) -> void:
	if _label != null:
		_label.visible = value


func _on_settings_changed(_settings: Dictionary) -> void:
	if _label != null:
		_label.text = tr(String(data.display_name_key))


func _effect_can_activate(_projectile: PaintProjectile, _contact: ProjectileContact) -> bool:
	return true


func _apply_effect(_projectile: PaintProjectile, _contact: ProjectileContact) -> void:
	push_error("GimmickBase effect must be implemented by %s." % get_script().resource_path)


func _update_visual_state() -> void:
	if _visual_root == null:
		return
	for child in _visual_root.get_children():
		if child is GeometryInstance3D:
			child.transparency = 0.45 if is_spent() else 0.0


func _on_projectile_contact_reported(projectile: PaintProjectile, contact: ProjectileContact) -> void:
	if contact != null and contact.collider == _mechanism_body:
		struck(projectile, contact)


func _on_selection_input_event(
		_camera: Node,
		event: InputEvent,
		_event_position: Vector3,
		_normal: Vector3,
		_shape_index: int
) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mechanism_selected.emit(self)


func _build_label() -> void:
	_label = Label3D.new()
	_label.name = "BriefingLabel"
	_label.text = tr(String(data.display_name_key))
	_label.font_size = 30
	_label.outline_size = 6
	_label.modulate = Color(0.95, 0.97, 1.0, 1.0)
	_label.outline_modulate = Color(0.04, 0.07, 0.12, 0.9)
	_label.position = Vector3(0.0, 4.4, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.001
	_label.no_depth_test = true
	_label.visible = false
	add_child(_label)
