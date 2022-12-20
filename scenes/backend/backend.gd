extends Control

var client: NakamaClient
var session: NakamaSession
var multiplayer_bridge: NakamaMultiplayerBridge
var socket: NakamaSocket

var test_email = "meow@meow.com"
var test_password = "meowwwwww"

func _ready():
	var scheme = "http"
	var host = "127.0.0.1"
	var port = 7350
	var server_key = "defaultkey"
	client = Nakama.create_client(server_key, host, port, scheme)
	
	await login_password(test_email, test_password)
	
	socket = Nakama.create_socket_from(client)
	socket.connected.connect(_on_socket_connected)
	socket.closed.connect(_on_socket_closed)
	socket.received_error.connect(_on_socket_error)
	await socket.connect_async(session)
	
	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	multiplayer_bridge.match_join_error.connect(_on_match_join_error)
	multiplayer_bridge.match_joined.connect(_on_match_joined)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

func login_password(p_email: String, p_password: String) -> NakamaSession:
	var email = p_email
	var password = p_password
	
	session = await client.authenticate_email_async(email, password)
	
	print(session)
	print(session.token)
	print(session.user_id)
	print(session.username)
	print("session.expired: ", session.expired)
	print("session.expire_time: ", session.expire_time)
	
	return session

func _on_socket_connected():
	print("Socket connected.")

func _on_socket_closed():
	print("Socket closed.")

func _on_socket_error(err):
	printerr("Socket error %s" % err)

func _on_match_join_error(error):
	printerr("Unable to join match: ", error.message)

func _on_match_joined() -> void:
	print("Joined match with id: ", multiplayer_bridge.match_id)
