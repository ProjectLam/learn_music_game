extends Button
@onready var testSongsPath = "res://TestSongs/"
@onready var buttonIndex:int
@onready var songArray:Array
@onready var aSPlayer:AudioStreamPlayer
@onready var currentStream = AudioStream
@onready var album = $HBoxContainer/VBoxContainer/HBoxContainer/AlbumLabel
@onready var albumName:String
@onready var artist = $HBoxContainer/VBoxContainer/HBoxContainer2/ArtistLabel
@onready var artistName:String
@onready var group = $HBoxContainer/VBoxContainer/HBoxContainer3/GroupLabel
@onready var groupName:String
func _on_custom_base_song_button_button_down():
	SetValues()
	aSPlayer.playing = true
	aSPlayer.volume_db = -16
func SetValues():
	for i in songArray.size():
		if i == buttonIndex:
			currentStream = load(testSongsPath+songArray[buttonIndex])
			aSPlayer.stream = currentStream
func _on_custom_base_song_button_mouse_entered():
	custom_minimum_size = Vector2(custom_minimum_size.x,120.0)
func _on_custom_base_song_button_mouse_exited():
	custom_minimum_size = Vector2(custom_minimum_size.x,100.0)
func _on_line_edit_2_text_submitted(new_text):
	album.text = new_text
	albumName = album.text
func _on_line_edit_3_text_submitted(new_text):
	artist.text = new_text
	artistName = artist.text
func _on_line_edit_4_text_submitted(new_text):
	group.text = new_text
	groupName = group.text
