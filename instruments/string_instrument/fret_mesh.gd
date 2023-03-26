@tool
extends Node3D

@onready var mesh = %mesh

@export var string_spacing: float = 1.0:
	set = set_string_spacing


@export var color: Color:
	set = set_color


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
#	mesh.mesh["size"].y = string_spacing
	mesh.material_override["albedo_color"] = color
#	mesh.position.y = string_spacing * 0.5

func set_string_spacing(value: float) -> void:
	if string_spacing != value:
		string_spacing = value
		refresh()


func set_color(value: Color) -> void:
	if color != value:
		color = value
		refresh()
