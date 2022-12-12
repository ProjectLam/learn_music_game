extends Object
class_name TLeaderboardItem

var number: int = -1: set = set_number
var user: TUser = null: set = set_user
var score: int = -1: set = set_score
var percent: int = -1: set = set_percent
var date: String = "": set = set_date

var nItem: LeaderboardItem

var serializable: Dictionary: set = set_serializable, get = get_serializable
var json: String: set = set_json, get = get_json

func _init(p_serializable: Dictionary = {}):
	if p_serializable.size():
		set_serializable(p_serializable)

func set_serializable(p_serializable: Dictionary) -> void:
	number = p_serializable["number"]
	user = TUser.new(p_serializable["user"])
	score = p_serializable["score"]

func get_serializable() -> Dictionary:
	return {
		number = number,
		user = user.serializable,
		score = score
	}

func set_json(p_json: String) -> void:
	serializable = JSON.parse_string(p_json)

func get_json() -> String:
	return JSON.stringify(serializable)

func set_number(p_number: int) -> void:
	number = p_number

func set_user(p_user: TUser) -> void:
	user = p_user

func set_score(p_score: int = -1) -> void:
	score = p_score

func set_percent(p_percent: int = -1) ->void:
	percent = p_percent

func set_date(p_date: String = "") -> void:
	date = p_date
