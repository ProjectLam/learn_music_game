extends VBoxContainer

const SCORE_VIEWER := preload("res://scenes/performance/ingame_user_score_viewer.tscn")


func reload_users(ingame_users: Dictionary) -> void:
	for child in get_children():
		child.name = "__tmp"
		child.queue_free()
	load_users(ingame_users)


func load_users(ingame_users: Dictionary) -> void:
	for key in ingame_users:
		var child = get_node_or_null(key)
		if not child:
			child = SCORE_VIEWER.instantiate()
			child.name = key
			add_child_sorted(child)
			
		child.stats = ingame_users[key]


func add_child_sorted(node: Node) -> void:
	var names: PackedStringArray
	var children := get_children()
	names.resize(children.size())
	for index in children.size():
		names[index] = String(children[index].name)
	var final_index: int = names.bsearch(node.name)
	add_child(node)
	move_child(node, final_index)
	
