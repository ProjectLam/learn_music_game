extends Node


signal note_started(frequency)
signal note_ended(frequency)
signal chord_started(frequencies)
signal chord_ended(frequencies)
signal fret_started(string: int, fret: int)
signal fret_ended(string: int, fret: int)

signal current_instrument_changed


var current_instrument := 0:
	set = set_current_instrument
var instrument_count := 0

@onready var microphone_input = %MicrophoneInput
@onready var computer_keyboard_input = %ComputerKeyboardInput


var mode := InputInstrument.Modes.KEYBOARD:
	set = set_mode


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
	# TODO : end any started notes and frets.
	
	get_child(index).note_started.disconnect(on_note_started)
	get_child(index).note_ended.disconnect(on_note_ended)
	get_child(index).fret_started.disconnect(_on_fret_started)
	get_child(index).fret_ended.disconnect(_on_fret_ended)
	get_child(index).deactivate()


func connect_instrument(index: int):
	get_child(index).note_started.connect(on_note_started)
	get_child(index).note_ended.connect(on_note_ended)
	get_child(index).fret_started.connect(_on_fret_started)
	get_child(index).fret_ended.connect(_on_fret_ended)
	get_child(index).mode = mode
	get_child(index).activate()
	current_instrument = index


func on_note_started(frequency):
	note_started.emit(frequency)
	Debug.print_to_screen(str(get_child(current_instrument).name) + ": " + NoteFrequency.CHROMATIC_NAMES[NoteFrequency.CHROMATIC.find(frequency)])


func on_note_ended(frequency):
	note_ended.emit(frequency)


func _on_fret_started(string: int, fret: int) -> void:
	fret_started.emit(string, fret)


func _on_fret_ended(string: int, fret: int) -> void:
	fret_ended.emit(string, fret)


func get_instrument_name(index: int)-> String:
	return str(get_child(index).name)


func get_device_names(index: int) -> PackedStringArray:
	return get_child(index).get_device_names()


func get_instrument_index(instrument_name: String)->int:
	return get_node(instrument_name).get_index()


func get_instrument(index: int)->InputInstrument:
	return get_child(index)


func set_current_instrument(value) -> void:
	if current_instrument != value:
		current_instrument = value
		PlayerVariables.selected_hw_instrument = get_child(current_instrument).name
		PlayerVariables.save()
		current_instrument_changed.emit()


func set_mode(value: InputInstrument.Modes) -> void:
	if mode != value:
		mode = value
	var inst = get_child(current_instrument)
	if inst:
		inst.mode = value


func select_instrument_name(iname: String) -> void:
	var inode = get_node_or_null(iname)
	if inode != null:
		current_instrument = inode.get_index()
	else:
		PlayerVariables.selected_hw_instrument = get_child(current_instrument).name
		PlayerVariables.save()


func is_input_direct_fret() -> bool:
	return current_instrument == 2


func get_detection_delay() -> float:
	return get_child(current_instrument).detection_delay
