extends Control

var fake_label := JSON.stringify({
	"name": "some match",
	"instrument": "piano.tres",
	"song": "dum dum dum",
	})

var fake_matches := {
	"01" : {
		"size": 5,
		"label": fake_label,
	},
	"02" : {
		"size": 5,
		"label": fake_label,
	},
	"03" : {
		"size": 5,
		"label": fake_label,
	},
}

@onready var matches = %Matches

var fake_apimatchlist: Array[NakamaAPI.ApiMatch] = []

var fakeprop = "ss" :
	set(value):
		fakeprop = value


func _ready():
	GBackend.skip_remote_json_load = true
	GBackend.ui_node.visible = false
	
	for key in fake_matches:
		var apimatch = NakamaAPI.ApiMatch.new()
		apimatch._match_id = key
		apimatch._label = fake_matches[key]["label"]
		apimatch._size = fake_matches[key]["size"]
		
		fake_apimatchlist.append(apimatch)
	matches.fake_apimatchlist = fake_apimatchlist
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

