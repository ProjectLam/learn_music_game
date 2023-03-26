@tool
extends Node3D

@onready var string_mesh = %string_mesh

@export var color: Color:
	set = set_color


@export var fret_space: float = 6.0:
	set = set_fret_space


@export var fret_margin: float = 0.3:
	set = set_fret_margin


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	string_mesh.material_override["albedo_color"] = color
	string_mesh.mesh["height"] = fret_space + 2.0 * fret_margin
	string_mesh.transform.origin.x = fret_space*0.5

func set_color(value: Color) -> void:
	if color != value:
		color = value
		refresh()


func set_fret_space(value: float) -> void:
	if fret_space != value:
		fret_space = value
		refresh()


func set_fret_margin(value: float) -> void:
	if fret_margin != value:
		fret_margin = value
		refresh()
