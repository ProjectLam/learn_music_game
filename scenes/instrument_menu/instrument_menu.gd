extends Control

func _ready():
	pass

func _on_Learn_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")

func _on_Play_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")

func _on_Matches_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/matchmaking/matchmaking.tscn")

func _on_Settings_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")

func _on_Tuning_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/tuner.tscn")

func _on_Quit_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")

func _on_BackBtn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")
