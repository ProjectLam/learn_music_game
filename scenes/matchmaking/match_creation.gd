@tool
extends Control

class_name MatchCreation

@onready var popup_bg = %PopupBG
@onready var creating_match_popup = %CreatingMatchPopup
@onready var match_create_parameters = %MatchCreateParameters
@onready var song_selection = %SongSelection
@onready var compact_song_preview = %compact_song_preview
@onready var instrument_selection_item = %InstrumentSelectionItem
@onready var instrument_selection_panel = %InstrumentSelectionPanel
@onready var create_match_button = %CreateMatchButton
@onready var join_password = %JoinPassword

var song: Song:
	set = set_song
var instrument_data: InstrumentData:
	set = set_instrument_data

@onready var popups := [
	creating_match_popup
]

enum Modes {
	SINGLE_PLAYER,
	MULTIPLAYER,
	UNDEFINED,
}

var mode_gruops := {
	Modes.SINGLE_PLAYER: "single_player_creation",
	Modes.MULTIPLAYER: "multiplayer_creation",
	Modes.UNDEFINED: "undefined_creation"
}

@export var mode := Modes.SINGLE_PLAYER:
	set = set_mode


func _ready():
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	_parse_scene_stack_vars()
	
	instrument_data = PlayerVariables.gameplay_instrument_data
	
	refresh_match_creation_mode()
	refresh_matchmaking_status()


func _process(delta):
	pass


func _parse_scene_stack_vars():
	var _stack_creation_mode := SceneStack.stack_data.get(SceneStack.MATCH_CREATION_MODE)
	
	if _stack_creation_mode is Modes:
		mode = _stack_creation_mode

var prev_mode := Modes.UNDEFINED
func refresh_match_creation_mode():
	if not is_inside_tree():
		return
	
	if Engine.is_editor_hint():
		return
	
	if prev_mode == mode:
		return
	
	prev_mode = mode
	
	MatchManager.leave_match_async()
	
	for mg in mode_gruops:
		if mg != mode:
			for control in get_tree().get_nodes_in_group(mode_gruops[mg]):
				if control is Control and is_ancestor_of(control):
					control.visible = false
	
	for control in get_tree().get_nodes_in_group(mode_gruops[mode]):
		if control is Control and is_ancestor_of(control):
			control.visible = true
	
	if mode == Modes.MULTIPLAYER:
		if not MatchManager.status_changed.is_connected(refresh_matchmaking_status):
			MatchManager.status_changed.connect(refresh_matchmaking_status)
		
		
	else:
		if MatchManager.status_changed.is_connected(refresh_matchmaking_status):
			MatchManager.status_changed.disconnect(refresh_matchmaking_status)
	

func set_instrument_data(value: InstrumentData) -> void:
	if instrument_data != value:
		instrument_data = value
		instrument_selection_item.instrument_data = instrument_data
		PlayerVariables.gameplay_instrument_data = instrument_data


func _on_create_match_button_pressed():
	match mode:
		Modes.MULTIPLAYER:
			MatchManager.create_match_async(song, join_password.text)
		Modes.SINGLE_PLAYER:
			SessionVariables.instrument = instrument_data.instrument_name
			SessionVariables.current_song = song
			SessionVariables.single_player = true
			SessionVariables.endless = false # TODO : add endless mode.
			get_tree().change_scene_to_file("res://scenes/performance.tscn")
	
	


func _refresh_popup_bg():
	for control in popups:
		if control.visible:
			popup_bg.visible = true
			return
	
	popup_bg.visible = false


func _on_song_selection_song_selected(p_song: Song):
	song = p_song
	compact_song_preview.song = song
	_on_song_selection_go_back()


func _on_song_selection_go_back():
	match_create_parameters.visible = true
	song_selection.visible = false
	instrument_selection_panel.visible = false
	grab_focus()


func _on_compact_song_preview_pressed():
	song_selection.visible = true
	match_create_parameters.visible = false
	instrument_selection_panel.visible = false


func _on_instrument_selection_item_pressed():
	song_selection.visible = false
	match_create_parameters.visible = false
	instrument_selection_panel.visible = true
	instrument_selection_panel.grab_focus()


func _on_instrument_selection_panel_instrument_selected(idata):
	instrument_data = idata
	match_create_parameters.visible = true
	song_selection.visible = false
	instrument_selection_panel.visible = false
	grab_focus()


var prev_status := MatchManager.MatchMakingStatus.OFFLINE
func refresh_matchmaking_status():
	if not is_inside_tree():
		return
	
	if not (mode in [Modes.MULTIPLAYER]):
		for popup in popups:
			popup.visible = false
		
		refresh_create_match_button()
		_refresh_popup_bg()
		return
	
	if prev_status == MatchManager.MatchMakingStatus.CREATING_MATCH \
			and MatchManager.status != MatchManager.MatchMakingStatus.CREATING_MATCH:
				creating_match_popup.hide()
				_refresh_popup_bg()
	
	match(MatchManager.status):
		MatchManager.MatchMakingStatus.IDLE:
			pass
		MatchManager.MatchMakingStatus.JOINED_MATCH:
			get_tree().change_scene_to_file("res://scenes/game_lobby/game_lobby.tscn")
		MatchManager.MatchMakingStatus.CREATING_MATCH:
			creating_match_popup.show()
			_refresh_popup_bg()
		_:
			pass
	
	
	refresh_create_match_button()
	
	prev_status = MatchManager.status


func set_song(value: Song) -> void:
	if song != value:
		song = value
		refresh_create_match_button()


func refresh_create_match_button():
	if not is_inside_tree():
		return
	
	match mode:
		Modes.MULTIPLAYER:
			if song == null:
				create_match_button.disabled = true
				return
			
			if MatchManager.status != MatchManager.MatchMakingStatus.IDLE:
				create_match_button.disabled = true
				return
			
			create_match_button.disabled = false
			return
		
		Modes.SINGLE_PLAYER:
			create_match_button.disabled = song == null
			return
	
	create_match_button.disabled = true


func set_mode(value: Modes):
	if mode != value:
		mode = value
		refresh_match_creation_mode()
