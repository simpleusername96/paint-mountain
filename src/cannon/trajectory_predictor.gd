class_name TrajectoryPredictor
extends RefCounted

const PHYSICS_STEP := 1.0 / 60.0
const MAXIMUM_STEPS := 720
const COLLISION_MASK := 1 | 4
const REST_PROBE_DISTANCE := 0.01


static func predict(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		stage_bounds: AABB
) -> TrajectoryPrediction:
	return predict_motion(
		space_state,
		cannon.get_launch_origin(),
		cannon.get_launch_velocity(),
		cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp,
		stage_bounds
	)


static func predict_motion(
		space_state: PhysicsDirectSpaceState3D,
		origin: Vector3,
		launch_velocity: Vector3,
		projectile_radius: float,
		linear_damp: float,
		stage_bounds: AABB,
		collision_mask: int = COLLISION_MASK
) -> TrajectoryPrediction:
	if space_state == null or projectile_radius <= 0.0:
		return TrajectoryPrediction.new(
			TrajectoryPrediction.Kind.TIMEOUT, origin, PackedVector3Array([origin]),
			0.0, null, Vector3.ZERO, &"invalid_predictor_input"
		)
	var shape := SphereShape3D.new()
	shape.radius = projectile_radius
	var points := PackedVector3Array([origin])
	var position := origin
	var velocity := launch_velocity
	var gravity := _gravity_vector()
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	for step_index in range(MAXIMUM_STEPS):
		velocity *= maxf(1.0 - linear_damp * PHYSICS_STEP, 0.0)
		velocity += gravity * PHYSICS_STEP
		var next_position := position + velocity * PHYSICS_STEP
		var motion := next_position - position
		var bounds_fraction := _bounds_exit_fraction(position, next_position, stage_bounds)
		query.transform = Transform3D(Basis.IDENTITY, position)
		query.motion = motion
		var fractions := space_state.cast_motion(query)
		var collision_fraction := 1.0
		if not fractions.is_empty():
			collision_fraction = clampf(float(fractions[0]), 0.0, 1.0)
		if collision_fraction < 1.0 and collision_fraction <= bounds_fraction:
			var motion_direction := motion.normalized()
			query.transform.origin = position + motion * collision_fraction \
					+ motion_direction * REST_PROBE_DISTANCE
			query.motion = Vector3.ZERO
			var rest_info := space_state.get_rest_info(query)
			if rest_info.is_empty():
				var failed_endpoint := position + motion * collision_fraction
				points.append(failed_endpoint)
				return TrajectoryPrediction.new(
					TrajectoryPrediction.Kind.TIMEOUT,
					failed_endpoint,
					points,
					(float(step_index) + collision_fraction) * PHYSICS_STEP,
					null,
					Vector3.ZERO,
					&"empty_rest_info_after_cast"
				)
			var endpoint: Vector3 = rest_info.get("point", position + motion * collision_fraction)
			var normal: Vector3 = rest_info.get("normal", Vector3.ZERO)
			var collider_id := int(rest_info.get("collider_id", 0))
			var collider := instance_from_id(collider_id) if collider_id != 0 else null
			points.append(endpoint)
			return TrajectoryPrediction.new(
				TrajectoryPrediction.Kind.COLLISION,
				endpoint,
				points,
				(float(step_index) + collision_fraction) * PHYSICS_STEP,
				collider,
				normal,
				&""
			)
		if bounds_fraction < 1.0:
			var exit_position := position + motion * bounds_fraction
			points.append(exit_position)
			return TrajectoryPrediction.new(
				TrajectoryPrediction.Kind.BOUNDS_EXIT,
				exit_position,
				points,
				(float(step_index) + bounds_fraction) * PHYSICS_STEP,
				null,
				Vector3.ZERO,
				&""
			)
		position = next_position
		points.append(position)
	return TrajectoryPrediction.new(
		TrajectoryPrediction.Kind.TIMEOUT,
		position,
		points,
		MAXIMUM_STEPS * PHYSICS_STEP,
		null,
		Vector3.ZERO,
		&"maximum_duration"
	)


static func _bounds_exit_fraction(start: Vector3, finish: Vector3, bounds: AABB) -> float:
	if not bounds.has_point(start):
		return 0.0
	if bounds.has_point(finish):
		return 1.0
	var motion := finish - start
	var result := 1.0
	for axis in range(3):
		var component := motion[axis]
		if is_zero_approx(component):
			continue
		var boundary := bounds.position[axis] if finish[axis] < bounds.position[axis] else bounds.end[axis]
		var fraction := (boundary - start[axis]) / component
		if fraction >= 0.0:
			result = minf(result, fraction)
	return clampf(result, 0.0, 1.0)


static func _gravity_vector() -> Vector3:
	var magnitude := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var direction := Vector3(ProjectSettings.get_setting("physics/3d/default_gravity_vector", Vector3.DOWN))
	return direction.normalized() * magnitude
