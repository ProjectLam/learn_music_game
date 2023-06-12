extends Control

@onready var instrument_title = %InstrumentTitle
@onready var instrument_box = %InstrumentBox
@onready var songs_number = %SongsNumber
@onready var courses_number = %CoursesNumber

@onready var actions = %Actions

@onready var focus_candidate := actions.get_child(0)

func _ready():
	
	var instrument_data := PlayerVariables.gameplay_instrument_data
	instrument_box.instrument_data = instrument_data
	instrument_box.info_visible = false
	instrument_title.text = instrument_data.instrument_label
	if not SongsConfigPreloader.is_song_preload_completed:
		await SongsConfigPreloader.song_preload_completed
	songs_number.text = str(InstrumentDetails.get_songs_number(instrument_data))
	courses_number.text = str(InstrumentDetails.get_courses_number(instrument_data))

	if FocusManager.is_in_focus_tree():
		grab_focus()
#
#
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		request_go_back()

func _gui_input(event):
	if event.is_action_pressed("ui_down"):
		accept_event()
		var first_button = actions.get_child(0)
		first_button.button_overlay.grab_focus()


func request_go_back():
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")


func _on_Learn_selected() -> void:
	_on_Play_selected()


func _on_Play_selected() -> void:
	SceneStack.stack_data[SceneStack.MATCH_CREATION_MODE] = MatchCreation.Modes.SINGLE_PLAYER
	get_tree().change_scene_to_file("res://scenes/matchmaking/match_creation.tscn")
#	get_tree().change_scene_to_file("res://scenes/song_selection/song_selection.tscn")


func _on_Matches_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/matchmaking/matchmaking.tscn")


func _on_Settings_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/settings/settings.tscn")


func _on_Tuning_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/tuner.tscn")


func _on_Quit_selected() -> void:
	get_tree().quit()
#	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")


func _on_instrument_box_pressed():
	request_go_back()
