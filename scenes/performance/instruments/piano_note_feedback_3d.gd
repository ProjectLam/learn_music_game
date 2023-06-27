extends Node3D

@onready var gpu_particles_3d = %GPUParticles3D

func _ready():
	gpu_particles_3d.emitting = true


func _process(delta):
	if not gpu_particles_3d.emitting:
		queue_free()
