extends RefCounted

class_name LAMMatch

signal changed
signal game_status_changed

enum GameStatus {
	UNDEFINED,
	DEFAULT,
	STARTED
}

const GameStatusStrings := {
	"default": GameStatus.DEFAULT,
	"started": GameStatus.STARTED,
}

var apimatch: NakamaAPI.ApiMatch :
	set = set_apimatch
var match_id: String = ""
var string_label: String = ""
var parsed_label
var instrument_name := ""
var song_identifier := ""
var player_count := -1
var player_limit := 0
var match_name := "" 
var password_proceted := false
var game_status := GameStatus.UNDEFINED
var allow_join_after_start := false

var invalid := true


func _init(p_from = null):
	if p_from:
		if p_from is NakamaAPI.ApiMatch:
			apimatch = p_from
		elif p_from is String:
			parse_label(p_from)

func parse_label(new_label: String) -> bool:
	if string_label == new_label:
		return false
	string_label = new_label
	var _changed := false
	var _game_status_changed := false
	parsed_label = JSON.parse_string(new_label)
	var _invlaid := false
	
	if parsed_label == null:
		invalid = true
		return true
	if not (parsed_label is Dictionary):
		parsed_label = null
		invalid = true
		push_error("Invalid match label detected")
		_changed = true
	else:
		# match name
		var lname = parsed_label.get("name")
		if not (lname is String):
			_invlaid = true
			match_name = ""
			push_error("Ivalid match name")
			_changed = true
		else:
			if match_name != lname:
				match_name = lname
				_changed = true
		
		# song id
		var lsongid = parsed_label.get("song")
		if not (lsongid is String):
			song_identifier = ""
			_invlaid = true
			push_error("Invalid song identifier")
			_changed = true
		else:
			if song_identifier != lsongid:
				song_identifier = lsongid
				_changed = true
		
		# match instrument
		var linsname = parsed_label.get("instrument")
		if not (linsname is String):
			instrument_name = ""
			_invlaid = true
			push_error("Invalid instrument name")
			_changed = true
		else:
			if instrument_name != linsname:
				instrument_name = linsname.get_basename()
				_changed = true
		
		# player limit
		var lplimit = parsed_label.get("player_limit")
		if not (lplimit is int) and not (lplimit is float):
			player_limit = 0
			_invlaid = true
			push_error("Invalid player limit")
			_changed = true
		else:
			if player_limit != lplimit:
				player_limit = int(lplimit)
				_changed = true
		
		# password status
		var lpassprotected = parsed_label.get("password_protected")
		if not (lpassprotected is bool):
			password_proceted = true
			_invlaid = true
			push_error("Invalid value for [password_protected]")
			_changed = true
		else:
			if password_proceted != lpassprotected:
				password_proceted = lpassprotected
				_changed = true
		
		var lgstatus_str = parsed_label.get("game_status") 
		if not (lgstatus_str is String):
			game_status = GameStatus.UNDEFINED
			_invlaid = true
			push_error("Invalid game status")
			_changed = true
		else:
			var lgstatus_v = GameStatusStrings.get(lgstatus_str)
			if lgstatus_v == null:
				game_status = GameStatus.UNDEFINED
				_invlaid = true
				push_error("Invalid game status")
				_changed = true
			else:
				if game_status != lgstatus_v:
					_game_status_changed = true
					game_status = lgstatus_v
		
		var lallow_join_after_start = parsed_label.get("allow_join_after_start")
		if not (lallow_join_after_start is bool):
			_invlaid = true
			push_error("Invalid value for [allow_join_after_start]")
			_changed = true
			allow_join_after_start = false
		else:
			if allow_join_after_start != lallow_join_after_start:
				allow_join_after_start = lallow_join_after_start
				_changed = true
	
	_changed = _changed or _game_status_changed
	invalid = _invlaid
	
	if _changed:
		changed.emit()
	
	if _game_status_changed:
		game_status_changed.emit()
	
	return _changed
	
func set_apimatch(value: NakamaAPI.ApiMatch) -> void:
	if apimatch != value:
		var _changed := false
		apimatch = value
		if match_id != apimatch.match_id:
			match_id = apimatch.match_id
			_changed = true
		
		if player_count != apimatch.size:
			player_count = apimatch.size
			_changed = true
		
		# do not parse the label again if it hasn't changed.
		if apimatch != null:
			_changed = parse_label(apimatch.label) or _changed
		
		if _changed:
			changed.emit()


func join_allowed_filter() -> bool:
	if player_count < -1:
		# not initialized:
		return false
	return allow_join_after_start or game_status == GameStatus.DEFAULT


func is_valid():
	return not invalid

