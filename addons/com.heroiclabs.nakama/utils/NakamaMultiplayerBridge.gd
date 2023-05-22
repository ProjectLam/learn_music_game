extends Node
class_name NakamaMultiplayerBridge

const version_index := 1
const retry_count := 0
const ping_interval := 3.0
var _ping_timer := 0.0
var valid := false

enum MatchState {
	SOCKET_CLOSED,
	DISCONNECTED,
	LEAVING_MATCH,
	FINDING_MATCH,
	JOINING,
	CONNECTED,
}

enum MetaMessageType {
	# used for setting the (peer,session_id) pairs.
	SET_PEER_MAP = 1001,
	MATCH_LABEL_UPDATE = 1002
}

signal match_join_error(exception)
signal match_joined()
signal needs_reconnect()
signal game_status_changed()

# Read-only variables.
var _nakama_socket: NakamaSocket
var nakama_socket: NakamaSocket:
	get: return _nakama_socket
	set(_v): pass
var _match_state: int = MatchState.DISCONNECTED:
	set = _set_match_state
var match_state: int:
	get: return _match_state
	set(_v): pass
var _match_id := ''
var match_id: String:
	get: return _match_id
	set(_v): pass
var match_label := {}
var _multiplayer_peer: NakamaMultiplayerPeer = NakamaMultiplayerPeer.new()
var multiplayer_peer: NakamaMultiplayerPeer:
	get: return _multiplayer_peer
	set(_v): pass

# Configuration that can be set by the developer.
const OPCPDE_META: int = 9001
const OPCODE_RPC_GODOT: int = 9002
const OPCODE_MATCH_HANDLER_RPC: int = 9003


# Internal variables.
var _my_session_id: String
var _my_peer_id: int = 0
var _id_map := {}
var _users := {}
var _matchmaker_ticket := ''

class User extends RefCounted:
	var presence
	var peer_id: int = 0
	var ready := false

	func _init(p_presence) -> void:
		presence = p_presence


var bridge_initializing := true
func _init(p_nakama_socket: NakamaSocket) -> void:
	_nakama_socket = p_nakama_socket
	_nakama_socket.received_match_presence.connect(self._on_nakama_socket_received_match_presence)
	# Matchmaker probably needs a redo. For now we just do direct joins.
#	_nakama_socket.received_matchmaker_matched.connect(self._on_nakama_socket_received_matchmaker_matched)
	_nakama_socket.received_match_state.connect(self._on_nakama_socket_received_match_state)
	_nakama_socket.closed.connect(self._on_nakama_socket_closed)

	_multiplayer_peer.packet_generated.connect(self._on_multiplayer_peer_packet_generated)
	_cleanup()
	
	await try_validate_async()
	if valid:
		bridge_initializing = false


func _process(delta):
	_ping_timer += delta
	if _ping_timer > ping_interval:
		_ping_timer = 0.0


func try_validate_async() -> void:
	var payload = await get_version()
	
	if payload == null:
		push_error("Could not get version. Retry again.")
		valid = false
		return
	
	var index = payload.get("index")
	if index == null:
		push_error("Invalid Server Version Detected")
		valid = false
		return

	if int(index) > version_index:
		push_error("Server version index [%d] does not match with current version index [%d]" % [index, version_index])
		valid = false
		return
	
	print("Server version detected :", payload)
	valid = true


func get_version():
	for i in retry_count+1:
		var payload = await _nakama_socket.rpc_async_parsed("get_version", {})
		if payload and not (not (payload is Dictionary) and not payload.is_exception()):
			return payload
	
	needs_reconnect.emit()
	return null


func parse_match_label(label_string: String) -> int:
	var parsed_label = JSON.parse_string(label_string)
	if parsed_label is Dictionary:
		match_label = parsed_label
		return OK
	return -1


func create_match_async(match_name: String, meta_data: Dictionary) -> NakamaRTAPI.Match:
	if _match_state > MatchState.JOINING:
		push_warning("Trying to create match before leaving the current one.")
		await leave_match_async()
	while(_match_state == MatchState.LEAVING_MATCH):
		await get_tree().process_frame
	if _match_state == MatchState.SOCKET_CLOSED:
		push_error("Connot create match while socket is closed")
		return null
	
	_match_state = MatchState.JOINING
	meta_data["name"] = match_name
