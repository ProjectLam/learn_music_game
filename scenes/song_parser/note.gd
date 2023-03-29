class_name Note


var time: float
var link_next: bool
var accent: bool
var bend: bool
var fret: int
var hammer_on: bool
var harmonic: bool
var hopo: bool
var ignore: bool
var left_hand: int
var mute: bool
var palm_mute: bool
var pluck: int
var pull_off: bool
var slap: int
var slide_to: int = -1
var string: int
var sustain: float
var tremolo: bool
var harmonic_pinch: bool
var pick_direction: bool
var right_hand: int
var slide_unpitch_to: int = -1
var tap: bool
var vibrato: bool


func get_pitch()->float:
	var string_chromatic_indices = [
		NoteFrequency.CHROMATIC.find(NoteFrequency.E2),
		NoteFrequency.CHROMATIC.find(NoteFrequency.A2),
		NoteFrequency.CHROMATIC.find(NoteFrequency.D3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.G3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.B3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.E4),
	]
	
	var index = string_chromatic_indices[string] + fret
	
	return NoteFrequency.CHROMATIC[index]
