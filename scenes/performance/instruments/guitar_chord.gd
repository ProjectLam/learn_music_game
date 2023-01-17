extends InstrumentChord


func switch_to_open(note_frequency: float):
	# Realistically this function will only be called when the note is in notes, but let's be thorough
	if notes.has(note_frequency):
		notes[note_frequency].switch_to_open()
	elif playing.has(note_frequency):
		playing[note_frequency].switch_to_open()
	elif played.has(note_frequency):
		played[note_frequency].switch_to_open()
