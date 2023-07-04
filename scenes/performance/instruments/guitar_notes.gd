extends InstrumentNotes


# The colors for the guitar strings, from bottom to top
@export var string_colors: PackedColorArray

# How far apart the strings are
@export var string_spacing: float
# How far up from the world origin the first string is
@export var string_offset: float
# How far apart the frets are
@export var fret_spacing: float
# How far to the right from the world origin the first note should hit
@export var fret_offset: float


#func _ready():
#	position.z -= get_press_area_spacing()


func spawn_note(note_index: int):
	super.spawn_note(note_index)
	var note_data: Note = _performance_notes[note_index]
	var note = note_scene.instantiate()
#	note.speed = note_speed
	var position_index: int = NoteFrequency.CHROMATIC.find(note_data.get_pitch())
	add_child(note)
	note.position = Vector3(
		fret_offset + fret_spacing * note_data.fret,
		_get_string_y(note_data.string),
		-get_note_offset(note_data.time)
	)
	note.color = string_colors[note_data.string]
	note.index = note_index
	note.end_point = Vector3(note.position.x, note.position.y, -get_note_offset(note_data.time + note_data.sustain) - note.position.z)
	note.instrument_notes = self
#	note.note_visuals = note_visuals
	
	if note_data.fret == 0:
		# Open string
		note.switch_to_open()
	
	if note_data.vibrato:
		note.set_vibrato()
	
	if note_data.slide_to > -1:
		note.set_slide_pitched(fret_spacing * (note_data.slide_to - note_data.fret))
	
	if note_data.slide_unpitch_to > -1:
		print("Slide: ", note_data.slide_unpitch_to - note_data.fret)
		note.set_slide_unpitched(fret_spacing * (note_data.slide_unpitch_to - note_data.fret))
	
	note.render()


func spawn_chord(note_index: int):
	super.spawn_chord(note_index)
	var chord_data: Chord = _performance_notes[note_index]
	var chord = chord_scene.instantiate()
#	chord.speed = note_speed
	add_child(chord)
	chord.position = Vector3(0, 0, -note_speed * (chord_data.time - time))
	chord.end_point = Vector3(chord.position.x, chord.position.y, -get_note_offset(chord_data.time + chord_data.sustain) - chord.position.z)
	chord.instrument_notes = self
	var frets := chord_data.get_frets()
	for string in frets.size():
		if frets[string] == -1:
			continue
		
		var pitch := chord_data.get_pitch_for_string(string)
		chord.add_note(Vector3(fret_offset + fret_spacing * frets[string], _get_string_y(string), 0), string_colors[string], pitch)
		if frets[string] == 0:
			chord.switch_to_open(pitch)


func _get_string_y(string_index):
	# Strings start at index 0, 0 being the low E (top string)
	return string_offset + (5 - string_index) * string_spacing
