extends Object
class_name TLeaderboardItem

var rank: int = -1: set = set_rank
var user: TUser = null: set = set_user
var score: int = -1: set = set_score
var percent: int = -1: set = set_percent
var date: String = "": set = set_date

var nItem: LeaderboardItem

var serializable: Dictionary: set = set_serializable, get = get_serializable
var json: String: set = set_json, get = get_json
var nakama_object: NakamaAPI.ApiLeaderboardRecord

func _init(p_from = null):
	if not p_from:
		return
	
	if p_from is NakamaAPI.ApiLeaderboardRecord:
		var _nakama_object: NakamaAPI.ApiLeaderboardRecord = p_from
		await set_nakama_object(_nakama_object)
	elif p_from is Dictionary:
		var _serializable: Dictionary = p_from
		if _serializable.size():
			set_serializable(_serializable)

func set_serializable(p_serializable: Dictionary) -> void:
	rank = p_serializable["rank"]
	user = TUser.new(p_serializable["user"])
	score = p_serializable["score"]

func get_serializable() -> Dictionary:
	return {
		rank = rank,
		user = user.serializable,
		score = score
	}

func set_json(p_json: String) -> void:
	serializable = JSON.parse_string(p_json)

func get_json() -> String:
	return JSON.stringify(serializable)

func set_rank(p_rank: int) -> void:
	rank = p_rank

func set_user(p_user: TUser) -> void:
	user = p_user

func set_score(p_score: int = -1) -> void:
	score = p_score

func set_percent(p_percent: int = -1) ->void:
	percent = p_percent

func set_date(p_date: String = "") -> void:
	date = p_date

func set_nakama_object(p_nakama_object: NakamaAPI.ApiLeaderboardRecord):
	nakama_object = p_nakama_object
	
	var nakama_user: NakamaAPI.ApiUser
	var _users: NakamaAPI.ApiUsers = await GBackend.client.get_users_async(GBackend.session, [nakama_object.owner_id], [p_nakama_object.username])
	if not _users.users.size():
		print("Error while getting leaderboard user: #%s %s" % [nakama_object.owner_id, nakama_object.username])
		return
	nakama_user = _users.users[0]
	
	set_user(TUser.new(nakama_user))
	set_score(int(nakama_object.score))
	set_rank(int(nakama_object.rank))
	
	return _users
