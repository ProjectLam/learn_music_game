extends Node


func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_pos := get_viewport().get_mouse_position()
	var size := Vector2(get_viewport().size)
#	var light_pos := mouse_pos / size
	RenderingServer.global_shader_parameter_set("mouse_position", mouse_pos)
	RenderingServer.global_shader_parameter_set("viewport_size", get_viewport().size)
	var lighting_point = mouse_pos/size
	RenderingServer.global_shader_parameter_set("lighting_point", lighting_point)
	
