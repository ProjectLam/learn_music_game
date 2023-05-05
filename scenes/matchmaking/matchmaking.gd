extends Control
class_name Matchmaking

@onready var instrument_box := %InstrumentBox
@onready var song_selection: SongSelection = %SongSelection
@onready var nMatches: Matches = %Matches
@onready var create_button = %Create
@onready var popup_bg = %PopupBG
@onready var joining_match_popup = %JoiningMatchPopup
@onready var creating_match_popup = %CreatingMatchPopup

var current_song_index: int = -1

const MatchMakingStatus = MatchManager.MatchMakingStatus

func _ready():
	song_selection.connect("item_played", _on_song_played)
	MatchManager.status_changed.connect(_on_match_status_changed)
	SessionVariables.load_test_song = false
	instrument_box.instrument_data = PlayerVariables.gameplay_instrument_data
	
	refresh()

func _on_Create_selected() -> void:
	song_selection.show()

func _on_song_played(p_nSong: SongSelectionItem):
	print("Selected song for match: ", p_nSong.song.get_identifier())
	
	song_selection.hide()
#	nMatches.hide()
	creating_match_popup.show()
	MatchManager.create_match_async(p_nSong.song)
	
	# TODO : add "creating match" intermediate interface. 
#	nWaitingOpponent_AnimationPlayer.play("Default")
#	nWaitingOpponent.show()
	
	print("Creating Match")


func _switch_to_lobby():
	# TODO : change to lobby scene instead after it's made.
	print("Switching to lobby")
	get_tree().change_scene_to_file("res://scenes/game_lobby/game_lobby.tscn")
	
	# DEPRECATED : this call will be removed in the future.
	SessionVariables.sync_remote()


#func _on_CancelBtn_pressed() -> void:
#	await GBackend.leave_match_async()
#	go_back()


func go_back():
	await MatchManager.leave_match_async()
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")


var prev_match_manager_status := -1
func refresh():
	if not is_inside_tree():
		return
	
	if prev_match_manager_status != MatchManager.status:
		match(MatchManager.status):
			MatchMakingStatus.OFFLINE:
				popup_bg.hide()
				song_selection.hide()
				creating_match_popup.hide()
				create_button.disabled = true
				# TODO : add more OFFLINE interfaces.
			MatchMakingStatus.CONNECTING:
				song_selection.hide()
				popup_bg.hide()
				creating_match_popup.hide()
				joining_match_popup.hide()
				create_button.disabled = true
				# TODO : add more CONNECTING interfaces.
			MatchMakingStatus.IDLE:
				song_selection.hide()
				popup_bg.hide()
				creating_match_popup.hide()
				joining_match_popup.hide()
				create_button.disabled = false
			MatchMakingStatus.JOINING_MATCH:
				song_selection.hide()
				popup_bg.show()
				creating_match_popup.hide()
				joining_match_popup.show()
			MatchMakingStatus.JOINED_MATCH:
				_switch_to_lobby()
			MatchMakingStatus.CREATING_MATCH:
				song_selection.hide()
				popup_bg.show()
				creating_match_popup.show()
				joining_match_popup.hide()
			_:
				push_error("Transition to ", MatchManager.status ," not implemented")
			
	
	prev_match_manager_status = MatchManager.status

func _on_match_status_changed():
	refresh()


func _on_back_selected():
	go_back()


func _on_matches_match_selected(match_id: String) -> void:
	match(MatchManager.status):
		MatchMakingStatus.IDLE:
			await MatchManager.join_match_async(match_id)
		_:
			# TODO : add error popups for this.
			push_error("Invalid status [%s] for joining match [%s]" % [str(MatchManager.status), match_id])
