@tool
extends GPUParticles3D

@export var color: Color = Color.WHITE:
	set = set_color

@export var mesh_size: Vector2 = Vector2(5.0, 1.0):
	set = set_mesh_size


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	material_override["albedo_color"] = color
	draw_pass_1["size"] = mesh_size


func set_color(value: Color) -> void:
	if color != value:
		color = value
		refresh()


func set_mesh_size(value: Vector2) -> void:
	if mesh_size != value:
		mesh_size = value
		refresh()
