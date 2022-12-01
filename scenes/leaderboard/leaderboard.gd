extends Control

@export var style_odd: StyleBox
@export var style_even: StyleBox

@onready var nItems = find_child("Items")

func _ready():
	_update_style()

func _process(delta):
	pass

func _update_style() -> void:
	for i in nItems.get_child_count():
		var nItem: PanelContainer = nItems.get_child(i)
		if i % 2 == 0:
			nItem.add_theme_stylebox_override("panel", style_odd)
		else:
			nItem.add_theme_stylebox_override("panel", style_even)
