class_name ShotObservation
extends RefCounted

var shot_number: int = 0
var commanded_yaw: float = 0.0
var commanded_elevation: float = 0.0
var commanded_power: float = 0.0
var first_terrain_contact: ProjectileContact
var first_mechanism_contact: ProjectileContact
var mechanism_activation_kinds := PackedInt32Array()
var spawned_child_count: int = 0
var peak_active_projectile_count: int = 0
var initial_payload: float = 0.0
var current_payload: float = 0.0
var consumed_payload: float = 0.0
var settlement_reason_counts: Dictionary = {}
var coverage_before: float = 0.0
var coverage_after: float = 0.0
var coverage_gain: float = 0.0
var penetration_guard_count: int = 0
var is_sealed: bool = false


func configure(
		new_shot_number: int,
		yaw: float,
		elevation: float,
		power: float,
		before_coverage: float,
		payload: float
) -> void:
	assert(not is_sealed, "A sealed shot observation cannot be configured.")
	shot_number = new_shot_number
	commanded_yaw = yaw
	commanded_elevation = elevation
	commanded_power = power
	coverage_before = before_coverage
	initial_payload = maxf(payload, 0.0)
	current_payload = initial_payload


func record_contact(contact: ProjectileContact, is_terrain: bool) -> void:
	if is_sealed or contact == null:
		return
	if is_terrain and first_terrain_contact == null:
		first_terrain_contact = contact
	elif not is_terrain and first_mechanism_contact == null:
		first_mechanism_contact = contact


func record_mechanism_activation(kind: int) -> void:
	if not is_sealed:
		mechanism_activation_kinds.append(kind)


func record_children_spawned(count: int, active_count: int) -> void:
	if is_sealed:
		return
	spawned_child_count += maxi(count, 0)
	peak_active_projectile_count = maxi(peak_active_projectile_count, active_count)


func record_payload(remaining: float) -> void:
	if is_sealed:
		return
	current_payload = clampf(remaining, 0.0, initial_payload)
	consumed_payload = initial_payload - current_payload


func record_settlement(reason: StringName) -> void:
	if is_sealed:
		return
	settlement_reason_counts[reason] = int(settlement_reason_counts.get(reason, 0)) + 1
	if reason == &"terrain_penetration_guard":
		penetration_guard_count += 1


func seal(final_coverage: float) -> void:
	if is_sealed:
		return
	coverage_after = maxf(final_coverage, 0.0)
	coverage_gain = maxf(coverage_after - coverage_before, 0.0)
	is_sealed = true
