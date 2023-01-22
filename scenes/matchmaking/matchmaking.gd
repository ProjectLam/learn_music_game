extends Control
class_name Matchmaking

@onready var instrument_box := %InstrumentBox
@onready var nWaitingOpponent = %WaitingOpponent
@onready var nWaitingOpponent_AnimationPlayer = %AnimationPlayer
@onready var nSongSelection: SongSelection = %SongSelection
@onready var nMatches: Matches = %Matches

var current_song_index: int = -1

func _ready():
	nSongSelection.connect("item_played", _on_song_played)
	GBackend.received_match_state.connect(_on_received_match_state)
	GBackend.peer_connected.connect(_on_peer_connected)
	SessionVariables.load_test_song = false
	instrument_box.instrument_data = PlayerVariables.gameplay_instrument_data

func _on_Create_selected() -> void:
	nSongSelection.show()

func _on_song_played(p_nSong: SongSelectionItem):
	print("Selected song for match: ", p_nSong.song.get_identifier())
	
	SessionVariables.current_song = p_nSong.song
	
	nSongSelection.hide()
	nMatches.hide()
	nWaitingOpponent.show()
	nWaitingOpponent_AnimationPlayer.play("Default")
	
	await GBackend.create_match_async()

#	print("Match created: #%s - %s" % [GBackend.current_match.match_id, GBackend.current_match.label])
	# TODO : change this when match naming is implemented.
	print("Match created")

func _on_peer_connected(peer_id : int):
	# Client Relayed Multiplayer, not data maintained on the backend.
	# Note : multiplayer api calls should not be called during 'received_match_presence'. But they 
	# can be called during 'peer_connected'.
	SessionVariables.instrument = PlayerVariables.gameplay_instrument_name
	get_tree().change_scene_to_file("res://scenes/performance.tscn")
	SessionVariables.sync_remote()
	

func _on_BackBtn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")

func _on_CancelBtn_pressed() -> void:
	await GBackend.leave_async()
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")

func _on_received_match_state(p_state):
	print("Received match state: ", p_state)
