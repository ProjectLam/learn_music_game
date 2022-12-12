class_name Note

var time: float = 0
var linkNext: int
var accent: int
var bend: int
var fret: int
var hammerOn: int
var harmonic: int
var hopo: int
var ignore: int
var leftHand: int
var mute: int
var palmMute: int
var pluck: int
var pullOff: int
var slap: int
var slideTo: int
var string: int
var sustain: float
var tremolo: int
var harmonicPinch: int
var pickDirection: int
var rightHand: int
var slideUnpitchTo: int
var tap: int
var vibrato: int


func get_pitch() -> float:
	var string_chromatic_indices = [
		NoteFrequency.CHROMATIC.find(NoteFrequency.E2),
		NoteFrequency.CHROMATIC.find(NoteFrequency.A2),
		NoteFrequency.CHROMATIC.find(NoteFrequency.D3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.G3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.B3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.E4),
	]

	# Adding 1 because fret 1 is at index 0.
	var index = string_chromatic_indices[string] + fret + 1

	return NoteFrequency.CHROMATIC[index]