#	multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_CONNECTING)
	var payload = await _nakama_socket.rpc_async_parsed("create_match", meta_data)
	
	if not (payload is Dictionary):
		_cleanup()
		if payload is NakamaException:
			match_join_error.emit(payload)
		elif payload is NakamaAsyncResult:
			match_join_error.emit(payload.get_exception())
		return null
		
	var match_id = payload.get("match_id")
	if not (match_id is String):
		_cleanup()
		match_join_error.emit(NakamaException.new("Invalid match_id", -1, -1))
		return null
	
	var join_res = await _nakama_socket.join_match_async(match_id)
	if not (join_res is NakamaRTAPI.Match) or join_res.is_exception():
		_cleanup()
		match_join_error.emit(join_res.get_exception())
		return
	
	_match_id = join_res.match_id
	_my_session_id = join_res.self_user.session_id
	if parse_match_label(join_res.label) != OK:
		push_error("invalid match label")
		match_label.clear()
		# TODO : add more error handling
	for presence in join_res.presences:
		print("adding Initial presence :", presence)
		if presence.session_id == _my_session_id:
			continue
		_on_presence_join(presence)
	# _match_state is already set to joining.
	# upon receiving session_d for peer_id 1 with 
	# _on_nakama_socked_received_match_state _match_state will be updated.
	
	while(_match_state == MatchState.JOINING):
		await get_tree().process_frame
	if _match_state == MatchState.CONNECTED:
		return join_res
	else:
		return null


func join_match_async(match_id: String):
	if _match_state > MatchState.JOINING:
		push_warning("Trying to join match before leaving the current one.")
		await leave_match_async()
	while(_match_state == MatchState.LEAVING_MATCH):
		await get_tree().process_frame
	if _match_state == MatchState.SOCKET_CLOSED:
		push_error("Connot join match while socket is closed")
		return null
	_match_state = MatchState.JOINING
	
	var join_res = await _nakama_socket.join_match_async(match_id)
	if not (join_res is NakamaRTAPI.Match) or not (join_res.self_user is NakamaRTAPI.UserPresence):
		push_error("joining match failed")
		_cleanup()
		match_join_error.emit(join_res.get_exception())
		return
	_match_id = join_res.match_id
	_my_session_id = join_res.self_user.session_id
	
	for presence in join_res.presences:
		if presence.session_id == _my_session_id:
			continue
		_on_presence_join(presence)
	
	
	if parse_match_label(join_res.label) != OK:
		push_error("invalid match label")
		match_label.clear()
		# TODO : add more error handling
	
	# _match_state is already set to joining.
	# upon receiving session_d for peer_id 1 with 
	# _on_nakama_socked_received_match_state _match_state will be updated.
	
	while(_match_state == MatchState.JOINING):
		await get_tree().process_frame
	if _match_state == MatchState.CONNECTED:
		return join_res
	else:
		return null



func match_rpc_async(data: Dictionary) -> int :
	if match_state == MatchState.CONNECTED:
		var send_data = JSON.stringify(data)
		
		var res = await _nakama_socket.send_match_state_async(_match_id, OPCODE_MATCH_HANDLER_RPC, send_data, [])
		if res.is_exception():
			return -1
		
		return OK
	else:
		push_error("RPC sent while the NakamaMultiplayerBridge isn't connected!")
		return -1


#func start_matchmaking(ticket) -> void:
#	if _match_state != MatchState.DISCONNECTED:
#		push_error("Cannot start matchmaking when state is %s" % MatchState.keys()[_match_state])
#		return
#	if ticket.is_exception():
#		push_error("Ticket with exception passed into start_matchmaking()")
#		return
#
#	_match_state = MatchState.JOINING
#	multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_CONNECTING)
#
#	_matchmaker_ticket = ticket.ticket

#func _on_nakama_socket_received_matchmaker_matched(matchmaker_matched) -> void:
#	if _matchmaker_ticket != matchmaker_matched.ticket:
#		return
#
#	# Get a list of sorted session ids.
#	var session_ids := []
#	for matchmaker_user in matchmaker_matched.users:
#		session_ids.append(matchmaker_user.presence.session_id)
#	session_ids.sort()
#
#	var res = await _nakama_socket.join_matched_async(matchmaker_matched)
#	if res.is_exception():
#		match_join_error.emit(res.get_exception())
#		leave()
#		return
#
#	_setup_match(res)
#
#	# If our session is the first alphabetically, then we'll be the host.
#	if _my_session_id == session_ids[0]:
#		_setup_host()
#
#		# Add all of the existing peers.
#		for presence in res.presences:
#			if presence.session_id != _my_session_id:
#				_host_add_peer(presence)


func _on_nakama_socket_closed() -> void:
	match_state = MatchState.SOCKET_CLOSED
	_cleanup()


