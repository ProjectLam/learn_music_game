@tool
extends PanelContainer

@onready var strings_containter = %StringsContainter
@export_range(3.0, 20.0) var time_length := 8.0:
	set = set_time_length

# string nodes in order from A to G#.
var string_nodes := []

func _ready():
	if not Engine.is_editor_hint():
		InstrumentInput.connect_instrument(InstrumentInput.find_child("MicrophoneInput").get_index())
		InstrumentInput.microphone_input.note_started.connect(_on_note_started)
		InstrumentInput.microphone_input.note_ended.connect(_on_note_ended)
		
		string_nodes = [
			strings_containter.get_node("A"),
			strings_containter.get_node("Bb"),
			strings_containter.get_node("B"),
			strings_containter.get_node("C"),
			strings_containter.get_node("Cs"),
			strings_containter.get_node("D"),
			strings_containter.get_node("Eb"),
			strings_containter.get_node("E"),
			strings_containter.get_node("F"),
			strings_containter.get_node("Fs"),
			strings_containter.get_node("G"),
			strings_containter.get_node("Gs"),
		]
		
		assert(string_nodes.size() == 12)
	
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	if Engine.is_editor_hint():
		return
	
	for child in strings_containter.get_children():
		child.time_length = time_length


func _on_note_started(frequency):
	var note = NoteFrequency.CHROMATIC.find(frequency)
	var note_idx = (note + 1)%12 - 1
	var string_node: Control = string_nodes[note_idx]
	string_node.add_note(frequency)


func _on_note_ended(frequency):
	pass

func set_time_length(value: float) -> void:
	if time_length != value:
		time_length = value
#		refresh()
