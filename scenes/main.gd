extends Node2D


func _on_song_select_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/SongSelect.tscn")


func _on_qr_code_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/QRCode.tscn")


func _on_options_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/options.tscn")


func _on_exit_btn_pressed():
	get_tree().quit(0)
