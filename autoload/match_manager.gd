extends Node

enum MatchMakingStatus {
	OFFLINE,
	CONNECTING,
	IDLE,
	LEAVING_MATCH,
	RECONNECTING,
	FINDING_MATCH,
	CREATING_MATCH,
	JOINING_MATCH,
	JOINED_MATCH, # after you create a match you join it.
}

enum GameStatus {
	UNDEFINED,
	DEFAULT,
	STARTED
}

const GameStatusStrings := {
	"default": GameStatus.DEFAULT,
	"started": GameStatus.STARTED,
}

signal status_changed
# note : game_status_changed is emited AFTER status_changed
signal game_status_changed

var match_counter := 0
var status := MatchMakingStatus.OFFLINE:
	set = set_status

var game_status := GameStatus.UNDEFINED:
	set = set_game_status

# Used to make sure only one request gets processed at any time.
# Used with requests that affect stats and game_status
# Also helps with not having to wait for leave_match_async.
var processing_request := false

# peer_id : User map
var users: RefDict

func _ready():
	GBackend.connection_status_changed.connect(_on_connection_status_changed)
	GBackend.game_status_changed.connect(_on_game_status_changed)
#	GBackend


func set_status(value: MatchMakingStatus) -> void:
	if status != value:
		var prev_status = status
		status = value
		
		status_changed.emit()
		
		match(status):
			MatchMakingStatus.JOINED_MATCH:
				process_match_label()
			MatchMakingStatus.RECONNECTING:
				push_error("Switching to Reconnecting not implemented yet")
			_:
				if game_status != GameStatus.UNDEFINED:
					game_status = GameStatus.UNDEFINED
					game_status_changed.emit()


func set_game_status(value: GameStatus) -> void:
	if game_status != value:
		game_status = value
		
#		if game_status == GameStatus.UNDEFINED:
#			users.dict.clear()


func create_match_async(song: Song) -> int:
	while processing_request:
		await get_tree().process_frame
	processing_request = true
	
	if status < MatchMakingStatus.IDLE:
		processing_request = false
		return -1
	
	
	if status != MatchMakingStatus.IDLE:
#		status = MatchMakingStatus.LEAVING_MATCH
		await GBackend.leave_match_async()
		if GBackend.connection_status != GBackend.CONNECTION_STATUS.CONNECTED:
			status = MatchMakingStatus.CONNECTING if GBackend.connection_status == GBackend.CONNECTION_STATUS.CONNECTING \
				else MatchMakingStatus.OFFLINE
			print("Match creation failed")
			processing_request = false
			return -1
	status = MatchMakingStatus.CREATING_MATCH
	processing_request = false
	
	
	
	var match_params := {
		# currently match is one on one so PlayerVariables is sued.
		# later SessionVariables.instrument needs to be set sooner.
		# and there should be a lobby room for host to start game by choice.
		"instrument": PlayerVariables.gameplay_instrument_name,
		"song": song.get_identifier(),
	}
	var err = await GBackend.create_match_async("unnamed_match", match_params)
	var init_err := await _init_match(err)
	if init_err != OK:
		return init_err
	
	print("Match creation succeeded")
	return OK


func get_label() -> Dictionary:
	return GBackend.multiplayer_bridge.match_label


func _init_match(join_err: int) -> int:
	if GBackend.connection_status != GBackend.CONNECTION_STATUS.CONNECTED:
		status = MatchMakingStatus.CONNECTING if GBackend.connection_status == GBackend.CONNECTION_STATUS.CONNECTING \
			else MatchMakingStatus.OFFLINE
		return -1
	
	if join_err != OK:
		status = MatchMakingStatus.IDLE
		return join_err
	
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		push_warning("Something went wrong. waiting for multiplayer to initialize.")
		await multiplayer.connected_to_server
	
	
	users = GBackend.multiplayer_bridge._users_pid
	
	
	var isntrument_name = get_label().get("instrument")
	if not (isntrument_name in InstrumentList.instruments):
		push_error("Instrument not found")
		status = MatchMakingStatus.LEAVING_MATCH
		await GBackend.leave_match_async()
		status = MatchMakingStatus.IDLE
		return -1
	
	var songid = GBackend.multiplayer_bridge.match_label.get("song")
	if not (songid in PlayerVariables.songs):
		# TDDO : later on song downloading will happen here.
		push_error("Invalid song name")
		status = MatchMakingStatus.LEAVING_MATCH
		await GBackend.leave_match_async()
		status = MatchMakingStatus.IDLE
		return -1
	
	
	SessionVariables.current_song = PlayerVariables.songs[songid]
	SessionVariables.instrument = PlayerVariables.gameplay_instrument_name
	
	SessionVariables.single_player = false
	
	status = MatchMakingStatus.JOINED_MATCH
	
	return OK


