extends Node3D


@export var key_nodes : Array[NodePath]
@onready var notes = %Notes

var tweens := {
	
}

func _ready():
	notes.input_note_started.connect(on_note_started)
	notes.input_note_ended.connect(on_note_ended)
#	InstrumentInput.note_started.connect(on_note_started)
#	InstrumentInput.note_ended.connect(on_note_ended)
	
	# TODO : add exclusion if note starts at the same frame it ends. or 1 frame after it ends.


func on_note_started(chromatic: int):
	var note_index: int = chromatic#NoteFrequency.CHROMATIC.find(frequency)
	if key_nodes.size() <= note_index:
		return
	var key: Node3D = get_node(key_nodes[note_index]) as Node3D
	
	var key_tween := key.create_tween()
	var prev_tween = tweens.get(key)
	if prev_tween:
		prev_tween.kill()
	tweens[key] = key_tween
	key_tween.tween_property(key, "rotation", Vector3(deg_to_rad(3), 0, 0), 0.03)


func on_note_ended(chromatic: int):
	var note_index: int = chromatic#NoteFrequency.CHROMATIC.find(frequency)
	if note_index >= key_nodes.size():
		return
	var key: Node3D = get_node(key_nodes[note_index]) as Node3D
	var prev_tween = tweens.get(key)
	if prev_tween:
		prev_tween.kill()
	var key_tween := key.create_tween()
	tweens[key] = key_tween
	key_tween.tween_property(key, "rotation", Vector3(0, 0, 0), 0.05)
