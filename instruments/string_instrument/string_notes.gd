extends InstrumentNotes

# The colors for the guitar strings, from bottom to top
@export var string_colors: Array[Color]
# y offset to spawn notes.
@export var string_y_offset := 0.0
@export var has_slide := true

@onready var strings = %Strings
@onready var frets = %Frets
@onready var keyboard_keys = %KeyboardKeys
@onready var string_container = %StringContainer


func _ready():
	InstrumentInput.current_instrument_changed.connect(end_all_notes)
	InstrumentInput.mode = InputInstrument.Modes.FRET
	
	super._ready()
	refresh()
#	string_container.position.z = -get_press_area_spacing()*0.5


# TODO : utilize map_string_note for slide.
func spawn_note(note_index: int):
	super.spawn_note(note_index)
	var note_data: Note = _performance_notes[note_index]
	var mappedsfret = instrument_data.map_string_note(note_data.string, note_data.fret)
	var string = mappedsfret.x
	var fret = mappedsfret.y
	var note = note_scene.instantiate()
	note.note_visuals = note_visuals
	note.open_width = frets.fret_space
	note.color = string_colors[string]
	note.set("text", str(fret))
	note.position = Vector3(
		_get_fret_x(fret),# if fret != 0 else 0.0,
		_get_string_y(string),
		-get_note_offset(note_data.time)
	)
	note.index = note_index
	note.instrument_notes = self
	add_child(note)
	note.end_point = Vector3(note.position.x, note.position.y, -get_note_offset(note_data.time) - position.z)
	
	if fret == 0:
		# Open string
		note.switch_to_open()
	
	if note_data.vibrato:
		note.set_vibrato()
	
	if has_slide:
		if note_data.slide_to > -1:
			note.set_slide_pitched(
					frets.get_fret_x_spacing() 
					* (note_data.slide_to 
					- note_data.fret))
		
		if note_data.slide_unpitch_to > -1:
			print("Slide: ", note_data.slide_unpitch_to - note_data.fret)
			note.set_slide_unpitched(
					frets.get_fret_x_spacing() 
					* (note_data.slide_unpitch_to 
					- note_data.fret))
	
	note.render()
	
	spawned_note_nodes[note_index] = note


# TODO : chords may not be fully implemented.
func spawn_chord(note_index: int):
	super.spawn_chord(note_index)
	var chord_data: Chord = _performance_notes[note_index]
	var chord = chord_scene.instantiate()
	chord.speed = note_speed
	add_child(chord)
	chord.position = Vector3(0, 0, -get_note_offset(chord_data.time))
	chord.instrument_notes = self
	chord.end_point = Vector3(chord.position.x, chord.position.y, -get_note_offset(chord_data.time + chord_data.sustain) - position.z)
#	chord.note_visuals
	var frets := chord_data.get_frets()
	for string in frets.size():
		if frets[string] == -1:
			continue
		
		var pitch := chord_data.get_pitch_for_string(string)
		chord.add_note(Vector3(_get_fret_x(frets[string]), _get_string_y(string), 0), string_colors[string], pitch)
		if frets[string] == 0:
			chord.switch_to_open(pitch)
	
	spawned_note_nodes[note_index] = chord


func _get_string_y(string) -> float:
	# Strings start at index 0, 0 being the low E (top string)
	var string_index = string
#	var string_index = strings.string_count - string - 1
	return strings.get_string_global_position(string_index).y


func _get_fret_x(fret) -> float:
	return frets.get_note_global_x(fret) - global_position.x


func refresh():
	if not is_inside_tree():
		return
	
	var idelay := InstrumentInput.get_detection_delay()
	var idelay_distance := note_speed*idelay
	
	position.z = get_press_area_spacing()*0.4 + idelay_distance
	string_colors = strings.string_colors
	
	instrument_data = owner.instrument_data
