extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	


func _on_song_select_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/SongSelect.tscn")


func _on_qr_code_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/QRCode.tscn")


func _on_options_btn_pressed():
	pass # Replace with function body.


func _on_exit_btn_pressed():
	pass # Replace with function body.
