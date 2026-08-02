class_name ImpactTargetSolver
extends RefCounted

const PHYSICS_STEP := 1.0 / 60.0
const MAXIMUM_SECONDS := 7.2
const MINIMUM_ELEVATION := 18.0
const MAXIMUM_ELEVATION := 68.0
const ELEVATION_STEP := 0.5
const TARGET_TOLERANCE := 1.25
const COLLISION_MASK := 1 | 2


static func solve(
		space_state: PhysicsDirectSpaceState3D,
		origin: Vector3,
		target: Vector3,
		projectile_data: ProjectileData,
		power_percent: float,
		target_collider: CollisionObject3D = null,
		cannon: CannonController = null
) -> Dictionary:
	if space_state == null or projectile_data == null:
		return _invalid_result(target, power_percent)
	var delta := target - origin
	var yaw := rad_to_deg(atan2(delta.x, -delta.z))
	if yaw < -28.0 or yaw > 28.0:
		return _invalid_result(target, power_percent)
	var previous_elevation := MINIMUM_ELEVATION
	var elevation := MINIMUM_ELEVATION
	while elevation <= MAXIMUM_ELEVATION + 0.0001:
		var result := _simulate(space_state, origin, target, projectile_data, yaw, elevation, power_percent, target_collider, false, cannon)
		if result.valid:
			var lower := previous_elevation
			var upper := elevation
			var best := result
			for _iteration in range(10):
				var midpoint := (lower + upper) * 0.5
				var refined := _simulate(space_state, origin, target, projectile_data, yaw, midpoint, power_percent, target_collider, false, cannon)
				if refined.valid:
					best = refined
					upper = midpoint
				else:
					lower = midpoint
			return best
		previous_elevation = elevation
		elevation += ELEVATION_STEP
	return _invalid_result(target, power_percent)


static func sample_solution(
		space_state: PhysicsDirectSpaceState3D,
		origin: Vector3,
		target: Vector3,
		projectile_data: ProjectileData,
		yaw: float,
		elevation: float,
		power_percent: float,
		target_collider: CollisionObject3D = null,
		cannon: CannonController = null
) -> Dictionary:
	return _simulate(space_state, origin, target, projectile_data, yaw, elevation, power_percent, target_collider, true, cannon)


static func _simulate(
		space_state: PhysicsDirectSpaceState3D,
		origin: Vector3,
		target: Vector3,
		projectile_data: ProjectileData,
		yaw: float,
		elevation: float,
		power_percent: float,
		target_collider: CollisionObject3D,
		collect_points: bool,
		cannon: CannonController
) -> Dictionary:
	var launch_origin := cannon.get_launch_origin_for(yaw, elevation) if cannon != null else origin
	var shape := SphereShape3D.new()
	shape.radius = projectile_data.radius
	var gravity_magnitude := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var gravity_direction := Vector3(ProjectSettings.get_setting("physics/3d/default_gravity_vector", Vector3.DOWN)).normalized()
	var gravity := gravity_direction * gravity_magnitude
	var linear_damp := projectile_data.linear_damp + float(ProjectSettings.get_setting("physics/3d/default_linear_damp", 0.1))
	var velocity := CannonBallistics.launch_velocity(projectile_data, yaw, elevation, power_percent)
	var position := launch_origin
	var elapsed := 0.0
	var points := PackedVector3Array([launch_origin])
	while elapsed < MAXIMUM_SECONDS - 0.0001:
		velocity += gravity * PHYSICS_STEP
		velocity *= maxf(0.0, 1.0 - linear_damp * PHYSICS_STEP)
		var next_position := position + velocity * PHYSICS_STEP
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, position)
		query.motion = next_position - position
		query.collision_mask = COLLISION_MASK
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var cast := space_state.cast_motion(query)
		if not cast.is_empty() and float(cast[0]) < 1.0:
			var collision_position := position + query.motion * float(cast[0])
			if collect_points:
				points.append(collision_position)
			var colliders := _colliders_at(space_state, shape, collision_position)
			var matches_target := (
				colliders.has(target_collider)
				if target_collider != null
				else collision_position.distance_to(target) <= TARGET_TOLERANCE
			)
			return {
				"valid": matches_target,
				"yaw": yaw,
				"elevation": elevation,
				"power": power_percent,
				"target": target,
				"collision_position": collision_position,
				"flight_time": elapsed + PHYSICS_STEP * float(cast[0]),
				"colliders": colliders,
				"points": points,
			}
		position = next_position
		elapsed += PHYSICS_STEP
		if collect_points and (points.is_empty() or points[-1].distance_to(position) >= 2.2):
			points.append(position)
	return _invalid_result(target, power_percent, yaw, elevation, points)


static func _colliders_at(
		space_state: PhysicsDirectSpaceState3D,
		shape: SphereShape3D,
		position: Vector3
) -> Array[CollisionObject3D]:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, position)
	query.margin = 0.08
	query.collision_mask = COLLISION_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result: Array[CollisionObject3D] = []
	for hit in space_state.intersect_shape(query, 8):
		var collider := hit.get("collider") as CollisionObject3D
		if collider != null and not result.has(collider):
			result.append(collider)
	return result


static func _invalid_result(
		target: Vector3,
		power_percent: float,
		yaw: float = 0.0,
		elevation: float = 0.0,
		points: PackedVector3Array = PackedVector3Array()
) -> Dictionary:
	return {
		"valid": false,
		"yaw": yaw,
		"elevation": elevation,
		"power": power_percent,
		"target": target,
		"collision_position": Vector3.ZERO,
		"flight_time": 0.0,
		"colliders": [],
		"points": points,
	}
