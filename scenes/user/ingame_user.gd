extends Resource

class_name IngameUser

var user: User

# In future in between valus can be used to show a loading progress if needed.
enum ReadyStatus {
	NOT_READY = 0,
	READY = 100
}


var _score: float = 0
var score: float :
	set = set_score,
	get = get_score

# This property is meant to be used to let others know the player or their client is not ready yet.
var _ready_status: ReadyStatus = ReadyStatus.NOT_READY
var ready_status: ReadyStatus:
	set = set_ready_status,
	get = get_ready_status

signal score_changed
signal ready_status_changed


func _on_good_note(note_index: int, timing_error: float) -> void:
	# TODO : add score calculations here.
	_score += 1.0
	
	score_changed.emit()
	changed.emit()


func set_score(svalue: float) -> void:
	if _score != svalue:
		_score = svalue
		
		score_changed.emit()
		changed.emit()


func get_score() -> float:
	return _score


func set_ready_status(grvalue: ReadyStatus) -> void:
	if _ready_status != grvalue:
		_ready_status = grvalue
		
		ready_status_changed.emit()
		changed.emit()


func get_ready_status() -> ReadyStatus:
	return _ready_status


func get_data() -> Dictionary:
	return {
		"score": score,
		"ready_status": ready_status
	}


func parse_data(data: Dictionary) -> void:
	var _has_changed := false
	var _score_changed := false
	var _readyst_changed := false
	if data.has("score"):
		var data_score = data.get("score")
		if (data_score is float or data_score is int) and score != data_score:
			_has_changed = true
			_score_changed = true
			_score = data_score
	if data.has("ready_status"):
		var data_readyst = data.get("ready_status")
		if (data_readyst is int) and ready_status != data_readyst:
			_has_changed = true
			_readyst_changed = true
			_ready_status = data_readyst
	
	if _score_changed:
		score_changed.emit()
	
	if _readyst_changed:
		ready_status_changed.emit()
	
	if _has_changed:
		changed.emit()
