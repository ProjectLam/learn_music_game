extends RefCounted

class_name User

func _init(p_from):
	if p_from is NakamaRTAPI.UserPresence:
		username = p_from.username
		user_id = p_from.user_id
		nkPresence = p_from
		session_id = p_from.session_id
	elif p_from is NakamaSession:
		username = p_from.username
		user_id = p_from.user_id


var nkPresence: NakamaRTAPI.UserPresence
var username: String
var user_id: String
var peer_id: int = -1
var session_id: String
