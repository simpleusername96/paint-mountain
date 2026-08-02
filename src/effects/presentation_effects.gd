class_name PresentationEffects
extends Node3D

const POOL_SIZE := 8

var _particles: Array[GPUParticles3D] = []
var _next_particle: int = 0


func _ready() -> void:
	for index in range(POOL_SIZE):
		var particle := _build_particle(index)
		add_child(particle)
		_particles.append(particle)


func splash(world_position: Vector3, scale: float = 1.0) -> void:
	var particle := _particles[_next_particle]
	_next_particle = (_next_particle + 1) % _particles.size()
	particle.global_position = world_position
	particle.amount = clampi(roundi(22.0 * scale), 12, 42)
	particle.emitting = false
	particle.restart()
	particle.emitting = true


func mechanism_burst(world_position: Vector3) -> void:
	splash(world_position + Vector3.UP, 1.7)


func _build_particle(index: int) -> GPUParticles3D:
	var particle := GPUParticles3D.new()
	particle.name = "PaintSplash%02d" % (index + 1)
	particle.emitting = false
	particle.one_shot = true
	particle.explosiveness = 0.95
	particle.lifetime = 0.72
	particle.randomness = 0.36
	particle.visibility_aabb = AABB(Vector3(-18.0, -12.0, -18.0), Vector3(36.0, 32.0, 36.0))
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = 0.5
	process_material.direction = Vector3.UP
	process_material.spread = 78.0
	process_material.initial_velocity_min = 5.0
	process_material.initial_velocity_max = 11.0
	process_material.gravity = Vector3(0.0, -16.0, 0.0)
	process_material.scale_min = 0.5
	process_material.scale_max = 1.45
	process_material.color = Color(0.035, 0.38, 0.98, 0.94)
	particle.process_material = process_material
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.035, 0.38, 0.98, 1.0)
	material.roughness = 0.3
	mesh.material = material
	particle.draw_pass_1 = mesh
	return particle

