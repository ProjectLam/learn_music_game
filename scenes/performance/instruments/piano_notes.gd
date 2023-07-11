extends InstrumentNotes


signal note_spawned()
signal note_destroyed()


var last_center: float = 0.0


func _ready():
	InstrumentInput.mode = InputInstrument.Modes.KEYBOARD
	super._ready()


func spawn_note(note_index: int):
	super.spawn_note(note_index)
	var note_data: Note = _performance_notes[note_index]
	var note = note_scene.instantiate()
#	note.speed = note_speed
	add_child(note)
	
	var position_index: int = NoteFrequency.CHROMATIC.find(note_data.get_pitch())
	note.position = $"../SpawnPositions".get_child(position_index).position
	
	note.position.z = -get_note_offset(note_data.time)
	
	note.color = Color.from_string("#35819d", Color.LIGHT_SKY_BLUE)
	note.end_point = Vector3(note.position.x, note.position.y, -get_note_offset(note_data.time + note_data.sustain) - note.position.z)
#	note.duration = note_data.sustain
	note.index = note_index
	note.instrument_notes = self
	note.note_visuals = note_visuals
	
	spawned_note_nodes[note_index] = note
	
	# Signals
#	note.tree_exited.connect(on_note_destroyed)
#	note_spawned.emit()
	


func spawn_chord(note_index: int):
	super.spawn_chord(note_index)
	var chord_data: Chord = _performance_notes[note_index]
	var notes := []
	for pitch in chord_data.get_pitches():
		var note = note_scene.instantiate()
		add_child(note)
		
		var position_index: int = NoteFrequency.CHROMATIC.find(pitch)
		note.position = $"../SpawnPositions".get_child(position_index).position
		
		note.position.z = -get_note_offset(chord_data.time)
		note.end_point = Vector3(note.position.x, note.position.y, -get_note_offset(chord_data.time + chord_data.sustain) - note.position.z)
		note.color = Color.from_string("#35819d", Color.LIGHT_SKY_BLUE)
		
		note.index = note_index
		note.instrument_notes = self
		note.note_visuals = note_visuals
		
		notes.append(note)
	
	spawned_note_nodes[note_index] = notes


func get_notes_center_x():
	if get_child_count() == 0:
		return last_center
	
	var sum := 0.0
	for note in get_children():
		sum += note.position.x
	
	last_center = sum / get_child_count()
	return last_center


func on_note_destroyed():
	note_destroyed.emit()


#func clear():
#	super.clear()
#	for c in get_children():
#		c.queue_free()
