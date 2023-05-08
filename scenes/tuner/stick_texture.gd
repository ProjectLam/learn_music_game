@tool
extends TextureRect

@export_node_path("Control") var containter
@onready var containter_node := get_node_or_null(containter)
@export_range(0.0,1.0) var size_ratio := 0.5
@export_range(0.05,0.2) var width_ratio := 0.1


func _ready():
	call_deferred("refresh")
#	refresh()
	if not Engine.is_editor_hint():
		set_process(false)


func _process(delta):
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	if not is_instance_valid(containter_node):
		return
	size.y = containter_node.size.y*size_ratio
	position.y = -size.y
	size.x = size.y*width_ratio
	position.x = -size.x*0.5
