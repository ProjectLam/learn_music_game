extends Control
class_name Matchmaking

@onready var instrument_box := %InstrumentBox
@onready var matches: Matches = %Matches
@onready var create_button = matches.create_match_button
@onready var popup_bg = %PopupBG
@onready var joining_match_popup = %JoiningMatchPopup
@onready var join_failed_popup = %JoinFailedPopup
@onready var join_failed_label = %JoinFailedLabel
@onready var join_password_popup = %JoinPasswordPopup
@onready var join_password = %JoinPassword

@onready var popups := [joining_match_popup, join_failed_popup, join_password_popup]

var current_song_index: int = -1
var last_join_attempt_match_id: String = ""
const MatchMakingStatus = MatchManager.MatchMakingStatus

func _ready():
	MatchManager.status_changed.connect(_on_match_status_changed)
	SessionVariables.load_test_song = false
	instrument_box.instrument_data = PlayerVariables.gameplay_instrument_data
	
	refresh()


func _process(delta):
	if join_password_popup.visible:
		if not matches.has_match(last_join_attempt_match_id):
			last_join_attempt_match_id = ""
			join_failed_label.text = "Match no longer available."
			show_popup(join_failed_label)


func show_popup(popup_node: Node):
	for popup in popups:
		if popup != popup_node:
			popup.visible = false
	popup_node.visible = true
	popup_bg.visible = true


func _switch_to_lobby():
	# TODO : change to lobby scene instead after it's made.
	print("Switching to lobby")
	get_tree().change_scene_to_file("res://scenes/game_lobby/game_lobby.tscn")
	
#	# DEPRECATED : this call will be removed in the future.
#	SessionVariables.sync_remote()


func go_back():
	MatchManager.leave_match_async()
	SceneStack.go_back()


var prev_match_manager_status := -1
func refresh():
	if not is_inside_tree():
		return
	
	if prev_match_manager_status != MatchManager.status:
		match(MatchManager.status):
			MatchMakingStatus.OFFLINE:
				create_button.disabled = true
				# TODO : add more OFFLINE interfaces.
			MatchMakingStatus.CONNECTING:
				if join_password_popup.visible:
					# TODO : see if this overlaps with any other connection failure popup.
					join_failed_label = "Connection failure!"
					show_popup(join_failed_popup)
				create_button.disabled = true
				# TODO : add more CONNECTING interfaces.
			MatchMakingStatus.IDLE:
				joining_match_popup.hide()
				create_button.disabled = false
			MatchMakingStatus.JOINING_MATCH:
				show_popup(joining_match_popup)
			MatchMakingStatus.JOINED_MATCH:
				_switch_to_lobby()
			_:
				push_error("Transition to ", MatchManager.status ," not implemented")
	
	refresh_popup_bg()
	prev_match_manager_status = MatchManager.status

func _on_match_status_changed():
	refresh()


func _on_back_selected():
	go_back()


func refresh_popup_bg():
	for popup in popups:
		if popup.visible:
			popup_bg.visible
			return
	
	popup_bg.visible = false


func _on_matches_match_selected(match_id: String) -> void:
	match(MatchManager.status):
		MatchMakingStatus.IDLE:
			await MatchManager.join_match_async(match_id)
		_:
			# TODO : add error popups for this.
			push_error("Invalid status [%s] for joining match [%s]" % [str(MatchManager.status), match_id])


func _on_matches_create_match_pressed():
	SceneStack.stack.append("res://scenes/matchmaking/matchmaking.tscn")
	SceneStack.stack_data[SceneStack.MATCH_CREATION_MODE] = MatchCreation.Modes.MULTIPLAYER
	get_tree().change_scene_to_file("res://scenes/matchmaking/match_creation.tscn")


func _on_matches_join_not_allowed(message):
	# TODO : add popup
	pass


func _on_matches_protected_match_selected(match_id):
	last_join_attempt_match_id = match_id
	join_password.text = ""
	show_popup(join_password_popup)


func _on_join_failed_ok_button_pressed():
	join_failed_popup.hide()
	refresh_popup_bg()


func _on_join_password_close_button_pressed():
	last_join_attempt_match_id = ""
	join_password_popup.hide()
	refresh_popup_bg()


func _on_join_password_join_button_pressed():
	var jpass: String = join_password.text
	var match_id = last_join_attempt_match_id
	join_password_popup.hide()
	refresh_popup_bg()
	last_join_attempt_match_id = ""
	match(MatchManager.status):
		MatchMakingStatus.IDLE:
			await MatchManager.join_match_async(match_id, jpass)
		_:
			# TODO : add error popups for this.
			push_error("Invalid status [%s] for joining match [%s]" % [str(MatchManager.status), match_id])
