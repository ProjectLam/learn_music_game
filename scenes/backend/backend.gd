extends Control

var client: NakamaClient
var session: NakamaSession
var multiplayer_bridge: NakamaMultiplayerBridge
var socket: NakamaSocket

var test_email = "meow@meow.com"
var test_password = "meowwwwww"

var is_connected = false

var scheme = "https"
var host = "nakama.projectlam.org"
var port = 7352
var server_key = "iIvf]<9:kwRzWn2(A8:hnkF/c@iK@IZY"

func _ready():
	check_dev_values()
	
	client = Nakama.create_client(server_key, host, port, scheme)
	
	await login_password(test_email, test_password)
	
	socket = Nakama.create_socket_from(client)
	socket.connected.connect(_on_socket_connected)
	socket.closed.connect(_on_socket_closed)
	socket.received_error.connect(_on_socket_error)
	if session:
		await socket.connect_async(session)
	
	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	multiplayer_bridge.match_join_error.connect(_on_match_join_error)
	multiplayer_bridge.match_joined.connect(_on_match_joined)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

func check_dev_values() -> bool:
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
	
	print(session)
	print(session.token)
	print(session.user_id)
	print(session.username)
	print("session.expired: ", session.expired)
	print("session.expire_time: ", session.expire_time)
	
	return session

func _on_socket_connected():
	print("Socket connected.")
	is_connected = true

func _on_socket_closed():
	print("Socket closed.")
	is_connected = false

func _on_socket_error(err):
	printerr("Socket error %s" % err)

func _on_match_join_error(error):
	printerr("Unable to join match: ", error.message)

func _on_match_joined() -> void:
	print("Joined match with id: ", multiplayer_bridge.match_id)
