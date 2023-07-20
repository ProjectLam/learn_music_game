extends Node3D

const FRET_SCENE := preload("res://instruments/string_instrument/string_fret_particles.tscn")
const OPEN_STRING_SCENE := preload("res://instruments/string_instrument/string_open_particles.tscn")
@onready var strings = %Strings
@onready var frets = %Frets
@onready var notes = %Notes

var fret_node_map := {}

func _ready():
	if not Engine.is_editor_hint():
		notes.input_fret_started.connect(_on_fret_started)
		notes.input_fret_ended.connect(_on_fret_ended)
#		notes.input_note_stareted.connect(_on_note_started)
#		notes.input_note_ended.connect(_on_note_ended)
	
	refresh()


func refresh():
	pass
#	for c in get_children():
#		c.queue_free()
#
#	fret_node_map.clear()


func _on_fret_started(string: int, fret: int) -> void:
	var fnode = fret_node_map.get(Vector2i(string, fret))
	if fnode:
		return
	
	if fret == 0:
		var scolor: Color = strings.get_string_color(string)
		var string_pos: Vector3 = strings.get_string_global_position(string)
		var open_string_node = OPEN_STRING_SCENE.instantiate()
		fret_node_map[Vector2i(string, 0)] = open_string_node
		add_child(open_string_node)
		open_string_node.color = scolor
		open_string_node.mesh_size.x = frets.fret_space
		open_string_node.position = string_pos + Vector3(frets.fret_space*0.5,0,0)
		open_string_node.emitting = true
	else:
		var xsize: float = frets.fret_space/(frets.fret_count + 1)
		var scolor: Color = strings.get_string_color(string)
		var string_pos: Vector3 = strings.get_string_global_position(string)
		string_pos.x = frets.get_note_global_x(fret)
		var fret_node = FRET_SCENE.instantiate()
		fret_node_map[Vector2i(string, fret)] = fret_node
		add_child(fret_node)
		fret_node.color = scolor
		fret_node.mesh_size.x = xsize
		fret_node.global_position = string_pos# + Vector3(frets.fret_space*0.5,0,0)
		fret_node.emitting = true
		
			
#	if fnode:
#		fnode.emitting = true


func _on_fret_ended(string: int, fret: int) -> void:
	var fnode = fret_node_map.get(Vector2i(string, fret))
	if fnode:
		fnode.emitting = false
	
	fret_node_map[Vector2i(string, fret)] = null


#func _on_note_started()
