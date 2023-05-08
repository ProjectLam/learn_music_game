extends Node


signal note_started(frequency)
signal note_ended(frequency)
signal chord_started(frequencies)
signal chord_ended(frequencies)


var current_instrument := 0
var instrument_count := 0

@onready var microphone_input = %MicrophoneInput


func _ready():
	for child in get_children():
		if child is InputInstrument:
			instrument_count += 1
			if instrument_count > 1:
				child.deactivate()
	connect_instrument(get_instrument_index(PlayerVariables.selected_hw_instrument))


func set_instrument_by_index(index: int):
	disconnect_instrument(current_instrument)
	current_instrument = index
	connect_instrument(current_instrument)
	Debug.print_to_screen("Instrument: " + str(get_child(current_instrument).name))


func set_instrument_by_name(instrument_name: String):
	set_instrument_by_index(get_instrument_index(instrument_name))


func get_instrument_input()->Array:
	return get_child(current_instrument).get_inputs()


func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		set_instrument_by_index((current_instrument + 1) % instrument_count)


func disconnect_instrument(index: int):
	get_child(index).note_started.disconnect(on_note_started)
	get_child(index).note_ended.disconnect(on_note_ended)
	get_child(index).deactivate()


func connect_instrument(index: int):
	get_child(index).note_started.connect(on_note_started)
	get_child(index).note_ended.connect(on_note_ended)
	get_child(index).activate()
	current_instrument = index


func on_note_started(frequency):
	note_started.emit(frequency)
	Debug.print_to_screen(str(get_child(current_instrument).name) + ": " + NoteFrequency.CHROMATIC_NAMES[NoteFrequency.CHROMATIC.find(frequency)])


func on_note_ended(frequency):
	note_ended.emit(frequency)


func get_instrument_name(index: int)->String:
	return str(get_child(index).name)


func get_instrument_index(instrument_name: String)->int:
	return get_node(instrument_name).get_index()


func get_instrument(index: int)->InputInstrument:
	return get_child(index)
