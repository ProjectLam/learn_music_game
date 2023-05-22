@tool
extends PanelContainer

@onready var user_status = %user_status
@onready var even_panel = %EvenPanel
@onready var odd_panel = %OddPanel


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	if get_index() % 2 == 0:
		even_panel.visible = true
		odd_panel.visible = false
	else:
		even_panel.visible = false
		odd_panel.visible = true
