extends Node


signal note_started(frequency)
signal note_ended(frequency)

var current_instrument := 0
var instrument_count := 0


func _ready():
	connect_instrument(current_instrument)
	for child in get_children():
		if child is InputInstrument:
			instrument_count += 1
			if instrument_count > 1:
				child.deactivate()


func get_instrument_input()->Array:
	return get_child(current_instrument).get_inputs()


func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		disconnect_instrument(current_instrument)
		current_instrument = (current_instrument + 1) % instrument_count
		connect_instrument(current_instrument)
		Debug.print_to_screen("Instrument: " + str(get_child(current_instrument).name), true)


func disconnect_instrument(index: int):
	get_child(index).deactivate()
	get_child(index).note_started.disconnect(on_note_started)
	get_child(index).note_ended.disconnect(on_note_ended)


func connect_instrument(index: int):
	get_child(index).activate()
	get_child(index).note_started.connect(on_note_started)
	get_child(index).note_ended.connect(on_note_ended)


func on_note_started(frequency):
	note_started.emit(frequency)
	Debug.print_to_screen(str(get_child(current_instrument).name) + ": " + NoteFrequency.CHROMATIC_NAMES[NoteFrequency.CHROMATIC.find(frequency)])


func on_note_ended(frequency):
	note_ended.emit(frequency)
