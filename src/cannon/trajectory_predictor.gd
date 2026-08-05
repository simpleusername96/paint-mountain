class_name TrajectoryPredictor
extends RefCounted

const PHYSICS_STEP := 1.0 / 60.0
const MAXIMUM_STEPS := 720
const COLLISION_MASK := 1 | 4
const REST_PROBE_DISTANCE := 0.01


static func predict(
		space_state: PhysicsDirectSpaceState3D,
		cannon: CannonController,
		stage_bounds: AABB,
		wind_profile: WindProfile = null,
		wind_schedule_seed: int = 0,
		launch_wind_tick: int = 0
) -> TrajectoryPrediction:
	return predict_motion(
		space_state,
		cannon.get_launch_origin(),
		cannon.get_launch_velocity(),
		cannon.projectile_data.radius,
		cannon.projectile_data.linear_damp,
		stage_bounds,
		COLLISION_MASK,
		true,
		wind_profile,
		wind_schedule_seed,
		launch_wind_tick
	)


static func predict_motion(
		space_state: PhysicsDirectSpaceState3D,
		origin: Vector3,
		launch_velocity: Vector3,
		projectile_radius: float,
		linear_damp: float,
		stage_bounds: AABB,
		collision_mask: int = COLLISION_MASK,
		capture_sampled_points: bool = true,
		wind_profile: WindProfile = null,
		wind_schedule_seed: int = 0,
		launch_wind_tick: int = 0
) -> TrajectoryPrediction:
	# Exhaustive offline certification needs collision identity and endpoint only;
	# gameplay keeps the default so its visible trajectory preview is unchanged.
	if space_state == null or projectile_radius <= 0.0:
		return TrajectoryPrediction.new(
			TrajectoryPrediction.Kind.TIMEOUT, origin, PackedVector3Array([origin]),
			0.0, null, Vector3.ZERO, &"invalid_predictor_input"
		)
	var shape := SphereShape3D.new()
	shape.radius = projectile_radius
	var points := PackedVector3Array([origin]) if capture_sampled_points \
			else PackedVector3Array()
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
		if wind_profile != null:
			var wind := WindController.sample_for_tick(
				wind_profile,
				wind_schedule_seed,
				maxi(0, launch_wind_tick) + step_index
			)
			if wind != null:
				velocity += wind.acceleration * PHYSICS_STEP
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
				if capture_sampled_points:
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
			var hit_identity := _resolve_hit_identity(
				rest_info,
				collider,
				endpoint,
				normal
			)
			if capture_sampled_points:
				points.append(endpoint)
			return TrajectoryPrediction.new(
				TrajectoryPrediction.Kind.COLLISION,
				endpoint,
				points,
				(float(step_index) + collision_fraction) * PHYSICS_STEP,
				collider,
				normal,
				&"" if hit_identity != null else &"missing_or_invalid_hit_identity",
				hit_identity
			)
		if bounds_fraction < 1.0:
			var exit_position := position + motion * bounds_fraction
			if capture_sampled_points:
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
		if capture_sampled_points:
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


static func _resolve_hit_identity(
		rest_info: Dictionary,
		collider: Object,
		world_point: Vector3,
		world_normal: Vector3
) -> TrajectoryHitIdentity:
	var collision_object := collider as CollisionObject3D
	if collision_object == null:
		return null
	var body_shape_index := int(rest_info.get("shape", -1))
	if body_shape_index < 0:
		return null
	var owner_id := StringName(collision_object.get_meta(
		ContainmentSpec.CONTACT_OWNER_META,
		&""
	))
	var shape_id := _shape_contact_id(collision_object, body_shape_index)
	if String(owner_id).is_empty() or String(shape_id).is_empty():
		return null
	if owner_id == TrajectoryHitIdentity.TERRAIN_TOP_OWNER_ID:
		var terrain_surface := _terrain_surface_for(collision_object)
		if terrain_surface == null:
			return null
		return terrain_surface.classify_top_hit(
			world_point,
			world_normal,
			shape_id,
			body_shape_index
		)
	var identity := TrajectoryHitIdentity.new(owner_id, shape_id, body_shape_index)
	return identity if identity.is_valid() else null


static func _shape_contact_id(
		collision_object: CollisionObject3D,
		body_shape_index: int
) -> StringName:
	var shape_owner_id := collision_object.shape_find_owner(body_shape_index)
	if shape_owner_id < 0:
		return &""
	var shape_owner := collision_object.shape_owner_get_owner(shape_owner_id)
	if shape_owner == null or not shape_owner.has_meta(ContainmentSpec.CONTACT_SHAPE_META):
		return &""
	return StringName(shape_owner.get_meta(ContainmentSpec.CONTACT_SHAPE_META, &""))


static func _terrain_surface_for(collision_object: CollisionObject3D) -> TerrainSurface:
	var current := collision_object as Node
	while current != null:
		if current is TerrainSurface:
			return current as TerrainSurface
		current = current.get_parent()
	return null
