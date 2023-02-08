extends Note
class_name Chord


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


var string_chromatic_indices = [
	NoteFrequency.CHROMATIC.find(NoteFrequency.E2),
	NoteFrequency.CHROMATIC.find(NoteFrequency.A2),
	NoteFrequency.CHROMATIC.find(NoteFrequency.D3),
	NoteFrequency.CHROMATIC.find(NoteFrequency.G3),
	NoteFrequency.CHROMATIC.find(NoteFrequency.B3),
	NoteFrequency.CHROMATIC.find(NoteFrequency.E4),
]


func get_pitches() -> Array[float]:
	var pitches: Array[float] = []
	
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


func get_pitch_for_string(string_index: int) -> float:
	match string_index:
		0:
			return NoteFrequency.CHROMATIC[string_chromatic_indices[0] + fret_0]
		1:
			return NoteFrequency.CHROMATIC[string_chromatic_indices[1] + fret_1]
		2:
			return NoteFrequency.CHROMATIC[string_chromatic_indices[2] + fret_2]
		3:
			return NoteFrequency.CHROMATIC[string_chromatic_indices[3] + fret_3]
		4:
			return NoteFrequency.CHROMATIC[string_chromatic_indices[4] + fret_4]
		5:
			return NoteFrequency.CHROMATIC[string_chromatic_indices[5] + fret_5]
		_:
			return -1.0


func has_pitch(pitch: float) -> bool:
	return get_pitches().has(pitch)


func get_frets() -> Array[int]:
	return [fret_0, fret_1, fret_2, fret_3, fret_4, fret_5]


func get_fingers() -> Array[int]:
	return [finger_0, finger_1, finger_2, finger_3, finger_4, finger_5]


func is_barre_chord() -> bool:
	# True when the same finger is used on more than one string
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


func get_barre_frets() -> Array[int]:
	# This returns an array because there's always a chance that a chord has a "main" barre finger
	# and an additional one - a potential example would be a Dmaj7/A shape moved up.
	# These are edge cases though, you should usually get a single fret from this function.
	var barre_frets: Array[int]
	
	if finger_0 >= 0 and (
		finger_0 == finger_1 \
		or finger_0 == finger_2 \
		or finger_0 == finger_3 \
		or finger_0 == finger_4 \
		or finger_0 == finger_5
	):
		barre_frets.append(fret_0)
	
	if finger_1 >= 0 and (
		finger_1 == finger_2 \
		or finger_1 == finger_3 \
		or finger_1 == finger_4 \
		or finger_1 == finger_5
	) and finger_1 != finger_0:
		barre_frets.append(fret_1)
	
	if finger_2 >= 0 and (
		finger_2 == finger_3 \
		or finger_2 == finger_4 \
		or finger_2 == finger_5
	) and finger_2 != finger_1 and finger_2 != finger_0:
		barre_frets.append(fret_2)
	
	if finger_3 >= 0 and (
		finger_3 == finger_4 \
		or finger_3 == finger_5
	) and finger_3 != finger_2 and finger_2 != finger_1 and finger_3 != finger_0:
		barre_frets.append(fret_3)
	
	if finger_4 >= 0 and finger_4 == finger_5 and finger_4 != finger_0 and finger_4 != finger_1 and finger_4 != finger_2 and finger_4 != finger_3:
		barre_frets.append(fret_4)
	
	return barre_frets
