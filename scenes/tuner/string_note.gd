extends Control

@onready var label = %Label

var index := 0:
	set = set_index


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	label.text = str(index)

func set_index(value: int) -> void:
	if index != value:
		index = value
		refresh()
