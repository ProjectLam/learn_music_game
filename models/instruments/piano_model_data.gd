extends Node3D


@export var key_nodes : Array[NodePath]

var tweens := {
	
}

func _ready():
	InstrumentInput.note_started.connect(on_note_started)
	InstrumentInput.note_ended.connect(on_note_ended)


func on_note_started(frequency: float):
	var note_index: int = NoteFrequency.CHROMATIC.find(frequency)
	if key_nodes.size() <= note_index:
		return
	var key: Node3D = get_node(key_nodes[note_index]) as Node3D
	
	var key_tween := key.create_tween()
	var prev_tween = tweens.get(key)
	if prev_tween:
		prev_tween.kill()
	tweens[key] = key_tween
	key_tween.tween_property(key, "rotation", Vector3(deg_to_rad(3), 0, 0), 0.03)


func on_note_ended(frequency: float):
	var note_index: int = NoteFrequency.CHROMATIC.find(frequency)
	if note_index >= key_nodes.size():
		return
	var key: Node3D = get_node(key_nodes[note_index]) as Node3D
	var prev_tween = tweens.get(key)
	if prev_tween:
		prev_tween.kill()
	var key_tween := key.create_tween()
	tweens[key] = key_tween
	key_tween.tween_property(key, "rotation", Vector3(0, 0, 0), 0.05)
