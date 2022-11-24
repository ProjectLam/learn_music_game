extends Control
class_name SongSelectionItem

signal selected

func _ready():
	pass

func _process(delta):
	pass

func _on_Box_gui_input(event):
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if event.pressed and not event.is_echo():
			emit_signal("selected", self)
