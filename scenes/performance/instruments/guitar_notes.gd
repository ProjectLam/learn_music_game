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



func _get_string_y(string_index):
	# Strings start at index 0, 0 being the low E (top string)
	return string_offset + (5 - string_index) * string_spacing
