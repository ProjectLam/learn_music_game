extends VBoxContainer

const SCORE_VIEWER := preload("res://scenes/performance/ingame_user_score_viewer.tscn")


func reload_users(ingame_users: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.free()
		
	load_users(ingame_users)


func load_users(ingame_users: Dictionary) -> void:
	for key in ingame_users:
		var child = get_node_or_null(key)
		if not child:
			child = SCORE_VIEWER.instantiate()
			child.name = key
			child.iuser = ingame_users[key]
			add_child_sorted(child)
		else:
			child.iuser = ingame_users[key]


func add_child_sorted(node: Node) -> void:
	var names: PackedStringArray
	var final_index := 0
	
	if node.iuser.user:
		var peer_id: int = node.iuser.user.peer_id
		if peer_id == get_multiplayer_authority():
			final_index = 0
		elif peer_id == multiplayer.get_unique_id():
			if is_multiplayer_authority():
				final_index = 0
			elif get_child_count() == 0 or get_child(0).iuser.user.peer_id != get_multiplayer_authority():
				final_index = 0
			else:
				final_index = 1
		else:
			if get_child_count() == 0:
				final_index = 0
			else:
				var children := get_children()
				names.resize(children.size())
				for index in children.size():
					names[index] = String(children[index].name)
				final_index = max(names.bsearch(node.name), min(2, get_child_count()))
	
	# TODO : add color coding to ingame_user_score_viewer.tscn
	add_child(node)
	move_child(node, final_index)
	
