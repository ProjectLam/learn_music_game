class_name InstrumentChord
extends InstrumentNote


@export var chord_tone_scene: PackedScene

var notes: Dictionary
var playing: Dictionary
var played: Dictionary


func add_note(note_position: Vector3, color: Color, pitch: float):
	var note_node: Node3D = chord_tone_scene.instantiate()
	add_child(note_node)
	note_node.position = note_position
	notes[pitch] = note_node
	note_node.color = color


func has_pitch(pitch: float) -> bool:
	return notes.keys().has(pitch)


func get_is_playing() -> bool:
	return playing.size() > 0


func has_finished() -> bool:
	return notes.size() == 0 and playing.size() == 0


func play_pitch(pitch: float):
	if has_pitch(pitch):
		playing[pitch] = notes[pitch]
		notes.erase(pitch)


func release_pitch(pitch: float):
	if playing.has(pitch):
		played[pitch] = playing[pitch]
		playing.erase(pitch)


func num_notes_remaining() -> int:
	return notes.size()
