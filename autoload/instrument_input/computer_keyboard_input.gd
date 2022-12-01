extends InputInstrument
# The computer keyboard input functions just like a midi instrument; only the changes to a state are
# recorded and emitted. The keyboard is played like a piano; the middle row (ASDFGHHJKL; on a US
# keyboard) correspond to white keys starting at C and keys on the row above are black keys whenever
# a piano would have a black key (WETYUOP on a US keyboard). The Z and X keys let the user move an
# octave up or down respectively.


signal octave_changed(new_offset)


# Middle C
var offset: int = 3 + 3 * 12

var note_data := [
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new(),
	NoteData.new()
]


func activate():
	set_process_input(true)
	super.activate()


func deactivate():
	set_process_input(false)
	super.deactivate()


func _input(event):
	if event is InputEventKey:
		if event.physical_keycode == KEY_Z and event.pressed:
			offset -= 12 if offset >= 12 else 0
			octave_changed.emit(offset)
			Debug.print_to_screen(str(name) + ": Octave down")
		elif event.physical_keycode == KEY_X and event.pressed:
			# The computer keyboard has 17 keys available
			offset += 12 if offset < NoteFrequency.CHROMATIC.size() - 17 else 0
			octave_changed.emit(offset)
			Debug.print_to_screen(str(name) + ": Octave up")
		
		match event.physical_keycode:
			KEY_A:
				toggle_note(0, event.pressed)
			KEY_W:
				toggle_note(1, event.pressed)
			KEY_S:
				toggle_note(2, event.pressed)
			KEY_E:
				toggle_note(3, event.pressed)
			KEY_D:
				toggle_note(4, event.pressed)
			KEY_F:
				toggle_note(5, event.pressed)
			KEY_T:
				toggle_note(6, event.pressed)
			KEY_G:
				toggle_note(7, event.pressed)
			KEY_Y:
				toggle_note(8, event.pressed)
			KEY_H:
				toggle_note(9, event.pressed)
			KEY_U:
				toggle_note(10, event.pressed)
			KEY_J:
				toggle_note(11, event.pressed)
			KEY_K:
				toggle_note(12, event.pressed)
			KEY_O:
				toggle_note(13, event.pressed)
			KEY_L:
				toggle_note(14, event.pressed)
			KEY_P:
				toggle_note(15, event.pressed)
			KEY_SEMICOLON:
				toggle_note(16, event.pressed)


func get_inputs()->Array:
	var inputs := []
	for note in note_data:
		if note.pressed:
			inputs.append(note.frequency)
	return inputs


func toggle_note(note, pressed):
	if pressed and not note_data[note].pressed:
		note_data[note].press(NoteFrequency.CHROMATIC[offset + note])
		note_started.emit(note_data[note].frequency)
	elif not pressed and note_data[note].pressed:
		note_data[note].release()
		note_ended.emit(note_data[note].frequency)


class NoteData:
	var frequency: float = 0.0
	var pressed: bool = false
	
	func press(_frequency):
		frequency = _frequency
		pressed = true
	
	func release():
		pressed = false