# returns OK on success
func join_match_async(match_id: String) -> int:
	while processing_request:
		await get_tree().process_frame
	processing_request = true
	
	match status:
		MatchMakingStatus.IDLE:
			status = MatchMakingStatus.JOINING_MATCH
			var ret := await GBackend.join_match_async(match_id)
			var init_err := await _init_match(ret)
			processing_request = false
			return init_err
		_:
			push_error("Status [%s] not implemented while joining match" % status)
			processing_request = false
			return -1
	
	processing_request = false
	return -1


# returns OK on success
func leave_match_async() -> int:
	while processing_request:
		await get_tree().process_frame
	processing_request = true
	
	# TODO : don't confuse connecting with reconnecting while inside a match.
	match status:
		MatchMakingStatus.OFFLINE, MatchMakingStatus.IDLE:
			processing_request = false
			return OK
		_:
			await GBackend.leave_match_async()
			status = MatchMakingStatus.IDLE if GBackend.connection_status == GBackend.CONNECTION_STATUS.CONNECTED else MatchMakingStatus.OFFLINE
			processing_request = false
			return OK
	
	processing_request = false
	return -1


func _on_connection_status_changed():
	match GBackend.connection_status:
		GBackend.CONNECTION_STATUS.CONNECTED:
			match status:
				MatchMakingStatus.OFFLINE, MatchMakingStatus.CONNECTING:
					status = MatchMakingStatus.IDLE
				_:
					push_error("Switch from ", status, ",",  MatchMakingStatus.OFFLINE, " to connected not implemented.")
		GBackend.CONNECTION_STATUS.DISCONNECTED:
			match status:
				MatchMakingStatus.IDLE, MatchMakingStatus.CONNECTING:
					status = MatchMakingStatus.OFFLINE
				_:
					push_error("Switch from ", status, " to disconnected not implemented.")
		GBackend.CONNECTION_STATUS.CONNECTING:
			match status:
				MatchMakingStatus.OFFLINE:
					status = MatchMakingStatus.CONNECTING
				_:
					push_error("Switch from ", status, " to connecting not implemented.")
		_:
			push_error("invalid Backend connection status.")


func _on_game_status_changed():
	process_match_label()


func process_match_label():
	var new_game_status = GameStatusStrings[get_label().get("game_status")]
	# we use boolean values because signal emission needs to be done after all values have been updated.
	var _game_status_changed := false
	if game_status != new_game_status:
		game_status = new_game_status
		_game_status_changed = true
	
	# Signal emissions.
	if _game_status_changed:
		game_status_changed.emit()


# returns OK if it succeeds
func order_ready_async() -> int:
	while processing_request:
		await get_tree().process_frame
		
	processing_request = true
	# for now we just let the host start the game in the backend.
	if game_status != GameStatus.DEFAULT:
		push_error("Invalid game transition.")
		processing_request = false
		return -1
	
	var err = await GBackend.multiplayer_bridge.match_rpc_async({"game_status": "started"})
	processing_request = false
	return err

# give a list of current matches. can exclude matches that you can't join.
func list_matches_async(only_allowed := true):
	pass


func get_peer_username(peer_id: int) -> String:
	# TODO : add checks.
	var user = users.dict.get(peer_id)
	if not user:
		push_error("invalid peer id")
		return ""
	return user.username


func get_peer_user_id(peer_id: int) -> String:
	# TODO : add checks
	var user = users.dict.get(peer_id)
	if not user:
		push_error("invalid peer id")
		return ""
	return users.user_id


func _on_peer_connected(peer_id: int) -> void:
	var presence := GBackend.multiplayer_bridge.get_peer_user(peer_id)
	if presence:
		users[presence.user_id] = Users.get_from(presence)


func is_user_host(user: User):
	if not user:
		return false
	
	if user.peer_id == get_multiplayer_authority():
		return true
	
	return false


func is_user_self(user: User):
	if not user:
		return false
	
	if status != MatchMakingStatus.RECONNECTING and status != MatchMakingStatus.JOINED_MATCH:
		return false
	
	return user.peer_id == multiplayer.get_unique_id()
