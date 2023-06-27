extends NoteBase

class_name Note

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
