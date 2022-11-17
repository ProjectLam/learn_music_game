extends Label


func set_text(new_text: String):
	text = new_text
	$ClearTimer.start()


func _on_clear_timer_timeout():
	text = ""
