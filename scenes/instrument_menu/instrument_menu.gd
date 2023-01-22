extends Control

@onready var instrument_title = %InstrumentTitle
@onready var instrument_box = %InstrumentBox
@onready var songs_number = %SongsNumber
@onready var courses_number = %CoursesNumber


func _ready():
	var instrument_data := PlayerVariables.gameplay_instrument_data
	instrument_box.instrument_data = instrument_data
	instrument_box.info_visible = false
	songs_number.text = str(InstrumentDetails.get_songs_number(instrument_data))
	courses_number.text = str(InstrumentDetails.get_courses_number(instrument_data))
	instrument_title.text = instrument_data.instrument_label

func _on_Learn_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")

func _on_Play_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")

func _on_Matches_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/matchmaking/matchmaking.tscn")

func _on_Settings_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")

func _on_Tuning_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/tuner/tuner.tscn")

func _on_Quit_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")

func _on_BackBtn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")
