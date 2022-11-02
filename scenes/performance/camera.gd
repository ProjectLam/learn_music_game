extends Camera3D


@export var noise: FastNoiseLite
@export var noise_amplitude: float = 2.0
@export var noise_frequency: float = 2.0

var noise_offset: float = 0.0

@onready var home = position


func _process(delta):
	noise_offset += delta * noise_frequency
	position = home + noise_amplitude * Vector3(noise.get_noise_1d(noise_offset), noise.get_noise_2d(0, noise_offset), 0)
