extends Control

var fake_label := JSON.stringify({
	"name": "some match",
	"instrument": "piano.tres",
	"song": "dum dum dum",
	"game_status": "default",
	"allow_join_after_start": false,
	"password_protected": true,
	"player_limit": 6,
	})

var fake_label_2 := JSON.stringify({
	"name": "some match 2",
	"instrument": "piano.tres",
	"song": "dum dum dum",
	"game_status": "started",
	"allow_join_after_start": false,
	"password_protected": true,
	"player_limit": 2,
	})

var fake_label_3 := JSON.stringify({
	"name": "some match 3",
	"instrument": "piano.tres",
	"song": "dum dum dum",
	"game_status": "default",
	"allow_join_after_start": false,
	"password_protected": false,
	"player_limit": 2,
	})

var fake_matches := {
	"01" : {
		"size": 5,
		"label": fake_label,
	},
#	"02" : {
#		"size": 5,
#		"label": fake_label,
#	},
	"03" : {
		"size": 5,
		"label": fake_label,
	},
	"04" : {
		"size": 1,
		"label": fake_label_2,
	},
#	"05" : {
#		"size": 0,
#		"label": fake_label,
#	},
#	"06" : {
#		"size": 0,
#		"label": fake_label_2,
#	},
}

var fake_periodic_match = {
		"size": 1,
		"label": fake_label_3,
	}

var periodic_match

@onready var matches = %Matches

var fake_apimatchlist: Array[NakamaAPI.ApiMatch] = []

var fakeprop = "ss" :
	set(value):
		fakeprop = value


func _ready():
	GBackend.skip_remote_json_load = true
	GBackend.ui_node.visible = false
	
	periodic_match = NakamaAPI.ApiMatch.new()
	periodic_match._match_id = "022"
	periodic_match._label = fake_periodic_match["label"]
	periodic_match._size = fake_periodic_match["size"]
	periodic_match._authoritative = true
	
	for key in fake_matches:
		var apimatch = NakamaAPI.ApiMatch.new()
		apimatch._match_id = key
		apimatch._label = fake_matches[key]["label"]
		apimatch._size = fake_matches[key]["size"]
		apimatch._authoritative = true
		
		fake_apimatchlist.append(apimatch)
	
	
	matches.fake_apimatchlist = fake_apimatchlist
	matches.fake_apimatchlist2 = fake_apimatchlist.duplicate()
	matches.fake_apimatchlist2.append(periodic_match)
	matches.reload_items()
	

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_F2 and event.pressed:
			add_match()


func add_match() -> void:
	var key = str(fake_apimatchlist.size() + 1)
	var apimatch = NakamaAPI.ApiMatch.new()
	apimatch._match_id = key
	apimatch._label = fake_label
	apimatch._size = 5
	
	fake_apimatchlist.append(apimatch)
	matches.reload_items()

