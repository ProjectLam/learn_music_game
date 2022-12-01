extends Camera3D


@export var noise: FastNoiseLite
@export var noise_amplitude: float = 2.0
@export var noise_frequency: float = 2.0

var noise_offset: float = 0.0
# Used for the noise-based movement
var home: Vector3

@export var guitar_position = Vector3(7.596, 6.039, 8.259)
@export var guitar_rotation_degrees = Vector3(-8.1, 3, 0)
@export var piano_position = Vector3(0, 6.039, 8.259)
@export var piano_rotation_degrees = Vector3(-8.1, 0, 0)


func _ready():
	position = piano_position
	rotation = Vector3(
			deg_to_rad(piano_rotation_degrees.x),
			deg_to_rad(piano_rotation_degrees.y),
			deg_to_rad(piano_rotation_degrees.z)
		)
	home = position


func _process(delta):
	noise_offset += delta * noise_frequency
	position = home + noise_amplitude * Vector3(noise.get_noise_1d(noise_offset), noise.get_noise_2d(0, noise_offset), 0)
