extends VBoxContainer

const USER_STATUS_SCENE := preload("res://scenes/user_status/glass_panel_user_status.tscn")

var self_status_node: Control

var user_status_nodes := {}


func _ready():
	reload()
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func reload():
	for c in get_children():
		remove_child(c)
		c.free()
	
	self_status_node = USER_STATUS_SCENE.instantiate()
	var self_user = MatchManager.users.dict[multiplayer.get_unique_id()]
	self_status_node.user = self_user
	add_child(self_status_node)
	user_status_nodes[multiplayer.get_unique_id()] = self_status_node
	for peer_id in multiplayer.get_peers():
		add_new_peer(peer_id)


func add_new_peer(peer_id: int):
	# TODO : find a better way to order the nodes.
	
	var new_user_status := USER_STATUS_SCENE.instantiate()
	var nuser: User = MatchManager.users.dict.get(peer_id)
	new_user_status.user = nuser
	var authority := get_multiplayer_authority()
	if not is_multiplayer_authority() and peer_id == authority:
		self_status_node.add_sibling(new_user_status)
		call_deferred("_refresh_children")
	else:
		add_child(new_user_status)
	
	user_status_nodes[peer_id] = new_user_status


func _on_peer_connected(peer_id: int) -> void:
	add_new_peer(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	# do nothing for now.
	pass


func _refresh_children():
	for c in get_children():
		if c.has_method("refresh"):
			c.refresh()
