class_name Chord
extends Note


enum Strum { UP, DOWN }

var display_name: String
var chord_name: String
var fret_0: int
var fret_1: int
var fret_2: int
var fret_3: int
var fret_4: int
var fret_5: int

# These seem to be descriptions of which finger is used for each string. Values are 0 <= finger < 5
var finger_0: int
var finger_1: int
var finger_2: int
var finger_3: int
var finger_4: int
var finger_5: int

var strum: Strum
# I imagine this would overlap Note.mute (since there's also a Note.palm_mute, surely the rest are fret hand mutes)
var fret_hand_mute: bool
#@TODO Not sure what high density means, but it seems to correlate with strumming down (for which we also have the strum parameter, so still not sure)
var high_density: bool


func get_pitches() -> Array[float]:
	var pitches: Array[float] = []
	
	var string_chromatic_indices = [
		NoteFrequency.CHROMATIC.find(NoteFrequency.E2),
		NoteFrequency.CHROMATIC.find(NoteFrequency.A2),
		NoteFrequency.CHROMATIC.find(NoteFrequency.D3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.G3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.B3),
		NoteFrequency.CHROMATIC.find(NoteFrequency.E4),
	]
	
	if fret_0 >= 0:
		pitches.append(NoteFrequency.CHROMATIC[string_chromatic_indices[0] + fret_0])
	if fret_1 >= 0:
		pitches.append(NoteFrequency.CHROMATIC[string_chromatic_indices[1] + fret_1])
	if fret_2 >= 0:
		pitches.append(NoteFrequency.CHROMATIC[string_chromatic_indices[2] + fret_2])
	if fret_3 >= 0:
		pitches.append(NoteFrequency.CHROMATIC[string_chromatic_indices[3] + fret_3])
	if fret_4 >= 0:
		pitches.append(NoteFrequency.CHROMATIC[string_chromatic_indices[4] + fret_4])
	if fret_5 >= 0:
		pitches.append(NoteFrequency.CHROMATIC[string_chromatic_indices[5] + fret_5])
	
	return pitches


func is_barre_chord() -> bool:
	return finger_0 >= 0 and (
		finger_0 == finger_1 \
		or finger_0 == finger_2 \
		or finger_0 == finger_3 \
		or finger_0 == finger_4 \
		or finger_0 == finger_5
	) or \
	finger_1 >= 0 and (
		finger_1 == finger_2 \
		or finger_1 == finger_3 \
		or finger_1 == finger_4 \
		or finger_1 == finger_5
	) or \
	finger_2 >= 0 and (
		finger_2 == finger_3 \
		or finger_2 == finger_4 \
		or finger_2 == finger_5
	) or \
	finger_3 >= 0 and (
		finger_3 == finger_4 \
		or finger_3 == finger_5
	) or \
	finger_4 >= 0 and finger_4 == finger_5
