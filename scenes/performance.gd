#
# 3D Audio Visualizer
# Copyright (C) 2022, Oğuzhan Eroğlu <rohanrhu2@gmail.com> (https://oguzhaneroglu.com)
#

extends Node3D

@export var strength = 4.0
@export var steps = 16
@export var max_freq = 11050.0
@export var min_db = 60

@export var interpolation_delay = 200
var interpolation_time = 0
var interpolation_direction = false
var interpolation = 1
var interpolation_target = 0

@export var max_distance = 40
@export var min_distance = 25

var spectrum

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	$AudioStreamPlayer3D.play(0)

func _process(delta):
	_process_speakers(delta)

func _process_speakers(delta):
	var magnitude: float = spectrum.get_magnitude_for_frequency_range(7000, max_freq).length()
	var energy = clamp((min_db + linear_to_db(magnitude)) / min_db, 0, 1)
	
	$SoundVizSurfaceOne/Speaker.scale = Vector3(4.0 + energy*3, 4.0 + energy*3, 4.0 + energy*3)

func load_ogg(path: String) -> AudioStreamOggVorbis:
	return AudioStreamOggVorbis.from_filesystem(path)
