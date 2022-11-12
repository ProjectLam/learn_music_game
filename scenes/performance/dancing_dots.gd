extends MultiMeshInstance3D


@export var should_extend_left: bool = false
@export var num_dots_x: int = 20
@export var num_dots_z: int = 20
@export var spacing: float = 1.0
@export var noise_speed: float = 1.0
@export var noise_frequency: float = 10.0
@export var noise_strength: float = 10.0

@export var points_strength = 4.0
@export var speaker_strength = 1.0
@export var steps = 16
@export var max_freq = 11050.0
@export var min_db = 60

@export var interpolation_delay = 200
var interpolation_time = 0
var interpolation_direction = false

var spectrum

var frequencies = PackedByteArray()
var heights = []

var noise: FastNoiseLite
var noise_offset: float = 0.0

@onready var nSpeaker = $"../Speaker"

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
	
	steps = num_dots_x * num_dots_z
	
	for i in steps:
		frequencies.append(0)
	
	for i in steps:
		heights.append(0)
	
	spectrum = AudioServer.get_bus_effect_instance(0, 0)


func _process(delta):
	if steps != len(heights):
		frequencies = []
		heights = []

		for i in range(steps):
			frequencies.append(0)

		for i in range(steps):
			heights.append(0)
	
	var time = Time.get_ticks_msec()
	var phz = 0
	var diff = time - interpolation_time
	var curr = float(diff) / interpolation_delay
	if curr > 1:
			curr = 1
	
	var i = 0
	for z in num_dots_z:
		for x in num_dots_x:
			if i >= len(heights):
				break
			
			var hz = i * max_freq / steps
			var magnitude: float = spectrum.get_magnitude_for_frequency_range(phz, hz).length()
			var energy = clamp((min_db + linear_to_db(magnitude)) / min_db, 0, 1)
		
			phz = hz
		
			if diff >= interpolation_delay:
				heights[i] = energy
		
			var height = curr * heights[i]
			if interpolation_direction:
				height = (1 - curr) * heights[i]
			
			frequencies[i] = height
			
			var index = z * num_dots_x + x
			multimesh.set_instance_transform(
				index,
				Transform3D(
					Basis.IDENTITY,
					Vector3(x, 0, z) * spacing + Vector3.UP * height * points_strength
				)
			)
			
			if not nSpeaker:
				nSpeaker = $"../Speaker"
			
			nSpeaker.get_surface_override_material(0).set_shader_parameter("swirling", (PI) * energy)
			nSpeaker.get_surface_override_material(0).set_shader_parameter("deconstruction", 1)
			nSpeaker.get_surface_override_material(0).set_shader_parameter("power", speaker_strength * energy)
			nSpeaker.get_surface_override_material(0).set_shader_parameter("radius", speaker_strength * energy)
			
			i += 1
	
	if diff >= interpolation_delay:
		interpolation_time = Time.get_ticks_msec()
		interpolation_direction = not interpolation_direction
