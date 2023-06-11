extends PanelContainer

signal song_changed
signal pressed

@onready var button_bg = %ButtonBg
@onready var select_a_song = %SelectASong
@onready var song_preview_panel = %SongPreviewPanel
@onready var song_name_label = %SongNameLabel

@export var parent_scene: String

var song: Song:
	set = set_song


func _ready():
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	if not song:
		song_preview_panel.visible = false
		select_a_song.visible = true
	else:
		song_preview_panel.visible = true
		select_a_song.visible = false
		
		song_name_label.text = song.get_identifier()


func refresh_song_preview():
	if not is_inside_tree():
		return
	
	if not song:
		return
	
	song_name_label.text = song.get_identifier()


func set_song(value: Song) -> void:
	if song != value:
		song = value
		refresh()
		song_changed.emit()


func _on_button_bg_pressed():
	pressed.emit()
