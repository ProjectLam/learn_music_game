extends Control

enum CONNECTION_STATUS {
	DISCONNECTED,
	CONNECTING,
	CONNECTED
}

enum FILE_SRC_MODE {
	OFFLINE,
	FETCHING,
	REMOTE
}

var client: NakamaClient
var session: NakamaSession
var multiplayer_bridge: NakamaMultiplayerBridge
var socket: NakamaSocket

var test_email = "meow@meow.com"
var test_password = "meowwwwww"

# nakama
var scheme = "https"
var host = "nakama.projectlam.org"
var port = 7352
var server_key = "projectlam"

# song loading
var remote_songs_json_url := ""
var remote_songs_info: Dictionary = {}
var skip_remote_json_load := false
var remote_songs_json_initialized := false
const RTFILE_RQ_SCENE := preload("res://scenes/networking/remote_file_access/remote_file_request.tscn")

var song_json_file_request
var song_remote_access: RemoteFileAccess
var connection_status := CONNECTION_STATUS.DISCONNECTED :
	set = set_connection_status,
	get = get_connection_status
var file_src_mode := FILE_SRC_MODE.REMOTE :
	set = set_file_src_mode,
	get = get_file_src_mode
var fetcher_count := 0

var problem_with_server := false

@onready var ui_node := $CanvasLayer
@onready var status_node = %Status

signal full_initialization
signal received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent)
signal received_match_state(p_state)
signal peer_connected(id : int)
signal remote_songs_json_received


func _ready():
	
	Dialogs.file_offline_dialog.option_selected.connect(
		_on_file_offline_dialog_response)
	
	refresh()
	
	init_remote_songs_json_url()
	
	if skip_remote_json_load:
		# skip
		remote_songs_json_initialized = true
	else:
		call_deferred("init_json_request")
	
	await multiplayer_init_async()
	if not remote_songs_json_initialized:
		await remote_songs_json_received
	
	
	_is_fully_initialized = true
	print("GBackend fully initialized.")
	emit_signal("full_initialization")


func init_json_request():
	if skip_remote_json_load:
		# skip
		remote_songs_json_initialized = true
		return
	
	
	if remote_songs_json_url == "":
		push_error("remote remote_songs_json_url not set")
		file_src_mode = FILE_SRC_MODE.OFFLINE
		_on_song_json_file_received("{}")
		return
	
	song_json_file_request = RTFILE_RQ_SCENE.instantiate()
	song_json_file_request.target_url = remote_songs_json_url
	song_json_file_request.request_completed_string.connect(_on_song_json_file_received)
	song_remote_access = RemoteFileAccess.new()
	song_remote_access.parent_url = remote_songs_json_url.get_base_dir()
	add_child(song_json_file_request)


func init_remote_songs_json_url():
#	var os_name = OS.get_name()
#	if Engine.has_singleton("JavaScriptBridge") and (os_name == 'HTML5' || os_name == 'Web'):
#		var jscript_eval = JavaScriptBridge.eval("godotGame.getSongsManifest();", true)
#		if jscript_eval is String:
#			remote_songs_json_url = jscript_eval
#	else:
#		# TODO : decinde on what to use for this.
#		remote_songs_json_url = "http://127.0.0.1/songs.json"
	pass


# use 'await await_finit()' to wait for full initialization.
func await_finit():
	if _is_fully_initialized:
		return
	await full_initialization


func await_connection():
	await await_finit()
	while(
		(socket.is_connected_to_host() || socket.is_connecting_to_host()) &&
		multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING):
		
		await get_tree().process_frame


var _is_fully_initialized = false
func is_fully_initialized() -> bool:
	return _is_fully_initialized


func multiplayer_init_async():
	connection_status = CONNECTION_STATUS.CONNECTING
	check_nakama_dev_values()
	client = Nakama.create_client(server_key, host, port, scheme)
	
	await login_password(test_email, test_password)
	
	if not session.is_exception():
		await _init_socket()
		await _init_multiplayer_bridge()


# TODO : check to see if the sockets can be reused. make new ones if needed.
func _init_socket():
	socket = Nakama.create_socket_from(client)
	socket.received_match_presence.connect(_on_received_match_presence)
	socket.received_match_state.connect(_on_received_match_state)
	socket.connected.connect(_on_socket_connected)
	socket.closed.connect(_on_socket_closed)
	socket.received_error.connect(_on_socket_error)
	await socket.connect_async(session)


func _init_multiplayer_bridge():
	multiplayer_bridge = await NakamaMultiplayerBridge.new(socket)
	
	# bridge_initializing is because a bug was detected that led to _init 
	# returning before the initializiation is complete.
	# TODO : report this bug.
	while(multiplayer_bridge.bridge_initializing):
		await get_tree().process_frame

	if not multiplayer_bridge.valid:
		multiplayer_bridge.free()
		multiplayer_bridge = null
	else:
		
		multiplayer_bridge.match_join_error.connect(_on_match_join_error)
		multiplayer_bridge.match_joined.connect(_on_match_joined)
		add_child(multiplayer_bridge)
		get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)
		
		multiplayer.peer_connected.connect(_on_peer_connected)
	
	if multiplayer_bridge == null:
		push_error("Invalid multiplayer bridge detected.")
		if problem_with_server:
			Dialogs.problem_with_server_dialog.open()
		else:
			Dialogs.connection_failed_dialog.open()


