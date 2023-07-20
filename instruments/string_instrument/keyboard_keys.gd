extends Node3D

func refresh():
	for child in get_children():
		child.refresh()
