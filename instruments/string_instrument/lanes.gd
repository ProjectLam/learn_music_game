@tool
extends Node3D

@onready var frets = %Frets

@export_range(10.0,100.0) var lane_length := 48.0:
	set = set_lane_length


@export var lane_scene: PackedScene

func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	if not lane_scene:
		push_error("Lane scene not set.")
		return
	
	for c in get_children():
		c.name = "tmp"
		c.queue_free()
	
	var fret_spacing = frets.get_fret_x_spacing()
	for fret_index in frets.fret_count:
		var lane_node = lane_scene.instantiate()
		var xloc = -global_position.x + frets.get_note_global_x(fret_index + 1)
		lane_node.position.x = xloc
		lane_node.set("fret_spacing", fret_spacing)
		lane_node.set("text", str(fret_index + 1))
		add_child(lane_node)

func set_lane_length(value: float) -> void:
	if lane_length != value:
		lane_length = value
		refresh()
