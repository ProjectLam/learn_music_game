extends Node


signal note_started(frequency)
signal note_ended(frequency)

var current_instrument := 0


func _ready():
	connect_instrument(current_instrument)


func get_instrument_input()->Array:
	return get_child(current_instrument).get_inputs()


func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		disconnect_instrument(current_instrument)
		current_instrument = (current_instrument + 1) % get_child_count()
		connect_instrument(current_instrument)
		print("Switched to instrument ", get_child(current_instrument).name)


func disconnect_instrument(index: int):
	get_child(index).note_started.disconnect(on_note_started)
	get_child(index).note_ended.disconnect(on_note_ended)


func connect_instrument(index: int):
	get_child(index).note_started.connect(on_note_started)
	get_child(index).note_ended.connect(on_note_ended)


func on_note_started(frequency):
	note_started.emit(frequency)


func on_note_ended(frequency):
	note_ended.emit(frequency)
