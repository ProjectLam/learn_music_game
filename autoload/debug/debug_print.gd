extends Label


func _on_timer_timeout():
	var tween = get_tree().create_tween()
	tween.finished.connect(_on_tween_finished)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1).from_current()


func _on_tween_finished():
	queue_free()
