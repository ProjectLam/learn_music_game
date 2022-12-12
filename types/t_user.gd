extends Object
class_name TUser

var id: int = 0
var name: String = ""
var avatar_url: String = ""

var serializable: Dictionary: set = set_serializable, get = get_serializable
var json: String: set = set_json, get = get_json

func _init(p_serializable: Dictionary = {}):
	if p_serializable.size():
		set_serializable(p_serializable)

func set_serializable(p_serializable: Dictionary) -> void:
	id = p_serializable["id"]
	name = p_serializable["name"]
	avatar_url = p_serializable["avatar_url"]

func get_serializable() -> Dictionary:
	return {
		id = id,
		name = name,
		avatar_url = avatar_url
	}

func set_json(p_json: String) -> void:
	serializable = JSON.parse_string(p_json)

func get_json() -> String:
	return JSON.stringify(serializable)
