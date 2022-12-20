extends Control

@onready var cSongSelection = preload("res://scenes/song_selection/song_selection.tscn")

@onready var nInstrumentBox_Image = find_child("InstrumentBox/Image")
@onready var nWaitingOpponent = find_child("WaitingOpponent")
@onready var nWaitingOpponent_AnimationPlayer = nWaitingOpponent.find_child("AnimationPlayer")
@onready var nSongSelection: SongSelection = find_child("SongSelection")
@onready var nMatches: Matches = find_child("Matches")

var game_match: NakamaRTAPI.Match
var match_players_count = 0

func _ready():
	GDialogs.open_single(GLoginDialog)
	nSongSelection.connect("item_selected", _on_song_selected)
	
	GBackend.socket.connect("received_match_presence", _on_received_match_presence)

func _on_Create_selected() -> void:
	nSongSelection.show()

func _on_song_selected(p_nSong: SongSelectionItem, p_index: int):
	nSongSelection.hide()
	nMatches.hide()
	nWaitingOpponent.show()
	nWaitingOpponent_AnimationPlayer.play("Default")
	
	game_match = await GBackend.socket.create_match_async("Meowing Cats Room " + str(Time.get_ticks_msec() / 1000))
	print("Match created: #%s - %s" % [game_match.match_id, game_match.label])

func _on_received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent):
	match_players_count += 1
	if match_players_count == 2:
		get_tree().change_scene_to_file("res://scenes/performance.tscn")
