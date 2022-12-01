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

func _on_Box_gui_input(event):
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not event.is_echo():
			emit_signal("selected", self)
