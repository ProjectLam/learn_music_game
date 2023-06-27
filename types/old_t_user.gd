extends Object

var id: String = ""
var username: String = ""
var avatar_url: String = ""
var is_online: bool: set = set_is_online

var serializable: Dictionary: set = set_serializable, get = get_serializable
var json: String: set = set_json, get = get_json
var nakama_object: NakamaAPI.ApiUser: set = set_nakama_object

func _init(p_from = null):
	if not p_from:
		return
	
	if p_from is NakamaAPI.ApiUser:
		var _nakama_object: NakamaAPI.ApiUser = p_from
		set_nakama_object(_nakama_object)
	elif p_from is Dictionary:
		var _seraliziable: Dictionary
		if _seraliziable.size():
			set_serializable(_seraliziable)

func set_serializable(p_serializable: Dictionary) -> void:
	id = p_serializable["id"]
	username = p_serializable["username"]
	avatar_url = p_serializable["avatar_url"]

func get_serializable() -> Dictionary:
	return {
		id = id,
		username = username,
		avatar_url = avatar_url
	}

func set_json(p_json: String) -> void:
	serializable = JSON.parse_string(p_json)

func get_json() -> String:
	return JSON.stringify(serializable)

func set_is_online(p_is_online: bool) -> void:
	is_online = p_is_online

func set_nakama_object(p_nakama_object: NakamaAPI.ApiUser) -> void:
	nakama_object = p_nakama_object
	
	id = nakama_object.id
	username = nakama_object.username
	avatar_url = nakama_object.avatar_url
	is_online = p_nakama_object.online
