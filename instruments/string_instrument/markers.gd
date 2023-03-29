@tool
extends Node3D


@onready var frets = %Frets
@onready var strings = %Strings

@export var marker_scene: PackedScene

@export var marker_positions: Array[Vector2i] = []:
	set = set_marker_positions

@export var marker_z_offset: float = 0.0:
	set = set_marker_z_offset


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	
	if not marker_scene:
		push_error("Marker scene not set.")
		return
		
	for c in get_children():
		c.name = "tmp"
		c.queue_free()
	
	var string_space: float = strings.string_space
	var bottom_margin: float = strings.bottom_margin
	for mpos in marker_positions:
		if not mpos.y >= 0:
			continue
		var fret_index := mpos.x
		var xpos: float = frets.get_note_global_x(fret_index) - global_position.x
		var mpos_arr: PackedVector3Array = []
		match(mpos.y):
			1:
				var ypos = bottom_margin + string_space*0.5
				mpos_arr.append(Vector3(
						xpos,
						ypos,
						marker_z_offset
				))
			2:
				var ypos = bottom_margin + string_space*0.25
#				ypos = bottom_margin
				mpos_arr.append(Vector3(
						xpos,
						ypos,
						marker_z_offset
				))
				ypos = bottom_margin + string_space*0.75
#				ypos = bottom_margin
				mpos_arr.append(Vector3(
						xpos,
						ypos,
						marker_z_offset
				))
			_:
				push_error("unimplemented marker count :", mpos.y)
				continue
		for marker_position in mpos_arr:
			var marker_node = marker_scene.instantiate()
			marker_node.position = marker_position
			add_child(marker_node)

func set_marker_positions(value) -> void:
	marker_positions = value
	refresh()


func set_marker_z_offset(value) -> void:
	if marker_z_offset != value:
		marker_z_offset = value
		refresh()
