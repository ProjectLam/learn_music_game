extends Control
class_name SongSelectionItem

signal selected

var song: Song: set = set_song
var radius: float = 1000.0


func _ready():
	pass


func _process(delta):
	var y: float = abs(get_parent().size.y*0.5 - (position.y + get_parent().position.y + size.y*0.5))
	position.x = radius - sqrt(abs(radius*radius - y*y))


func set_song(p_song: Song):
	song = p_song

func _on_SelectBtn_pressed() -> void:
	emit_signal("selected", self)
