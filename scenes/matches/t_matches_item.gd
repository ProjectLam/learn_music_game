extends Object
class_name TMatchesItem

var user: TUser = null: set = set_user
var players_count: int = -1: set = set_players_count
var date: String = "": set = set_date

var nItem: MatchesItem

var serializable: Dictionary: set = set_serializable, get = get_serializable
var json: String: set = set_json, get = get_json
var nakama_object: NakamaAPI.ApiMatch

func _init(p_from = null):
	if not p_from:
		return
	
	if p_from is NakamaAPI.ApiMatch:
		var _nakama_object: NakamaAPI.ApiMatch = p_from
		await set_nakama_object(_nakama_object)
	elif p_from is Dictionary:
		var _serializable: Dictionary = p_from
		if _serializable.size():
			set_serializable(_serializable)

func set_serializable(p_serializable: Dictionary) -> void:
	user = TUser.new(p_serializable["user"])
	players_count = p_serializable["players_count"]

func get_serializable() -> Dictionary:
	return {
		user = user.serializable,
		players_count = players_count
	}

func set_json(p_json: String) -> void:
	serializable = JSON.parse_string(p_json)

func get_json() -> String:
	return JSON.stringify(serializable)

func set_user(p_user: TUser) -> void:
	user = p_user

func set_players_count(p_players_count: int = -1) -> void:
	players_count = p_players_count

func set_date(p_date: String = "") -> void:
	date = p_date

func set_nakama_object(p_nakama_object: NakamaAPI.ApiMatch):
	nakama_object = p_nakama_object
	
	var nakama_user: NakamaAPI.ApiUser
	var _users: NakamaAPI.ApiUsers = await GBackend.client.get_users_async(GBackend.session, [nakama_object.self_user.user_id], [p_nakama_object.self_user.username])
	if not _users.users.size():
		print("Error while getting leaderboard user: #%s %s" % [nakama_object.owner_id, nakama_object.username])
		return
	nakama_user = _users.users[0]
	
	set_user(TUser.new(nakama_user))
	set_players_count(nakama_object.size)
	
	return _users
