extends Node3D

@onready var gpu_particles_3d = %GPUParticles3D

var width := 1.0:
	set = set_width

func _ready():
	gpu_particles_3d.emitting = true
	gpu_particles_3d["draw_pass_1"]["size"].x = width


func _process(delta):
	if not gpu_particles_3d.emitting:
		queue_free()


func set_width(value: float) -> void:
	if width != value:
		width = value
