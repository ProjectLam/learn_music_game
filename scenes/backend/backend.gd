extends Control

var client: NakamaClient
var session: NakamaSession

var test_email = "meow6@meow.com"
var test_password = "meowwwwww"

func _ready():
	var scheme = "http"
	var host = "127.0.0.1"
	var port = 7350
	var server_key = "defaultkey"
	client = Nakama.create_client(server_key, host, port, scheme)
	
	login_password(test_email, test_password)

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