func check_nakama_dev_values() -> void:
	if FileAccess.file_exists("user://dev.json"):
		var file = FileAccess.open("user://dev.json", FileAccess.READ)
		var content = file.get_as_text()
		var dev = JSON.parse_string(content)
		print("parsed dev json : ", dev)
		if dev.has("nakama"):
			scheme = dev["nakama"]["connection"]["protocol"]
			host = dev["nakama"]["connection"]["address"]
			port = int(dev["nakama"]["connection"]["port"])
			server_key = dev["nakama"]["connection"]["server_key"]
			
			if dev["nakama"].has("test_user"):
				test_email = dev["nakama"]["test_user"]["email"]
				test_password = dev["nakama"]["test_user"]["password"]
	
	if CmdArgs.arguments.has("email"):
		test_email = CmdArgs.arguments["email"]
	
	if CmdArgs.arguments.has("password"):
		test_password = CmdArgs.arguments["password"]


func login_password(p_email: String, p_password: String) -> NakamaSession:
	var email = p_email
	var password = p_password
	
	session = await client.authenticate_email_async(email, password)
	
	if session.is_exception():
		push_warning("Login Error: ", session.exception)
		if not (
				session.exception.status_code in [
					HTTPClient.STATUS_CONNECTED,
					HTTPClient.STATUS_BODY
				]):
			# http request failed.
			connection_status = CONNECTION_STATUS.DISCONNECTED
			Dialogs.connection_failed_dialog.open()
		else:
			Dialogs.login_failed_dialog.open()
	else:
		print(session)
		print(session.token)
		print(session.user_id)
		print(session.username)
		print("session.expired: ", session.expired)
		print("session.expire_time: ", session.expire_time)
	
	return session


func _on_socket_connected():
	print("Socket connected.")
	connection_status = CONNECTION_STATUS.CONNECTED


func _on_socket_closed():
	print("Socket closed.")
	if connection_status != CONNECTION_STATUS.DISCONNECTED:
		connection_status = CONNECTION_STATUS.DISCONNECTED
		Dialogs.connection_failed_dialog.open()


func _on_socket_error(err):
	printerr("Socket error %s" % err)


func _on_match_join_error(error):
	var msg = error.get("message")
	if msg == null:
		msg = error
	printerr("Unable to join match: ", msg)
	Dialogs.join_match_failed_dialog.message = msg


func _on_match_joined() -> void:
	print("Joined match with id: ", multiplayer_bridge.match_id)


func _on_received_match_state(p_state) -> void:
	received_match_state.emit(p_state)


func _on_received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent) -> void:
	received_match_presence.emit(p_presence)


func list_matches_async(min_players : int = 1, max_players : int = -1, limit : int = 100,
		label : String = "", query : String = "") -> NakamaAPI.ApiMatchList:
	var maxpl
	if max_players > 0:
		maxpl = max_players
	
	
	return await client.list_matches_async(session, min_players, maxpl, limit, true, label, query)
	


# returns false if it succeeds. this will be replaced with an error later.
func create_match_async(match_name = "", params := {}) -> bool:
	await await_finit()
	if multiplayer_bridge == null:
		if problem_with_server:
			Dialogs.problem_with_server_dialog.open()
		else:
			Dialogs.connection_failed_dialog.open()
		return true
	await multiplayer_bridge.create_match_async(match_name, params)
	if multiplayer_bridge.match_state != NakamaMultiplayerBridge.MatchState.CONNECTED:
		Dialogs.create_match_failed_dialog.open()
		return true
	return false


func leave_async() -> void:
	await await_finit()
	if multiplayer_bridge == null:
		if problem_with_server:
			Dialogs.problem_with_server_dialog.open()
		else:
			Dialogs.connection_failed_dialog.open()
		return
	await multiplayer_bridge.leave_async()


# returns false if it succeeds. this will be replaced with an error later.
func join_match_async(p_match_id: String) -> bool:
	await await_finit()
	if multiplayer_bridge == null:
		if problem_with_server:
			Dialogs.problem_with_server_dialog.open()
		else:
			Dialogs.connection_failed_dialog.open()
		return true
	await multiplayer_bridge.join_match_async(p_match_id)
	if multiplayer_bridge.match_state != NakamaMultiplayerBridge.MatchState.CONNECTED:
		Dialogs.join_match_failed_dialog.open()
		return true
	return false


func _on_peer_connected(id : int) -> void:
	peer_connected.emit(id)


func _on_song_json_file_received(json_string: String):
	var parse_result = JSON.parse_string(json_string)
	if parse_result is Dictionary:
		remote_songs_info = parse_result
	else:
		push_error("unimplemented remote song json format")
	remote_songs_json_initialized = true
	remote_songs_json_received.emit()


func set_connection_status(value) -> void:
	if connection_status != value:
		connection_status = value
		refresh()


func get_connection_status():
	return connection_status


func set_file_src_mode(value) -> void:
	if file_src_mode != value:
		file_src_mode = value
		refresh()


func get_file_src_mode():
	return file_src_mode


func refresh():
	if status_node:
		status_node.refresh()


func add_fetcher():
	assert(file_src_mode != FILE_SRC_MODE.OFFLINE)
	fetcher_count += 1
	if fetcher_count == 1:
		file_src_mode = FILE_SRC_MODE.FETCHING


func remove_fetcher():
	fetcher_count -= 1
	if fetcher_count == 0 and file_src_mode == FILE_SRC_MODE.FETCHING:
		file_src_mode = FILE_SRC_MODE.REMOTE


func _on_file_offline_dialog_response(params: Dictionary) -> void:
	var option = params.get("option")
	if not (option is String):
		push_error("invalid option for file offline dialog")
		return
	match(option.to_lower()):
		"yes":
			file_src_mode = FILE_SRC_MODE.OFFLINE
		"no":
			pass


func logout():
	# TODO
	pass
