extends VScrollBar

signal scroll_started
signal scroll_ended

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				emit_signal("scroll_started")
			else:
				emit_signal("scroll_ended")
