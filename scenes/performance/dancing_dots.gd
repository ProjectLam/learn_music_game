extends MultiMeshInstance3D


@export var should_extend_left: bool = false
@export var num_dots_x: int = 20
@export var num_dots_z: int = 20
@export var spacing: float = 1.0
@export var noise_speed: float = 1.0
@export var noise_frequency: float = 10.0
@export var noise_strength: float = 10.0

var noise: FastNoiseLite
var noise_offset: float = 0.0


func _ready():
	# Generate meshes
	multimesh.instance_count = num_dots_x * num_dots_z
	for z in num_dots_z:
		for x in num_dots_x:
			var index = z * num_dots_x + x
			multimesh.set_instance_transform(
				index,
				Transform3D(
					Basis.IDENTITY,
					Vector3(x * (1 if should_extend_left else -1), 0, z) * spacing
					)
				)
	
	noise = FastNoiseLite.new()


func _process(delta):
	# Scroll through the noise, using it as an offset for the dots
	# This should probably be replaced with data coming from the audio stream
	for z in num_dots_z:
		for x in num_dots_x:
			var index = z * num_dots_x + x
			multimesh.set_instance_transform(
				index,
				Transform3D(
					Basis.IDENTITY,
					Vector3(x, 0, z) * spacing + Vector3.UP * noise_strength * noise.get_noise_2d(noise_offset + x * noise_frequency, z * noise_frequency)
					)
				)
	
	noise_offset += delta * noise_speed
