extends Control

const NOTE_SCENE := preload("res://scenes/tuner/string_note.tscn")

var time_length := 8.0

func _ready():
	refresh()


func _process(delta):
	var speed = size.y/time_length
	for child in get_children():
		child.position.y -= delta*speed
		if child.position.y < -100.0:
			child.queue_free()


func refresh() -> void:
	if not is_inside_tree():
		return


func add_note(octave: int, _color: Color) -> void:
	print("Adding Note To String")
	var note_node := NOTE_SCENE.instantiate()
	note_node.index = octave
	note_node.position.y = size.y
	note_node.position.x = 0
	add_child(note_node)
