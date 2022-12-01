extends Node3D


@export var key_nodes : Array[NodePath]


func _ready():
	InstrumentInput.note_started.connect(on_note_started)
	InstrumentInput.note_ended.connect(on_note_ended)


func on_note_started(frequency: float):
	var note_index: int = NoteFrequency.CHROMATIC.find(frequency)
	var key: Node3D = get_node(key_nodes[note_index]) as Node3D
	
	get_tree().create_tween().tween_property(key, "rotation", Vector3(deg_to_rad(3), 0, 0), 0.03)


func on_note_ended(frequency: float):
	var note_index: int = NoteFrequency.CHROMATIC.find(frequency)
	var key: Node3D = get_node(key_nodes[note_index]) as Node3D
	
	get_tree().create_tween().tween_property(key, "rotation", Vector3(0, 0, 0), 0.05)
