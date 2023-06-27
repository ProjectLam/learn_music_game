extends "res://scenes/matches/matches.gd"

var fake_apimatchlist: Array[NakamaAPI.ApiMatch] = []
var fake_apimatchlist2: Array[NakamaAPI.ApiMatch] = []

func _ready():
	focus_entered.connect(_on_focus_entered)
	
	
	refresh_matches()


var counter := 0
func reload_items():
	counter += 1
	if counter % 2 == 0:
		last_match_list = NakamaAPI.ApiMatchList.new()
		last_match_list._matches = fake_apimatchlist
		_reload_items(last_match_list)
	else:
		last_match_list = NakamaAPI.ApiMatchList.new()
		last_match_list._matches = fake_apimatchlist2
		_reload_items(last_match_list)
	
