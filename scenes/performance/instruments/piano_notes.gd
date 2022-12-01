extends InstrumentNotes


signal note_spawned()
signal note_destroyed()


var last_center: float = 0.0


func spawn_note(note_data: Note, note_index: int):
	super.spawn_note(note_data, note_index)
	
	var note = note_scene.instantiate()
	note.speed = note_speed
	add_child(note)
	
	var position_index: int = NoteFrequency.CHROMATIC.find(note_data.get_pitch())
	note.position = $"../SpawnPositions".get_child(position_index).position
	
	note.position.z = -note_speed * (note_data.time - time)
	
	note.color = Color.from_string("#35819d", Color.LIGHT_SKY_BLUE)
	note.duration = note_data.sustain
	note.index = note_index
	
	# Signals
	note.tree_exited.connect(on_note_destroyed)
	note_spawned.emit()


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
