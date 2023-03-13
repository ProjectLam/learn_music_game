extends "res://scenes/matches/matches.gd"

var fake_apimatchlist: Array[NakamaAPI.ApiMatch] = []

func _ready():
	focus_entered.connect(_on_focus_entered)
	
	
	_on_refresh_timer_timeout()


func reload_items():
	_reload_items(fake_apimatchlist)
	
