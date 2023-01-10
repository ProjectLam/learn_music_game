extends MeshInstance3D


var sound_effect_scene: PackedScene = preload("res://scenes/performance/speaker_sound.tscn")

func _ready():
	await get_tree().process_frame
	# TODO : node_started was null when testing.
	get_parent().performance_instrument.note_started.connect(on_note_started)


func on_note_started(_note_data):
	var sound_effect = sound_effect_scene.instantiate()
	$SpeakerCone/Marker3D.add_child(sound_effect)
