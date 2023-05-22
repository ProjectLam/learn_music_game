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

var user_email = "meow@meow.com"
var user_password = "meowwwwww"

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

var is_js_enabled = Engine.has_singleton("JavaScriptBridge") && OS.get_name() == 'Web'
var _js_godotGame: JavaScriptObject
var _js_login_callback_ref

@onready var ui_node := $CanvasLayer
@onready var status_node = %Status

signal session_created
signal full_initialization
signal received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent)
signal received_match_state(p_state)
#signal peer_connected(id : int)
signal remote_songs_json_received
signal login_set(cancelled: bool)
signal connection_status_changed

func _init():
	if is_js_enabled:
		_js_godotGame = JavaScriptBridge.get_interface("godotGame")
		if is_instance_valid(_js_godotGame):
			_js_login_callback_ref = JavaScriptBridge.create_callback(_login_password_js_wrapper)
			_js_godotGame.loginCallback = _js_login_callback_ref
		else:
			push_error("JS enabled, but godotGame not defined")
			is_js_enabled = false


func _ready():
	
	Dialogs.file_offline_dialog.option_selected.connect(
		_on_file_offline_dialog_response)
	Dialogs.login_failed_dialog.option_selected.connect(
		_on_login_failed_dialog_option_selected)
	
	refresh()
	
	init_remote_songs_json_url()
	
	if skip_remote_json_load:
		# skip
		remote_songs_json_initialized = true
	else:
		call_deferred("init_json_request")
	
	
	if not remote_songs_json_initialized:
		await remote_songs_json_received
	
	_is_fully_initialized = true
	print("GBackend fully initialized.")
	emit_signal("full_initialization")
	
	
	await multiplayer_init_async()


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
	if is_js_enabled:
		var jscript_eval = _js_godotGame.getSongsManifest()
		if jscript_eval is String:
			remote_songs_json_url = jscript_eval
	#else:
	#	remote_songs_json_url = "http://127.0.0.1/songs.json"
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


func create_client_and_socket():
	client = Nakama.create_client(server_key, host, port, scheme)
	socket = Nakama.create_socket_from(client)
	socket.received_match_presence.connect(_on_received_match_presence)
	socket.received_match_state.connect(_on_received_match_state)
	socket.connected.connect(_on_socket_connected)
	socket.closed.connect(_on_socket_closed)
	socket.received_error.connect(_on_socket_error)
	socket.connection_error.connect(_on_socket_connection_error)


func multiplayer_init_async():
	check_nakama_dev_values()
	create_client_and_socket()
	
	await try_login_async()


# TODO : check to see if the sockets can be reused. make new ones if needed.
func _init_socket():
#	socket = Nakama.create_socket_from(client)
#	socket.received_match_presence.connect(_on_received_match_presence)
#	socket.received_match_state.connect(_on_received_match_state)
#	socket.connected.connect(_on_socket_connected)
#	socket.closed.connect(_on_socket_closed)
#	socket.received_error.connect(_on_socket_error)
	await socket.connect_async(session)


func _init_multiplayer_bridge():
	if is_instance_valid(multiplayer_bridge):
		multiplayer_bridge.match_join_error.disconnect(_on_match_join_error)
		multiplayer_bridge.match_joined.disconnect(_on_match_joined)
		multiplayer_bridge.queue_free()
		
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
		multiplayer_bridge._multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_CONNECTING)
		multiplayer.set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)
		multiplayer_bridge._multiplayer_peer.set_connection_status(MultiplayerPeer.CONNECTION_DISCONNECTED)
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
				user_email = dev["nakama"]["test_user"]["email"]
				user_password = dev["nakama"]["test_user"]["password"]
	
	if CmdArgs.arguments.has("email"):
		user_email = CmdArgs.arguments["email"]
	
	if CmdArgs.arguments.has("password"):
		user_password = CmdArgs.arguments["password"]


func open_js_login_dialog():
	_js_godotGame.showLoginModal(true)


# NOTE: In Godot 4 the callback MUST have an Array arg,
# and when invoked from JS you MUST pass in an argument (null will do).
# Failing to do any of the above will not produce any kind of error, the
# callback will just fail silently!
func _login_password_js_wrapper(p: Array):
	user_email = p[0]
	user_password = p[1]
	login_set.emit(false)


# creates valid session.
func authenticate_async():
	session = await client.authenticate_email_async(user_email, user_password)
	if session.is_exception():
		push_warning("Login Error: ", session.exception)
		var msg = session.exception.message
		session = null
		if is_js_enabled:
			_js_godotGame.onLoginError(msg)
			# TODO : this has to prompt the user to try to login again or continue without loggin in.
			# TODO : call login_set.emit(false) if the login is cancelled.
		else:
			Dialogs.login_failed_dialog.message = msg
			Dialogs.login_failed_dialog.open()
	elif not session.is_valid() or session.is_expired():
		var msg := "Invalid Session"
		session = null
		push_warning("Login Error: ", msg)
		if is_js_enabled:
			_js_godotGame.onLoginError(msg)
			# TODO : this has to prompt the user to try to login again or continue without loggin in.
			# TODO : call login_set.emit(false) if the login is cancelled.
		else:
			Dialogs.login_failed_dialog.message = msg
			Dialogs.login_failed_dialog.open()
	else:
		print(session)
		print(session.token)
		print(session.user_id)
		print(session.username)
		print("session.expired: ", session.expired)
		print("session.expire_time: ", session.expire_time)


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
	
	if client:
		var ret = await client.list_matches_async(session, min_players, maxpl, limit, true, label, query)
		return ret
	else:
		push_warning("invalid client")
		return NakamaAPI.ApiMatchList.new()
	


