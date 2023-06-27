extends Node

var stack: Array[String] = []

const fallback = "res://scenes/instrument_selection/instrument_selection.tscn"

var stack_data := {}

const MATCH_CREATION_MODE := "match_creation_mode"

func go_back():
	if stack.size() == 0:
		push_warning("no where to go back to. using fallback scene")
		get_tree().change_scene_to_file(fallback)
		return
	else:
		var prev_scene: String = stack.pop_back()
		get_tree().change_scene_to_file(prev_scene)


func clear():
	stack.clear()
