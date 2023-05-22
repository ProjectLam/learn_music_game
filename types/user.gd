extends RefCounted

class_name User

func _init(p_from):
	if p_from is NakamaRTAPI.UserPresence:
		username = p_from.username
		user_id = p_from.user_id


var username: String
var user_id: String