func get_user_presence_for_peer(peer_id: int) -> NakamaRTAPI.UserPresence:
	var session_id = _id_map.get(peer_id)
	if session_id == null:
		return null
	var user = _users.get(session_id)
	if user == null:
		return null
	return user.presence


func leave_match_async() -> void:
	if _match_state <= MatchState.LEAVING_MATCH:
		push_warning("Trying to leave match more than once")
	
	_match_state = MatchState.LEAVING_MATCH

	if _match_id:
		await _nakama_socket.leave_match_async(_match_id)
	# matchamker may need a redo.
#	if _matchmaker_ticket:
#		await _nakama_socket.remove_matchmaker_async(_matchmaker_ticket)
	
	# we check for this because it's possible that it's equal to SOCKED_CLOSED.
	if _match_state == MatchState.LEAVING_MATCH:
		_cleanup()


func _cleanup() -> void:
	for peer_id in _id_map:
		multiplayer_peer.peer_disconnected.emit(peer_id)

	_match_id = ''
	_matchmaker_ticket = ''
	_my_session_id = ''
	_my_peer_id = 0
	_id_map.clear()
	_users.clear()

#	_multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_DISCONNECTED)
	if _match_state > MatchState.DISCONNECTED:
		_match_state = MatchState.DISCONNECTED


# nakama precense events are sent as soon as a new precense is detected before
# any custom logic on the server is executed.
func _on_nakama_socket_received_match_presence(event) -> void:
	if _match_state == MatchState.DISCONNECTED:
		return
	if event.match_id != _match_id:
		return
	
	for presence in event.joins:
		print("New precense joined :", presence.session_id)
		_on_presence_join(presence)
#
#		# If we are the host, and they don't yet have a peer id, then let's
#		# generate a new id for them and send all the necessary messages.
#		if _my_peer_id == 1 and _users[presence.session_id].peer_id == 0:
#			_host_add_peer(presence)
	
	for presence in event.leaves:
		if not _users.has(presence.session_id):
			push_warning("A user left. But it's join event was not received.")
			continue
	
		var peer_id = _users[presence.session_id].peer_id
		
		if peer_id:
			_multiplayer_peer.peer_disconnected.emit(peer_id)
			_id_map.erase(peer_id)
		_users.erase(presence.session_id)


func _on_presence_join(presence: NakamaRTAPI.UserPresence):
	if not _users.has(presence.session_id):
		_users[presence.session_id] = User.new(presence)


func _parse_json(data: String):
	var json = JSON.new()
	if json.parse(data) != OK:
		return null
	var content = json.get_data()
	if not content is Dictionary:
		return null
	return content


# handles received nakama messages.
func _on_nakama_socket_received_match_state(data) -> void:
	if _match_state < MatchState.JOINING:
		# match is neither joining or joined.
		return
	if data.match_id != _match_id:
		return
	
	match data.op_code:
		OPCPDE_META:
			_process_meta(data)
		OPCODE_RPC_GODOT:
			_process_godot_rpc(data)
		_:
			push_error("INVALID OPCODE :", data)


func _process_meta(data) -> void:
	var content = _parse_json(data.data)
	if content == null:
		return
	var type = content['type']
#
#		# Ensure that any meta messages are coming from the server!
	if data.presence:
		push_error("Meta op codes only allowed from server")
		return
	match(int(type)):
		MetaMessageType.SET_PEER_MAP:
			_process_meta_set_peer_map(content)
		MetaMessageType.MATCH_LABEL_UPDATE:
			_process_meta_match_label_update(content)
		_:
			_nakama_socket.logger.error("Received meta message with unknown type :%s" % content)


func _process_meta_match_label_update(content):
	var prev_label = match_label.duplicate(true)
	var new_label_string = content.get("match_label")
	if parse_match_label(new_label_string) != OK:
		push_error("Meta update sent invalid match label")
		match_label.clear()
		# TODO : add more error handling
	
	if prev_label.get("game_status") != match_label.get("game_status"):
		game_status_changed.emit()
	


