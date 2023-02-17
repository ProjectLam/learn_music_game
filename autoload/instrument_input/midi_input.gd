extends InputInstrument


const MIDI_OFFSET = -21

var notes: PackedByteArray


func _ready():
	super._ready()
	OS.open_midi_inputs()
	
	notes.resize(NoteFrequency.CHROMATIC.size())
	notes.fill(0)


func activate():
	set_process_input(true)
	super.activate()


func deactivate():
	set_process_input(false)
	super.deactivate()


func get_inputs()->Array:
	var inputs = []
	
	for i in notes.size():
		if notes[i] == 1:
			inputs.append(NoteFrequency.CHROMATIC[i])
	
	return inputs


func _input(event):
	if event is InputEventMIDI and (event.message == MIDI_MESSAGE_NOTE_ON or event.message == MIDI_MESSAGE_NOTE_OFF):
		var chromatic_index = event.pitch + MIDI_OFFSET
		if chromatic_index < 0 or chromatic_index >= NoteFrequency.CHROMATIC.size():
			return
		if event.message == MIDI_MESSAGE_NOTE_ON and notes[chromatic_index] != 1:
			notes[chromatic_index] = 1
			note_started.emit(NoteFrequency.CHROMATIC[event.pitch + MIDI_OFFSET])
		elif event.message == MIDI_MESSAGE_NOTE_OFF and notes[chromatic_index] != 0:
			notes[chromatic_index] = 0
			note_ended.emit(NoteFrequency.CHROMATIC[event.pitch + MIDI_OFFSET])
