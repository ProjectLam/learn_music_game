extends Resource

class_name IngameUser

var score: float = 0


func _on_good_note(note_index: int, timing_error: float) -> void:
	# TODO : add score calculations here.
	score += 1.0
	changed.emit()


func get_data() -> Dictionary:
	return {
		"score": score,
	}


func parse_data(data: Dictionary) -> void:
	var has_changed := false
	if data.has("score"):
		var data_score = data.get("score")
		if (data_score is float or data_score is int) and score != data_score:
			has_changed = true
			score = data_score
	if has_changed:
		changed.emit()
