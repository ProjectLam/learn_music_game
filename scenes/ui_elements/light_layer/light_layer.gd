extends Panel


func _ready():
	pass


func _process(delta):
	var mouse_pos := get_local_mouse_position()
	var light_pos = mouse_pos / size
	material.set_shader_parameter("lighting_point", light_pos)
