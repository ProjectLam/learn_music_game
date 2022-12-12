extends Control
class_name SongSelectionItem

signal selected

var song: TSong: set = set_song

func _ready():
	pass

func _process(delta):
	pass

func set_song(p_song: TSong):
	song = p_song

func _on_SelectBtn_pressed() -> void:
	emit_signal("selected", self)
