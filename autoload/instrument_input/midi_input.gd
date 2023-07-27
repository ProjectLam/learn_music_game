extends InputInstrument


const MIDI_OFFSET = -21

var notes: PackedByteArray

var midi_auto_release := false
var midi_auto_release_period := 0.1
var current_midi_inputs := {
	
}


func _ready():
	super._ready()
	OS.open_midi_inputs()
	
	notes.resize(NoteFrequency.CHROMATIC.size())
	notes.fill(0)

var time := 0.0
func _process(delta: float) -> void:
	time += delta
	
	if midi_auto_release:
		for cindex in current_midi_inputs:
			var t = current_midi_inputs[cindex]
			if t - midi_auto_release_period > time:
				_on_note_ended(cindex)


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
		if Debug.print_note:
			print("MIDI Event (index, pressed): (%s, %s)" % [event.pitch, event.message == MIDI_MESSAGE_NOTE_ON])
		var pressed: bool = event.message == MIDI_MESSAGE_NOTE_ON
		var chromatic_index = event.pitch + MIDI_OFFSET
		if chromatic_index < 0 or chromatic_index >= NoteFrequency.CHROMATIC.size():
			return
		if pressed:
			_on_note_started(chromatic_index)
		elif not midi_auto_release:
			_on_note_ended(chromatic_index)
				


func get_device_names() -> PackedStringArray:
	return OS.get_connected_midi_inputs()


func _on_note_started(chromatic_index: int) -> void:
#	pass
	current_midi_inputs[chromatic_index] = time
	var string_fret = chromatic_index_to_fret(chromatic_index)
	match(mode):
		Modes.KEYBOARD:
			notes[chromatic_index] = 1
			note_started.emit(NoteFrequency.CHROMATIC[chromatic_index])
		Modes.FRET:
			notes[chromatic_index] = 1
			fret_started.emit(string_fret.x, string_fret.y)


func _on_note_ended(chromatic_index: int) -> void:
	current_midi_inputs.erase[chromatic_index]
	var string_fret = chromatic_index_to_fret(chromatic_index)
	match(mode):
		Modes.KEYBOARD:
			notes[chromatic_index] = 1
			note_started.emit(NoteFrequency.CHROMATIC[chromatic_index])
		Modes.FRET:
			notes[chromatic_index] = 1
			fret_started.emit(string_fret.x, string_fret.y)