func _process_meta_set_peer_map(content):
	# peer_map is a Dictionary of (session_id : peer_id) pairs
	var peer_map = content.get("peer_map")
	if not (peer_map is Dictionary):
		push_error("invalid value for 'new_peers_map' entry")
		return
	
	# entries for users that have left should 
	# be removed. Not sure if we need to check for that. If the backend 
	# is doing it's job then we shouldn't need to.
	if _match_state == MatchState.CONNECTED:
		for sess_id in peer_map:
			if not _users.has(sess_id):
				# trying to set peer_id for a precense that hasn't been received yet.
				push_error("Setting peer for non existing user :", sess_id)
				return
			var peer_id: int = peer_map[sess_id]
			if _id_map.has(peer_id):
				if _id_map.get(peer_id) != sess_id:
					push_error("Changing peer id is not supported")
					return
			else:
				_id_map[peer_id] = sess_id
				_users[sess_id].peer_id = peer_id
				multiplayer_peer.peer_connected.emit(peer_id)
	elif _match_state == MatchState.JOINING and peer_map.has(_my_session_id):
		# our peer id has been set. we can initialize multiplayer_peer. 
		
		_my_peer_id = peer_map[_my_session_id]
		_users[_my_session_id].peer_id = _my_peer_id
		_id_map[_my_peer_id] = _my_session_id
		# TODO :
		# boradcast that you are now ready
		_multiplayer_peer.initialize(_my_peer_id)
		_match_state = MatchState.CONNECTED
#				_multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_CONNECTED)
		# peer_connected events for the rest of the peers :
		for sess_id in peer_map:
			if sess_id == _my_session_id:
				continue
			var peer_id: int = peer_map[sess_id]
			_users[sess_id].peer_id = peer_id
			_id_map[peer_id] = sess_id
			_multiplayer_peer.peer_connected.emit(peer_id)
		if _id_map.has(1):
			# host has joined.
			_match_state = MatchState.CONNECTED
			match_joined.emit()


func _process_godot_rpc(data) -> void:
	if data.presence == null:
		push_error("Invalid godot rpc. null sender.")
		return
	if data.presence.session_id == _my_session_id:
		# Invalid godot rpc. sender = self. ignoring silently.
		return
	var from_session_id: String = data.presence.session_id
	if not _users.has(from_session_id) or _users[from_session_id].peer_id == 0:
		push_error("Received RPC from %s which isn't assigned a peer id" % data.presence.session_id)
		return
	
	# forward packet for built in processing.
	var from_peer_id = _users[from_session_id].peer_id
	
	_multiplayer_peer.deliver_packet(Marshalls.base64_to_raw(data.data), from_peer_id)


# sends godot rpc buffers around.
func _on_multiplayer_peer_packet_generated(peer_id: int, buffer: PackedByteArray) -> void:
	if match_state == MatchState.CONNECTED:
		var target_presences = null
		var target_presence = null
		if peer_id > 0:
			if not _id_map.has(peer_id):
				push_error("Attempting to send RPC to unknown peer id: %s" % peer_id)
				return
			var presence: NakamaRTAPI.UserPresence = _users[_id_map[peer_id]].presence
			target_presence = presence.session_id
			target_presences = [ presence ]
		# because nakama api dumps target presences for target_precenses we need to bundle them.
		
		var data = JSON.stringify({
			"target_presence": target_presence,
			"data": Marshalls.raw_to_base64(buffer),
		})
		_nakama_socket.send_match_state_async(_match_id, OPCODE_RPC_GODOT, data, target_presences)
	else:
		push_error("RPC sent while the NakamaMultiplayerBridge isn't connected!")


func get_peer_UserPresence(peer_id: int) -> NakamaRTAPI.UserPresence:
	var sess_id = _id_map.get(peer_id)
	if not (sess_id is String):
		push_error("no user presence for peer_id[%d]" % peer_id)
		return null
	var user: User = _users.get(sess_id)
	if not user:
		push_error("no user presence for peer_id[%d]" % peer_id)
		return null
	if user.presence is NakamaRTAPI.UserPresence:
		return user.presence
	else:
		push_error("Invalid user presence for peer_id[%d]" % peer_id)
		return null
	

func get_peer_username(peer_id: int) -> String:
	var presence = get_peer_UserPresence(peer_id)
	if presence:
		return presence.username
	else:
		push_error("no user presence for peer_id[%d]" % peer_id)
		return ""
	


func get_peer_user_id(peer_id: int) -> String:
	var presence = get_peer_UserPresence(peer_id)
	if presence:
		return presence.user_id
	else:
		push_error("no user presence for peer_id[%d]" % peer_id)
		return ""


func _set_match_state(value: MatchState) -> void:
	if _match_state != value:
		_match_state = value
		match(_match_state):
			MatchState.JOINING:
				if _multiplayer_peer._get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING:
					_multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_CONNECTING)
			MatchState.CONNECTED:
				if _multiplayer_peer._get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
					_multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_CONNECTED)
			_:
				if _multiplayer_peer._get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
					_multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_DISCONNECTED)
