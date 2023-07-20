@tool
extends Node3D

signal changed

@onready var strings = %Strings

@export var fret_scene: PackedScene
@export var nut_scene: PackedScene
@export var fret_count: int:
	set = set_fret_count
@export var fret_space: float = 6.0:
	set = set_fret_space
@export var fret_margins: float = 0.1:
	set = set_fret_margins




func _ready():
	refresh()


func refresh():
	
	for c in get_children():
		c.name = "tmp"
		c.queue_free()
	
	if not is_inside_tree():
		return
	
	if not fret_scene:
		push_error("fret scene not set.")
		return
	
	
	if not nut_scene:
		push_error("Nut scene not set.")
		return
	
#	var string_spacing = strings.
	
	var nut = nut_scene.instantiate()
	add_child(nut)
	
	var offset = fret_space/(fret_count)
	for fret_index in range(-1, fret_count - 1):
		var fret_node = fret_scene.instantiate()
		if not (fret_node is Node3D):
			push_error("Invalid fret scene")
			return
		
		fret_node.position.x = offset*fret_index + offset
		add_child(fret_node)


func set_fret_space(value: float) -> void:
	if fret_space != value:
		assert(value >= 0)
		fret_space = value
		changed.emit()
		refresh()


func set_fret_count(value: float) -> void:
	if fret_count != value:
		fret_count = value
		changed.emit()
		refresh()


func set_fret_margins(value: float) -> void:
	if fret_margins != value:
		fret_margins = value
		changed.emit()
		refresh()


func get_note_local_x(fret_index: float) -> float:
	var offset := fret_space/float(fret_count)
	return offset*fret_index + offset*0.5


func get_note_global_x(fret_index: int) -> float:
	return global_position.x + get_note_local_x(fret_index - 1)


func get_fret_x_spacing() -> float:
	return fret_space/(fret_count)
