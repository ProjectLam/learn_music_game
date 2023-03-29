@tool
extends Node3D

@onready var mesh = %mesh

@export var base_size:= 0.7

@export var size:= 0.7:
	set = set_size


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	var scalef := size / base_size
	scale = Vector3(scalef, scalef, scalef)


func set_size(value: float) -> void:
	if size != value:
		size = value
		refresh()