# returns OK if it succeeds. this will be replaced with an error later.
func create_match_async(match_name = "", params := {}) -> int:
	await await_finit()
	if connection_status in [CONNECTION_STATUS.CONNECTING, CONNECTION_STATUS.CONNECTING]:
		push_error("Trying to create match while connection is not established. Disable access from the UI")
		if connection_status == CONNECTION_STATUS.DISCONNECTED:
			return -1
	if multiplayer_bridge == null:
		while connection_status == CONNECTION_STATUS.CONNECTING:
			await get_tree().process_frame
		if problem_with_server:
			Dialogs.problem_with_server_dialog.open()
		else:
			Dialogs.connection_failed_dialog.open()
		return -1
	await multiplayer_bridge.create_match_async(match_name, params)
	if multiplayer_bridge.match_state != NakamaMultiplayerBridge.MatchState.CONNECTED:
		Dialogs.create_match_failed_dialog.open()
		return -1
	return OK


func leave_match_async() -> void:
	await await_finit()
	if multiplayer_bridge == null:
		if problem_with_server:
			Dialogs.problem_with_server_dialog.open()
		else:
			Dialogs.connection_failed_dialog.open()
		return
	await multiplayer_bridge.leave_match_async()


# returns OK if it succeeds. this will be replaced with an error later.
func join_match_async(p_match_id: String) -> int:
	await await_finit()
	if connection_status in [CONNECTION_STATUS.CONNECTING, CONNECTION_STATUS.CONNECTING]:
		push_error("Trying to create match while connection is not established. Disable access from the UI")
		if connection_status == CONNECTION_STATUS.DISCONNECTED:
			return -1
	if multiplayer_bridge == null:
		while connection_status == CONNECTION_STATUS.CONNECTING:
			await get_tree().process_frame
		if problem_with_server:
			Dialogs.problem_with_server_dialog.open()
		else:
			Dialogs.connection_failed_dialog.open()
		return -1
	await multiplayer_bridge.join_match_async(p_match_id)
	if multiplayer_bridge.match_state != NakamaMultiplayerBridge.MatchState.CONNECTED:
		Dialogs.join_match_failed_dialog.open()
		return -1
	return OK


func _on_peer_connected(id : int) -> void:
	pass


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
		connection_status_changed.emit()


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


func _on_login_failed_dialog_option_selected(params : Dictionary):
	var opt = params.get("option")
	match(opt):
		"try_again":
			print("Trying to login again")
			await try_login_async()
		"continue_offline", PopupBase.OPTION_CLOSE:
			await logout()
			print("Continuing offline without loggin in")
		_:
			push_error("Invalid response [%s] to login failure" % str(opt))


func logout(manual: bool = false):
	if session_is_valid():
		await client.session_logout_async(session)
	session = null
	if not manual:
		connection_status = CONNECTION_STATUS.DISCONNECTED


func try_login_async():
	connection_status = CONNECTION_STATUS.CONNECTING
	await logout(true)
	var cancelled = false
	if not session_is_valid():
		if is_js_enabled:
			open_js_login_dialog()
			cancelled = await login_set
		else:
			# TODO : add a login dialog before loggin in.
			pass
	
	# setting new session.
	if not cancelled:
		await authenticate_async()
		# In case of an authentication failure _on_login_failed_dialog_option_selected will handle 
		# things based on user's choice.
	else:
		# We're logged out now.
		connection_status = CONNECTION_STATUS.DISCONNECTED
		return
	
	if session_is_valid():
		# authentication failed.
		await connect_to_session_async()
		if is_js_enabled:
			_js_godotGame.onLoginOk()
		
		await _init_multiplayer_bridge()
		if is_logged_in():
			connection_status = CONNECTION_STATUS.CONNECTED
		# We keep the state on connecting till login failed dialog decides if we want to keep trying.
#		else:
#			connection_status = CONNECTION_STATUS.DISCONNECTED


# returns OK if it succeeds. -1.
func connect_to_session_async() -> int:
	if not session or not session.valid or session.is_expired():
		push_error("cannot connect to invalid session")
		if connection_status != CONNECTION_STATUS.DISCONNECTED:
			connection_status = CONNECTION_STATUS.DISCONNECTED
		Dialogs.connection_failed_dialog.open()
		return -1
	
	await socket.connect_async(session, false, 10)
	if not is_logged_in():
		return -1
	
	return OK


func is_logged_in():
	return socket.is_connected_to_host()


func session_is_valid() -> bool:
	return session and not session.is_exception() and session.is_valid() and not session.is_expired()


func _on_socket_connection_error(p_error):
	pass
