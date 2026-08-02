class_name GimmickBase
extends Area3D

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
var _label: Label3D


func _ready() -> void:
	assert(data != null, "%s requires MechanismData before entering the tree." % name)
	collision_layer = 2
	collision_mask = 1
	monitoring = true
	monitorable = true
	_build_trigger()
	_visual_root = get_node_or_null("Visual") as Node3D
	if _visual_root == null:
		# Script-created nodes used by focused tests retain a compact fallback visual.
		_visual_root = Node3D.new()
		_visual_root.name = "Visual"
		add_child(_visual_root)
		_build_visual(_visual_root)
	_label = Label3D.new()
	_label.name = "BriefingLabel"
	_label.text = data.display_name
	_label.font_size = 42
	_label.outline_size = 8
	_label.modulate = Color(0.95, 0.97, 1.0, 1.0)
	_label.outline_modulate = Color(0.04, 0.07, 0.12, 0.9)
	_label.position = Vector3(0.0, data.trigger_radius + 1.2, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.visible = false
	add_child(_label)
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)
	reset_state()


func configure(projectile_manager: ProjectileManager, paint_system: PaintSystem) -> void:
	_projectile_manager = projectile_manager
	_paint_system = paint_system


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func can_activate(projectile: PaintProjectile) -> bool:
	if projectile == null or not is_instance_valid(projectile):
		return false
	if _projectile_manager == null or _paint_system == null:
		return false
	if cooldown_remaining > 0.0:
		return false
	if data.has_finite_charges() and remaining_charges <= 0:
		return false
	if _activated_projectile_ids.has(projectile.get_instance_id()):
		return false
	return _effect_can_activate(projectile)


func activate(projectile: PaintProjectile) -> bool:
	if not can_activate(projectile):
		return false
	_activated_projectile_ids[projectile.get_instance_id()] = true
	if data.has_finite_charges():
		remaining_charges -= 1
	cooldown_remaining = data.cooldown_seconds
	_apply_effect(projectile)
	_update_visual_state()
	mechanism_activated.emit(self, projectile, data.kind)
	return true


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
		"position": global_position,
		"remaining_charges": remaining_charges,
		"cooldown": cooldown_remaining,
		"spent": is_spent(),
	}


func set_label_visible(value: bool) -> void:
	if _label != null:
		_label.visible = value


func _effect_can_activate(_projectile: PaintProjectile) -> bool:
	return true


func _apply_effect(_projectile: PaintProjectile) -> void:
	push_error("GimmickBase effect must be implemented by %s." % get_script().resource_path)


func _build_visual(_parent: Node3D) -> void:
	pass


func _update_visual_state() -> void:
	if _visual_root == null:
		return
	for child in _visual_root.get_children():
		if child is GeometryInstance3D:
			child.transparency = 0.45 if is_spent() else 0.0


func _on_body_entered(body: Node3D) -> void:
	if body is PaintProjectile:
		activate(body)


func _on_input_event(
		_camera: Node,
		event: InputEvent,
		_event_position: Vector3,
		_normal: Vector3,
		_shape_index: int
) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mechanism_selected.emit(self)


func _build_trigger() -> void:
	var shape := SphereShape3D.new()
	shape.radius = data.trigger_radius
	var collision := CollisionShape3D.new()
	collision.name = "TriggerShape"
	collision.shape = shape
	add_child(collision)


func _material(color: Color, metallic: float = 0.1, roughness: float = 0.36) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material
