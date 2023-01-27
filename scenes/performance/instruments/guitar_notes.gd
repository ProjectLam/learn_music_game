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


func spawn_note(note_data: Note, note_index: int):
	super.spawn_note(note_data, note_index)
	
	var note = note_scene.instantiate()
	note.speed = note_speed
	add_child(note)
	note.position = Vector3(
		fret_offset + fret_spacing * note_data.fret,
		_get_string_y(note_data.string),
		-note_speed * (note_data.time - time)
	)
	note.color = string_colors[note_data.string]
	note.duration = note_data.sustain
	note.index = note_index
	
	if note_data.fret == 0:
		# Open string
		note.switch_to_open()
	
	if note_data.vibrato:
		note.set_vibrato()
	
	if note_data.slide_to > -1:
		note.set_slide_pitched(fret_spacing * (note_data.fret - note_data.slide_to))
	
	if note_data.slide_unpitch_to > -1:
		note.set_slide_unpitched(fret_spacing * (note_data.fret - note_data.slide_to))
	
	note.render()


func spawn_chord(chord_data: Chord, note_index: int):
	super.spawn_chord(chord_data, note_index)
	
	var chord = chord_scene.instantiate()
	chord.speed = note_speed
	add_child(chord)
	chord.position = Vector3(0, 0, -note_speed * (chord_data.time - time))
	
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
