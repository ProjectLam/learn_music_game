extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func go_back():
	var current_scene := get_tree().current_scene
	if self == current_scene:
		get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")
	else:
		hide()


func request_go_back():
	go_back()


func _on_quit_button_pressed():
	request_go_back()
