extends Control


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	if MatchManager.status != MatchManager.MatchMakingStatus.CONNECTING \
		and MatchManager.status != MatchManager.MatchMakingStatus.JOINED_MATCH:
		push_error("Not Implemented yet")
	prev_match_manager_status = MatchManager.MatchMakingStatus.CONNECTING
	
	refresh()


func _process(delta):
	if Input.is_action_just_pressed("ui_up"):
		refresh()


func request_finish(request_code: int) -> bool:
	# TODO : add confirmation dialogs.
	# TODO : set previous scene when going to the settings page.
	return true


var prev_match_manager_status := -1
func refresh():
	if not is_inside_tree():
		return
	
	
	# temporary implementation for 1 on 1 match.
	var peers := multiplayer.get_peers()
	# our own peer won't be included.
	if peers.size() > 0:
		_switch_to_game_start()
		return
	
	if prev_match_manager_status != MatchManager.status:
		match(MatchManager.status):
			MatchManager.MatchMakingStatus.CONNECTING, MatchManager.MatchMakingStatus.JOINED_MATCH:
				pass
			_:
				push_error("State %s not implemented" % str(MatchManager.status))
				await GBackend.leave_match_async()
	
	prev_match_manager_status = MatchManager.status


func _switch_to_game_start():
	print("Switching to game start")
	get_tree().change_scene_to_file("res://scenes/performance.tscn")

func _on_peer_connected(peer_id : int):
	# Note : multiplayer api calls should not be called during 'received_match_presence'. But they 
	# can be called during 'peer_connected'.
	refresh()
	
#	if multiplayer.get_unique_id() == get_multiplayer_authority():
#
#		get_tree().change_scene_to_file("res://scenes/performance.tscn")
