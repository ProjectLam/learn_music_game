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
@export var phin_position = Vector3(7.596, 6.039, 8.259)
@export var phin_rotation_degrees = Vector3(-8.1, 3, 0)


func _ready():
	_on_instrument_changed()
	SessionVariables.instrument_changed.connect(_on_instrument_changed)


func _on_instrument_changed():
	print("reconfiguring camera for session instrument [%s]" % SessionVariables.instrument)
	match SessionVariables.instrument.to_lower():
		"guitar.tres":
			set_camera_position(guitar_position, guitar_rotation_degrees)
		"piano.tres":
			set_camera_position(piano_position, piano_rotation_degrees)
		"phin.tres":
			set_camera_position(phin_position, phin_rotation_degrees)
	
	home = position


func set_camera_position(_position: Vector3, _rotation_degrees: Vector3):
	position = _position
	rotation = Vector3(
		deg_to_rad(_rotation_degrees.x),
		deg_to_rad(_rotation_degrees.y),
		deg_to_rad(_rotation_degrees.z)
	)


func _process(delta):
	noise_offset += delta * noise_frequency
	position = home + noise_amplitude * Vector3(noise.get_noise_1d(noise_offset), noise.get_noise_2d(0, noise_offset), 0)
