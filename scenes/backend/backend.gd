extends Control

var client: NakamaClient
var session: NakamaSession
var multiplayer_bridge: NakamaMultiplayerBridge
var socket: NakamaSocket

var test_email = "meow@meow.com"
var test_password = "meowwwwww"

var is_connected = false

# nakama
var scheme = "https"
var host = "nakama.projectlam.org"
var port = 7352
var server_key = "projectlam"

# song loading
var remote_songs_json_url := "http://127.0.0.1/test_files/pjlam/songs.json"
var remote_songs_info: Dictionary = {}
signal remote_songs_json_received
var remote_songs_json_initialized := false
const RTFILE_RQ_SCENE := preload("res://scenes/networking/remote_file_access/remote_file_request.tscn")
var song_json_file_request
var song_remote_access: RemoteFileAccess


@onready var nConnectionFailedDialog: Control = find_child("ConnectionFailedDialog")
@onready var nConnectionFailedDialog_AnimationPlayer: AnimationPlayer = nConnectionFailedDialog.get_node("AnimationPlayer")

@onready var nLoginFailedDialog: Control = find_child("LoginFailedDialog")
@onready var nLoginFailedDialog_AnimationPlayer: AnimationPlayer = nLoginFailedDialog.get_node("AnimationPlayer")

signal full_initialization
signal received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent)
signal received_match_state(p_state)
signal peer_connected(id : int)


func _ready():
	song_json_file_request = RTFILE_RQ_SCENE.instantiate()
	song_json_file_request.target_url = remote_songs_json_url
	song_json_file_request.request_completed_string.connect(_on_song_json_file_received)
	song_remote_access = RemoteFileAccess.new()
	song_remote_access.parent_url = remote_songs_json_url.get_base_dir()
	add_child(song_json_file_request)
	
	await multiplayer_init_async()
	if not remote_songs_json_initialized:
		await remote_songs_json_received
	
	
	_is_fully_initialized = true
	print("Backend fully initialized.")
	emit_signal("full_initialization")


func _process(delta: float) -> void:
	nLoginFailedDialog.pivot_offset.x = nLoginFailedDialog.get_rect().size.x/2
	nLoginFailedDialog.pivot_offset.y = nLoginFailedDialog.get_rect().size.y/2
	
	nLoginFailedDialog.pivot_offset.x = nLoginFailedDialog.get_rect().size.x/2
	nLoginFailedDialog.pivot_offset.y = nLoginFailedDialog.get_rect().size.y/2
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
	nConnectionFailedDialog.hide()
	nLoginFailedDialog.hide()
	
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
	nConnectionFailedDialog_AnimationPlayer.play("Open")


func close_connection_failed_dialog():
	nConnectionFailedDialog_AnimationPlayer.play("Close")


func open_login_failed_dialog():
	nLoginFailedDialog_AnimationPlayer.play("Open")


func close_login_failed_dialog():
	nLoginFailedDialog_AnimationPlayer.play("Close")


func _on_socket_connected():
	print("Socket connected.")
	is_connected = true


func _on_socket_closed():
	print("Socket closed.")
	is_connected = false
	open_connection_failed_dialog()


func _on_socket_error(err):
	printerr("Socket error %s" % err)
	open_connection_failed_dialog()


func _on_match_join_error(error):
	printerr("Unable to join match: ", error.message)


func _on_match_joined() -> void:
	print("Joined match with id: ", multiplayer_bridge.match_id)


func _on_ConnectionFailedDialog_CloseBtn_pressed() -> void:
	close_connection_failed_dialog()


func _on_ConnectionFailedDialog_OkBtn_pressed() -> void:
	close_connection_failed_dialog()


func _on_LoginFailedDialog_CloseBtn_pressed() -> void:
	close_login_failed_dialog()


func _on_LoginFailedDialog_OkBtn_pressed() -> void:
	close_login_failed_dialog()


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
