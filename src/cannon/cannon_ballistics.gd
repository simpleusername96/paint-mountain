class_name CannonBallistics
extends RefCounted


static func launch_direction(yaw_degrees: float, elevation_degrees: float) -> Vector3:
	var yaw := deg_to_rad(yaw_degrees)
	var elevation := deg_to_rad(elevation_degrees)
	var horizontal_scale := cos(elevation)
	return Vector3(
		sin(yaw) * horizontal_scale,
		sin(elevation),
		-cos(yaw) * horizontal_scale
	).normalized()


static func launch_velocity(
		projectile_data: ProjectileData,
		yaw_degrees: float,
		elevation_degrees: float,
		power_percent: float
) -> Vector3:
	return launch_direction(yaw_degrees, elevation_degrees) * projectile_data.launch_speed(power_percent)


static func sample_unobstructed(
		origin: Vector3,
		velocity: Vector3,
		gravity: Vector3,
		step_seconds: float,
		maximum_seconds: float,
		linear_damp: float = 0.0
) -> PackedVector3Array:
	if linear_damp > 0.0:
		return _sample_damped(origin, velocity, gravity, step_seconds, maximum_seconds, linear_damp)
	var samples := PackedVector3Array([origin])
	var elapsed := step_seconds
	while elapsed <= maximum_seconds + 0.0001:
		samples.append(origin + velocity * elapsed + 0.5 * gravity * elapsed * elapsed)
		elapsed += step_seconds
	return samples


static func _sample_damped(
		origin: Vector3,
		velocity: Vector3,
		gravity: Vector3,
		sample_step: float,
		maximum_seconds: float,
		linear_damp: float
) -> PackedVector3Array:
	const PHYSICS_STEP := 1.0 / 60.0
	var samples := PackedVector3Array([origin])
	var position := origin
	var elapsed := 0.0
	var next_sample := sample_step
	while elapsed < maximum_seconds - 0.0001:
		var delta := minf(PHYSICS_STEP, maximum_seconds - elapsed)
		velocity *= maxf(0.0, 1.0 - linear_damp * delta)
		velocity += gravity * delta
		position += velocity * delta
		elapsed += delta
		if elapsed + 0.0001 >= next_sample:
			samples.append(position)
			next_sample += sample_step
	return samples
