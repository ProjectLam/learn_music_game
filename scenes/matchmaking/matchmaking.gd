extends Control
class_name Matchmaking

enum STATES {
	INIT
}

@onready var nInstrumentBox_Image = find_child("InstrumentBox/Image")
@onready var nWaitingOpponent = find_child("WaitingOpponent")
@onready var nWaitingOpponent_AnimationPlayer = nWaitingOpponent.find_child("AnimationPlayer")
@onready var nSongSelection: SongSelection = find_child("SongSelection")
@onready var nMatches: Matches = find_child("Matches")

var game_match: NakamaRTAPI.Match
var match_players_count = 0

var current_song_index: int = -1

func _ready():
	nSongSelection.connect("item_played", _on_song_played)
	GBackend.socket.connect("received_match_presence", _on_received_match_presence)
	GBackend.socket.connect("received_match_state", _on_received_match_state)

func _on_Create_selected() -> void:
	nSongSelection.show()

func _on_song_played(p_nSong: SongSelectionItem, p_index: int):
	print("Selected song for match: ", p_nSong.song.file_name)
	
	current_song_index = p_index
	PlayerVariables.current_song = PlayerVariables.songs[current_song_index]
	
	nSongSelection.hide()
	nMatches.hide()
	nWaitingOpponent.show()
	nWaitingOpponent_AnimationPlayer.play("Default")
	
	game_match = await GBackend.socket.create_match_async("Meowing Cats Room " + str(Time.get_ticks_msec() / 1000))
	print("Match created: #%s - %s" % [game_match.match_id, game_match.label])

func _on_received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent):
	match_players_count += 1
	if match_players_count == 2:
		GBackend.socket.send_match_state_async(game_match.match_id, STATES.INIT, JSON.stringify({
			song = {
				title = PlayerVariables.current_song.title
			}
		}))
		get_tree().change_scene_to_file("res://scenes/performance.tscn")

func _on_BackBtn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")

func _on_CancelBtn_pressed() -> void:
	await GBackend.socket.leave_match_async(game_match.match_id)
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")

func _on_received_match_state(p_state):
	print("Received match state: ", p_state)
