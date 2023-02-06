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
const POPUP_SCENE := preload("res://scenes/popup_dialog/popup_dialog.tscn")
var song_json_file_request
var song_remote_access: RemoteFileAccess
var connection_status := CONNECTION_STATUS.DISCONNECTED :
	set = set_connection_status,
	get = get_connection_status
var file_src_mode := FILE_SRC_MODE.REMOTE :
	set = set_file_src_mode,
	get = get_file_src_mode
var fetcher_count := 0

var current_dialog
var file_offline_dialog :
	set(value):
		current_dialog = value
		file_offline_dialog = value

@onready var ui_node := $CanvasLayer
@onready var status_node = %Status

signal full_initialization
signal received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent)
signal received_match_state(p_state)
signal peer_connected(id : int)
signal remote_songs_json_received
signal file_offline_dialog_closed


func _ready():
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
	print("Backend fully initialized.")
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
	remote_songs_json_url = "http://127.0.0.1/songs.json"


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
	
	socket = Nakama.create_socket_from(client)
	socket.received_match_presence.connect(_on_received_match_presence)
	socket.received_match_state.connect(_on_received_match_state)
	socket.connected.connect(_on_socket_connected)
	socket.closed.connect(_on_socket_closed)
	socket.received_error.connect(_on_socket_error)
	socket.connect_async(session)
	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	multiplayer_bridge.match_join_error.connect(_on_match_join_error)
	multiplayer_bridge.match_joined.connect(_on_match_joined)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)
	
	multiplayer.peer_connected.connect(_on_peer_connected)


func check_nakama_dev_values() -> bool:
	if not FileAccess.file_exists("user://dev.json"):
		return false
	var file = FileAccess.open("user://dev.json", FileAccess.READ)
	var content = file.get_as_text()
	var dev = JSON.parse_string(content)
	
	if dev.has("nakama"):
		scheme = dev["nakama"]["connection"]["protocol"]
		host = dev["nakama"]["connection"]["address"]
		port = int(dev["nakama"]["connection"]["port"])
		server_key = dev["nakama"]["connection"]["server_key"]
		
		if dev["nakama"].has("test_user"):
			test_email = dev["nakama"]["test_user"]["email"]
			test_password = dev["nakama"]["test_user"]["password"]
	
	return false


func login_password(p_email: String, p_password: String) -> NakamaSession:
	var email = p_email
	var password = p_password
	
	session = await client.authenticate_email_async(email, password)
	
	if session.is_exception():
		print("Login Error: ", session.exception)
		open_login_failed_dialog()
	
	print(session)
	print(session.token)
	print(session.user_id)
	print(session.username)
	print("session.expired: ", session.expired)
	print("session.expire_time: ", session.expire_time)
	
	return session


func open_connection_failed_dialog():
	var instant_spawn := false
	if not is_current_dialog_done():
		instant_spawn = true
		current_dialog.instant_fade = true
		while not is_current_dialog_done():
			await current_dialog.option_selected
		current_dialog.visible = false
	current_dialog = POPUP_SCENE.instantiate()
	current_dialog.instant_spawn = instant_spawn
	current_dialog.title = "Connection Failed"
	current_dialog.message = "Connection failed to server!"
	current_dialog.options = ["Ok"]
	
	ui_node.add_child(current_dialog)


func open_login_failed_dialog():
	var instant_spawn := false
	if not is_current_dialog_done():
		instant_spawn = true
		current_dialog.instant_fade = true
		while not is_current_dialog_done():
			await current_dialog.option_selected
		current_dialog.visible = false
	current_dialog = POPUP_SCENE.instantiate()
	current_dialog.instant_spawn = instant_spawn
	current_dialog.title = "Login Failed"
	current_dialog.message = "Your email or password were wrong!"
	current_dialog.options = ["Ok"]
	
	ui_node.add_child(current_dialog)


func _on_socket_connected():
	print("Socket connected.")
	connection_status = CONNECTION_STATUS.CONNECTED


func _on_socket_closed():
	print("Socket closed.")
	connection_status = CONNECTION_STATUS.DISCONNECTED
	open_connection_failed_dialog()


func _on_socket_error(err):
	printerr("Socket error %s" % err)


func _on_match_join_error(error):
	printerr("Unable to join match: ", error.message)


func _on_match_joined() -> void:
	print("Joined match with id: ", multiplayer_bridge.match_id)


func _on_received_match_state(p_state) -> void:
	print("Received match state: ", p_state)
	received_match_state.emit(p_state)


func _on_received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent) -> void:
	received_match_presence.emit(p_presence)


func create_match_async(match_name = "") -> void:
	await await_finit()
	# TODO : add match naming. create_match_async should not be called on socket without
	#  taking care of additional logic implemented in create_match()
	await multiplayer_bridge.create_match()


func leave_async() -> void:
	await await_finit()
	await multiplayer_bridge.leave()


func join_match_async(p_match_id: String) -> void:
	await await_finit()
	await multiplayer_bridge.join_match(p_match_id)


func _on_peer_connected(id : int) -> void:
	peer_connected.emit(id)


func _on_song_json_file_received(json_string: String):
	var parse_result := JSON.parse_string(json_string)
	if parse_result is Dictionary:
		remote_songs_info = parse_result
	else:
		push_error("unimplemented remote song json format")
	remote_songs_json_initialized = true
	remote_songs_json_received.emit()


func is_current_dialog_done() -> bool:
	return not is_instance_valid(current_dialog) or current_dialog.done


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


func _on_file_offline_dialog_closed():
	file_offline_dialog_closed.emit()


func file_offline_dialog_response(option: String) -> void:
	match(option):
		"Yes":
			file_src_mode = FILE_SRC_MODE.OFFLINE
		"No":
			pass


func open_file_offline_dialog(msg: String = ""):
	if is_instance_valid(file_offline_dialog) and not file_offline_dialog.done:
		return
	
	await get_tree().process_frame
	
	var instant_spawn := false
	if not is_current_dialog_done():
		instant_spawn = true
		current_dialog.instant_fade = true
		while not is_current_dialog_done():
			await current_dialog.option_selected
		current_dialog.visible = false
	
	var title := "Failed to download file"
	var message := "Switch to offline mode?"
	if msg != "":
		message = "%s\n%s" % [msg, message]
	file_offline_dialog = POPUP_SCENE.instantiate()
	file_offline_dialog.tree_exited.connect(_on_file_offline_dialog_closed)
	file_offline_dialog.title = title
	file_offline_dialog.instant_spawn = instant_spawn
	file_offline_dialog.message = message
	file_offline_dialog.option_selected.connect(file_offline_dialog_response)
	file_offline_dialog.options = ["Yes", "No"]
	
	ui_node.add_child(file_offline_dialog)
