extends InstrumentNotes


func spawn_note(note_data: Note, note_index: int):
	super.spawn_note(note_data, note_index)
	
	var note = note_scene.instantiate()
	note.speed = note_speed
	add_child(note)
	
	note.position = Vector3(
		0,
		0,
		-note_speed * (note_data.time - time)
	)
	
	note.color = Color.from_string("#35819d", Color.LIGHT_SKY_BLUE)
	note.duration = note_data.sustain
	note.index = note_index
