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

signal status_changed

var status := MatchMakingStatus.OFFLINE:
	set = set_status


func _ready():
	GBackend.connection_status_changed.connect(_on_connection_status_changed)


func set_status(value: MatchMakingStatus) -> void:
	if status != value:
		status = value
		status_changed.emit()


func create_match_async(song: Song) -> int:
	if status < MatchMakingStatus.IDLE:
		return -1
	
	
	if status != MatchMakingStatus.IDLE:
#		status = MatchMakingStatus.LEAVING_MATCH
		await GBackend.leave_match_async()
		if GBackend.connection_status != GBackend.CONNECTION_STATUS.CONNECTED:
			status = MatchMakingStatus.CONNECTING if GBackend.connection_status == GBackend.CONNECTION_STATUS.CONNECTING \
				else MatchMakingStatus.OFFLINE
			print("Match creation failed")
			return -1
	status = MatchMakingStatus.CREATING_MATCH
	
	
	
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


func _init_match(join_err: int) -> int:
	if GBackend.connection_status != GBackend.CONNECTION_STATUS.CONNECTED:
		status = MatchMakingStatus.CONNECTING if GBackend.connection_status == GBackend.CONNECTION_STATUS.CONNECTING \
			else MatchMakingStatus.OFFLINE
		return -1
	
	if join_err != OK:
		status = MatchMakingStatus.IDLE
		return join_err
	
	var isntrument_name = GBackend.multiplayer_bridge.match_label.get("instrument")
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
	match status:
		MatchMakingStatus.IDLE:
			status = MatchMakingStatus.JOINING_MATCH
			var ret := await GBackend.join_match_async(match_id)
			var init_err := await _init_match(ret)
			return init_err
		_:
			push_error("Status [%s] not implemented while joining match" % status)
			return -1


# returns OK on success
func leave_match_async() -> int:
	# TODO : don't confuse connecting with reconnecting while inside a match.
	match status:
		MatchMakingStatus.OFFLINE, MatchMakingStatus.IDLE:
			return OK
		_:
			await GBackend.leave_match_async()
			status = MatchMakingStatus.IDLE if GBackend.connection_status == GBackend.CONNECTION_STATUS.CONNECTED else MatchMakingStatus.OFFLINE
			return OK


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
