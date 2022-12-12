extends Control
class_name Courses

@export var item_stylebox_normal: StyleBox
@export var item_stylebox_completed: StyleBox

@onready var nItems: GridContainer = find_child("Items")

func _ready():
	get_item(0).is_completed = true

func _process(delta):
	pass

func get_item(p_index: int) -> CoursesItem:
	return nItems.get_child(p_index)
