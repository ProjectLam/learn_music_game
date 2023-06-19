extends InstrumentChord


@onready var chord_box = $ChordBox
@onready var duration_tail = $ChordBox/DurationTail

var min_x: float = INF


func add_note(note_position: Vector3, color: Color, pitch: float):
	super.add_note(note_position, color, pitch)
	
	min_x = min(note_position.x, min_x)
	reposition_chord()


func switch_to_open(note_frequency: float):
	# Realistically this function will only be called when the note is in notes, but let's be thorough
	if notes.has(note_frequency):
		notes[note_frequency].switch_to_open()
	elif playing.has(note_frequency):
		playing[note_frequency].switch_to_open()
	elif played.has(note_frequency):
		played[note_frequency].switch_to_open()
	
	if notes[note_frequency].position.x == min_x:
		min_x = INF
		for frequency in notes:
			if notes[frequency].is_open:
				continue
			min_x = min(notes[frequency].position.x, min_x)
		if min_x == INF:
			min_x = 0
		
		reposition_chord()


func reposition_chord():
	# Subtract 1 because chord tones are centered
	chord_box.position.x = min_x - 1
	for frequency in notes:
		if notes[frequency].is_open:
			notes[frequency].position.x = min_x - 1


func set_end_point(value: Vector3):
	super.set_end_point(value)
	duration_tail.scale.z = -value.z
