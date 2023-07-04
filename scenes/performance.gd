extends Node3D


@onready var audio_stream: AudioStreamPlayer = $AudioStreamPlayer
@onready var current_song: Song
@onready var ingame_scores_viewer = %IngameScores
@onready var song_loader = %SongLoader
@export var should_print_song_loading_debugs: bool = false
@onready var vfx = %VFX
@onready var chat_box = %ChatBox
@onready var chat_text = %RichTextLabel
@onready var popup_bg = %PopupBG
@onready var loading_song_popup = %LoadingSongPopup
@onready var waiting_for_players_popup = %WaitingForPlayersPopup
@onready var loading_progress_label = %LoadingProgressLabel
@onready var end_match_player_scores = %EndMatchPlayerScores
@onready var match_end_popup = %MatchEndPopup
@onready var restart_match_button = %RestartMatchButton

@onready var popups := [loading_song_popup, waiting_for_players_popup, match_end_popup]

var test_song_path := "res://Arlow - How Do You Know [NCS Release].mp3"

var self_user := IngameUser.new()
var ingame_users := {}
# the state that we intend to go to after the song loads.
var target_ready_state := IngameUser.ReadyStatus.READY

var performance_instrument: PerformanceInstrument:
	set = set_performance_instrument

# seek amount is 1 second for testing.
var seek_amount := 1.0

var is_ready := false
var paused := true:
	set = set_paused


var awaiting_song_load := false:
	set = set_awaiting_song_load

# TODO : we might be waiting for game start but required users might exit the game. add reevaluations.
var awaiting_game_start := false:
	set = set_awaiting_game_start


var match_ended := false

var start_delay := 5.0;

func _ready():
	
	for popup in popups:
		popup.hide()
	
	refresh_popup_bg()
	
	loading_song_popup.visible = awaiting_song_load
	
	
	song_loader.song_loaded.connect(_on_song_loaded)
	
	
	if not SessionVariables.single_player:
		awaiting_game_start = true
		restart_match_button.visible = false
		multiplayer.peer_connected.connect(_on_user_connected)
		multiplayer.peer_disconnected.connect(_on_user_disconnected)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		
		assert(multiplayer.has_multiplayer_peer())
		var cstate = multiplayer.multiplayer_peer.get_connection_status()
		
		if cstate == MultiplayerPeer.CONNECTION_CONNECTED:
			# already connected.
			var user: User = MatchManager.users.dict[multiplayer.get_unique_id()]
			self_user.user = user
			ingame_users[user.user_id] = self_user
			reload_network_users()
		else:
			# we will wait for _on_connected_to_server.
			push_error("After the implementation of game lobby, when entering the game multiplayeAPI should be already connected to server.")
#			ingame_scores_viewer.reload_users({"self": self_user})
	else:
		restart_match_button.visible = true
		ingame_users = { "self": self_user }
		ingame_scores_viewer.reload_users(ingame_users)
	
	SessionVariables.song_changed.connect(_on_song_changed)
	SessionVariables.instrument_changed.connect(_on_instrument_changed)
	
	current_song = SessionVariables.current_song
	
	if current_song == null && SessionVariables.load_test_song:
		awaiting_song_load = true
		var current_stream = song_loader.load_mp3_from_path(test_song_path)
		audio_stream.stream = current_stream
		audio_stream.play()
	
	if SessionVariables.instrument != "":
		var instrument_data := InstrumentList.get_instrument_by_name(SessionVariables.instrument)
		performance_instrument = instrument_data.create_performance_node()

	
	if !is_instance_valid(performance_instrument):
		push_error("Invalid performance instrument")
		# TODO : add error handling.
	add_child(performance_instrument)
	_on_connect_instrument()
	
	_on_song_changed()
	refresh_popup_bg()
	
	is_ready = true


func _process(delta: float) -> void:
	print_debug("A", " : ", get_stack())
	if match_ended:
		return
	
	if Input.is_action_pressed("ui_cancel"):
		MatchManager.leave_match_async()
		get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")
		return
	if Input.is_action_just_pressed("media_pause_play"):
		print("media_pause_play pressed")
		media_pause_play()
	if Input.is_action_just_pressed("media_seek_forward"):
		print("seeking forward by %s seconds" % seek_amount)
		media_seek(true)
	if Input.is_action_just_pressed("media_seek_backward"):
		print("seeking backward by %s seconds" % seek_amount)
		media_seek(false)
	
	if awaiting_song_load:
		var request = song_loader.loading_requests.get(current_song)
		if not is_instance_valid(request) or not request.has_method("get_downloaded_bytes") or not request.has_method("get_total_bytes"):
			loading_progress_label.visible = false
		else:
			var totalbytes: int = request.get_total_bytes()
			var downloaded: int = request.get_downloaded_bytes()
			loading_progress_label.visible = true
			if totalbytes > 0:
				loading_progress_label.text = "%s/%s KB" % [downloaded/1000, totalbytes/1000]
			else:
				loading_progress_label.text = "Fetching..."
	print_debug("B", " : ", get_stack())


func print_song_loading_debug(to_print):
	print_debug("C", " : ", get_stack())
	if should_print_song_loading_debugs:
		print(to_print)
	
	print_debug("D", " : ", get_stack())


func _on_song_changed():
	print_debug("E", " : ", get_stack())
	if match_ended:
		return
	
	self_user.ready_status = IngameUser.ReadyStatus.NOT_READY
	try_sync_user_data()
	current_song = SessionVariables.current_song
	if current_song is Song:
		print("performance song changed to ", current_song.get_identifier())
	else:
		print("performance song changed to none")
	var current_stream:AudioStream
	if current_song:
		awaiting_song_load = true
		song_loader.load_song(current_song)
	else:
		print("No song selected")
	
	print_debug("F", " : ", get_stack())


func _on_song_loaded(song: Song) -> void:
	print_debug("G", " : ", get_stack())
	if match_ended:
		return
	
	if not awaiting_song_load:
		print("Song [%s] loaded." % song.title)
		return
	
	if song != current_song:
		# Not the song we're looking for.
		print("Song [%s] loaded but it's not the intended song." % song.title)
		return
	
	awaiting_song_load = false
	
	audio_stream.stream = song_loader.get_main_stream(song)
	self_user.ready_status = target_ready_state
	try_sync_user_data()
	if is_everyone_ready():
		print("All clients seem to be ready.")
		_on_game_start()
	else:
		if not awaiting_song_load:
			waiting_for_players_popup.show()
			refresh_popup_bg()
	
	print_debug("H", " : ", get_stack())

func is_everyone_ready() -> bool:
	print_debug("J", " : ", get_stack())
	if match_ended:
		return false
	
	if SessionVariables.single_player:
		return self_user.ready_status == IngameUser.ReadyStatus.READY
	
	assert(multiplayer.has_multiplayer_peer())
	
	var cstate = multiplayer.multiplayer_peer.get_connection_status()
	if cstate != MultiplayerPeer.CONNECTION_CONNECTED:
		print("Not connected yet. Cannot check for ready status.")
		return false
	
	# check to see if anybody is not ready
	for uid in ingame_users:
		var iuser: IngameUser = ingame_users[uid]
		if iuser.ready_status != IngameUser.ReadyStatus.READY:
			print_debug("K1", " : ", get_stack())
			return false
	
	print_debug("K2", " : ", get_stack())
	return true  


func _on_game_start():
	print_debug("L", " : ", get_stack())
	if match_ended:
		return
	
	print("Starting game")
	awaiting_game_start = false
	sync_audiostream_remote(true, -start_delay)
	print_debug("M", " : ", get_stack())


func sync_audiostream_remote(p_playing: bool, p_seek):
	print_debug("N", " : ", get_stack())
	if match_ended:
		return
	
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		rpc("_sync_audiostream_remote", p_playing, p_seek, -1)
	else:
		_seek(p_seek)
		paused = not p_playing
	
	print_debug("O", " : ", get_stack())

func set_paused(value: bool) -> void:
	print_debug("P", " : ", get_stack())
	if paused != value:
		paused = value
		_seek(performance_instrument.notes.time)
#		performance_instrument.notes.paused = paused
	print_debug("Q", " : ", get_stack())


func is_music_playing() -> bool:
	print_debug("R", " : ", get_stack())
	return not paused


# The current play/pause mechanism is designed in a way that if there are any conflicts in the 
# play/pause state, then the clients will try to relay pause requests to each other so that 
# everyone ends up pausing. 
@rpc("any_peer", "call_local", "reliable") func _sync_audiostream_remote(p_playing: bool, p_seek: float, relay_source):
	print_debug("S", " : ", get_stack())
	if match_ended:
		return
	if multiplayer.get_unique_id() == relay_source:
		return
	if is_music_playing() == p_playing:
		# do nothing.
		_seek(p_seek)
		return
	else:
		if(p_playing):
			if not is_everyone_ready():
				print("Ignoring stream sync. Not everyone is ready.")
				# Probably everyone is ready but we don't know that yet.
				# TODO : Add more handling
				return
			paused = false 
			_seek(p_seek)
#			audio_stream.play(p_seek)
		else:
			paused = true
			_seek(p_seek)
			if multiplayer.get_unique_id() != multiplayer.get_remote_sender_id():
				# relay pause command to sychronize state.
				rpc("_sync_audiostream_remote", p_playing, p_seek, multiplayer.get_remote_sender_id())
	print_debug("T", " : ", get_stack())


func _on_instrument_changed():
	print_debug("U", " : ", get_stack())
	if match_ended:
		return
	
	print_debug("V", " : ", get_stack())
	if performance_instrument:
		push_error("Changing performance instrument mid game is unsupported")
		return
	
	print_debug("W", " : ", get_stack())
	if not is_ready:
		return
	
	print_debug("X", " : ", get_stack())
	var instrument_data := InstrumentList.get_instrument_by_name(SessionVariables.instrument)
	performance_instrument = instrument_data.create_performance_node()
	add_child(performance_instrument)
	_on_connect_instrument()
	print_debug("Y", " : ", get_stack())


func _seek(time: float = 0):
	print_debug("Z", " : ", get_stack())
	if match_ended:
		return
	
	if not paused:
		if is_instance_valid(performance_instrument):
			performance_instrument.start_game(current_song)
			performance_instrument.notes.paused = false
			performance_instrument.seek(time)
	else:
		performance_instrument.start_game(current_song)
		performance_instrument.seek(time)
		performance_instrument.notes.paused = true
	
	print_debug("A2", " : ", get_stack())
	


# performs a pause/play action.
func media_pause_play():
	print_debug("B2", " : ", get_stack())
	if match_ended:
		return
	
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			sync_audiostream_remote(not is_music_playing(), audio_stream.get_playback_position())
			return
	
	paused = is_music_playing()
	print_debug("C2", " : ", get_stack())
#	_seek(audio_stream.get_playback_position())


func media_seek(forward: bool) -> void:
	print_debug("D2", " : ", get_stack())
	if match_ended:
		return
	
	var _seek := seek_amount
	if not forward:
		_seek *= -1
	var final_time := audio_stream.get_playback_position()
	if is_instance_valid(performance_instrument):
		final_time = performance_instrument.notes.time
	final_time += _seek
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			sync_audiostream_remote(is_music_playing(), final_time)
			return
	
	_seek(final_time)
	print_debug("E2", " : ", get_stack())


func _on_QuitBtn_pressed() -> void:
	print_debug("F2", " : ", get_stack())
	await GBackend.leave_match_async()
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")
	print_debug("G2", " : ", get_stack())


func _exit_tree():
	print_debug("H2", " : ", get_stack())
	performance_instrument = null


func _on_pause_play_button_pressed():
	print_debug("J2", " : ", get_stack())
	if match_ended:
		return
	
	media_pause_play()
	print_debug("K2", " : ", get_stack())


# returns an array of all user identifiers.
func get_all_network_users() -> Array[User]:
	print_debug("R2", " : ", get_stack())
	var users: PackedInt32Array = multiplayer.get_peers()
	users.append(multiplayer.get_unique_id())
	var ret: Array[User]
	ret.resize(users.size())
	for index in users.size():
		var user: User = MatchManager.users.dict[users[index]]
		ret[index] = user
	
	print_debug("S2", " : ", get_stack())
	return ret


func reload_network_users():
	print_debug("T2", " : ", get_stack())
	var users := get_all_network_users()
	for iuser in users:
		if not ingame_users.has(iuser.user_id):
			_add_new_user(iuser)
	ingame_scores_viewer.reload_users(ingame_users)
	print_debug("U2", " : ", get_stack())


func _add_new_user(user: User) -> IngameUser:
	print_debug("V2", " : ", get_stack())
	var new_iuser = IngameUser.new()
	# add entry
	ingame_users[user.user_id] = new_iuser
	new_iuser.user = user
	# reload ui.
	ingame_scores_viewer.reload_users(ingame_users)
	new_iuser.ready_status_changed.connect(_on_users_ready_changed)
	print_debug("W2", " : ", get_stack())
	return new_iuser


func try_pause_game() -> void:
	print_debug("X2", " : ", get_stack())
	if match_ended:
		return
	
	if is_music_playing():
		sync_audiostream_remote(false, 0.0)
	
	print_debug("Y2", " : ", get_stack())


func _on_users_ready_changed() -> void:
	print_debug("Z2", " : ", get_stack())
	if match_ended:
		return
	
	print("Users ready status changed.")
	if is_everyone_ready():
		_on_game_start()
	else:
		try_pause_game()
	
	print_debug("A3", " : ", get_stack())


func _on_user_connected(peer_id: int):
	print_debug("A4", " : ", get_stack())
	if match_ended:
		return
	
	reload_network_users()
	if is_multiplayer_authority():
		var udata := {}
		for iuser in ingame_users:
			udata[iuser] = iuser.get_data()
		rpc("_set_all_user_data", udata)
	
	var user: User = MatchManager.users.dict[peer_id]
	# ui notification to let us know a user has connected.
	add_chat_notification("%s connected." % user.username)
	
	print_debug("A5", " : ", get_stack())


func _on_user_disconnected(peer_id: int):
	print_debug("A6", " : ", get_stack())
	reload_network_users()
	
	var user: User = MatchManager.users.dict.get(peer_id)
	if not user:
		user = MatchManager.users_old.dict.get(peer_id)
	add_chat_notification("%s disconnected" % user.username)
	
	if peer_id == get_multiplayer_authority():
		# TODO :
		# multiplayer authority has disconnected. this is a problem till we design a full authoritative model.
		push_error("Host disconnected. State not implemented.")
		MatchManager.leave_match_async()
	
	print_debug("A7", " : ", get_stack())


func _on_server_disconnected() -> void:
	print_debug("A8", " : ", get_stack())
	if match_ended:
		return
	
	print_debug("A9", " : ", get_stack())
	# TODO
	pass


func _on_connected_to_server() -> void:
	print_debug("A10", " : ", get_stack())
	if match_ended:
		return
	
	var user: User = MatchManager.users.dict[multiplayer.get_unique_id()]
	ingame_users[user.user_id] = self_user
	reload_network_users()
	print_debug("A11", " : ", get_stack())


func update_user_data(uid: String) -> void:
	print_debug("A12", " : ", get_stack())
	if match_ended:
		return
	
	# user data for has changed.
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc("_set_user_data", self_user.get_data())
	
	print_debug("A13", " : ", get_stack())


func broadcast_all_user_data() -> void:
	print_debug("A14", " : ", get_stack())
	if match_ended:
		return
	
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print("Broadcasting all user data")
			var udata := {}
			for iuser in ingame_users:
				udata[iuser] = iuser.get_data()
			rpc("_set_all_user_data", udata)
	
	print_debug("A15", " : ", get_stack())


@rpc("authority", "call_remote", "reliable") func _set_all_user_data(data) -> void:
	print_debug("A16", " : ", get_stack())
	print("rpc _set_all_user_data called by {%s} with {%s}" % [multiplayer.get_remote_sender_id(), data])
	var suser: User = MatchManager.users.dict[multiplayer.get_unique_id()]
	for key in data:
		if not (key is String):
			# invalid key
			push_error("invalid user key %s" % key)
			continue
		var iuser: IngameUser
		if ingame_users.has(key):
			iuser = ingame_users[key]
		elif key == suser.user_id:
			ingame_users[key] = self_user
			iuser = self_user
		else:
			iuser = _add_new_user(key)
		
		var udata = data[key]
		if not (udata is Dictionary):
			# invalid user data
			push_error("invalid user data %s" % udata)
			continue
		iuser.parse_data(udata)
	ingame_scores_viewer.reload_users(ingame_users)
	end_match_player_scores.reload_users(ingame_users)
	
	print_debug("A17", " : ", get_stack())


@rpc("any_peer", "call_remote", "reliable") func _set_user_data(data) -> void:
	print_debug("A19", " : ", get_stack())
	print("received remote _set_user_data call with [id = %d, data = %s]" % 
			[multiplayer.get_remote_sender_id(), data])
	
	var suser: User = MatchManager.users.dict[multiplayer.get_remote_sender_id()]
	var uid :String = suser.user_id
	if not (data is Dictionary):
		push_error("invalid user data for uid [%s]" % uid)
		return
	if not ingame_users.has(uid):
		push_warning("something went wrong, non existing user is sending data")
		return
	ingame_users[uid].parse_data(data)
	ingame_scores_viewer.reload_users(ingame_users)
	end_match_player_scores.reload_users(ingame_users)


func _on_connect_instrument() -> void:
	print_debug("A20", " : ", get_stack())
	if match_ended:
		return
	
	if performance_instrument:
		performance_instrument.notes.good_note_started.connect(_on_good_note_started)
	
	print_debug("A21", " : ", get_stack())


func try_sync_user_data() -> void:
	print_debug("A22", " : ", get_stack())
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc("_set_user_data", self_user.get_data())
	
	print_debug("A23", " : ", get_stack())


func _on_good_note_started(note_index: int, time_error: float) -> void:
	
	print_debug("A24", " : ", get_stack())
	if match_ended:
		return
	
	self_user._on_good_note(note_index, time_error)
	try_sync_user_data()
	
	print_debug("A25", " : ", get_stack())


# temporary unique user id generator. will be replaced with a user id system.
#func get_user_id(peer_id: int) -> String:
#	var username: String = MatchManager.get_peer_user_id(peer_id)
#	if username != "":
#		return username
#	else:
#		# TODO : this changes the username of the users that have left.
#		#  add a global profile cache for user profiles and use that for usernames.
#		return "user_%s" % peer_id
		


func add_chat_notification(message: String) -> void:
	print_debug("A26", " : ", get_stack())
	chat_text.text += "\n%s" % message
	chat_box.refresh()
	print_debug("A27", " : ", get_stack())


func refresh_popup_bg():
	print_debug("A28", " : ", get_stack())
	if not is_inside_tree():
		return
	
	for control in popups:
		if control.visible:
			popup_bg.visible = true
			return
	
	popup_bg.visible = false
	print_debug("A29", " : ", get_stack())


func set_awaiting_song_load(value: bool) -> void:
	print_debug("A30", " : ", get_stack())
	if match_ended:
		return
	
	if awaiting_song_load != value:
		awaiting_song_load = value
		if is_instance_valid(loading_song_popup):
			loading_song_popup.visible = awaiting_song_load
			if not awaiting_song_load and awaiting_game_start:
				waiting_for_players_popup.show()
			refresh_popup_bg()
	
	print_debug("A31", " : ", get_stack())


func set_awaiting_game_start(value: bool) -> void:
	print_debug("A32", " : ", get_stack())
	if match_ended:
		return
	
	if awaiting_game_start != value:
		awaiting_game_start = value
		
		if is_instance_valid(waiting_for_players_popup):
			if awaiting_game_start:
				if not awaiting_song_load and awaiting_game_start:
					waiting_for_players_popup.show()
					refresh_popup_bg()
			else:
				waiting_for_players_popup.hide()
				refresh_popup_bg()
	
	print_debug("A33", " : ", get_stack())


func _on_performance_song_started() -> void:
	print_debug("A34", " : ", get_stack())
	if match_ended:
		return
	if current_song:
		if performance_instrument.get_audio_time() > audio_stream.stream.get_length():
			audio_stream.stream_paused = true
		else:
			audio_stream.play(performance_instrument.get_audio_time())
	
	print_debug("A35", " : ", get_stack())


func _on_performance_song_paused() -> void:
	print_debug("A36", " : ", get_stack())
	audio_stream.stream_paused = true


func set_performance_instrument(value) -> void:
	print_debug("A37", " : ", get_stack())
	if match_ended:
		return
	
	if performance_instrument != value:
		if performance_instrument:
			if performance_instrument.song_paused.is_connected(_on_performance_song_paused):
				performance_instrument.song_paused.disconnect(_on_performance_song_paused)
			if performance_instrument.song_started.is_connected(_on_performance_song_started):
				performance_instrument.song_started.disconnect(_on_performance_song_started)
		performance_instrument = value
		
		if performance_instrument:
			performance_instrument.song_paused.connect(_on_performance_song_paused)
			performance_instrument.song_started.connect(_on_performance_song_started)
	
	print_debug("A38", " : ", get_stack())

func _on_song_end_reached() -> void:
	print_debug("A29", " : ", get_stack())
	if SessionVariables.endless:
		# do nothing.
		return
	
	match_ended = true
	
	self_user.ready_status = IngameUser.ReadyStatus.ENDED_PLAYING
	try_sync_user_data()
	
	for popup in popups:
		if popup != match_end_popup:
			popup.visible = false
	
	match_end_popup.show()
	
	refresh_popup_bg()
	
	end_match_player_scores.reload_users(ingame_users)
	print_debug("A40", " : ", get_stack())


func _on_audio_stream_player_finished():
	print_debug("A41", " : ", get_stack())
	if not paused:
		_on_song_end_reached()
	print_debug("A42", " : ", get_stack())
	
#	_on_song_changed() you can call this to restart the match. not sure if it's the best option.


func restart_match():
	print_debug("A43", " : ", get_stack())
	if SessionVariables.single_player:
		match_ended = false
		match_end_popup.hide()
		refresh_popup_bg()
		
		self_user.score = 0
		self_user.ready_status = IngameUser.ReadyStatus.READY
		_seek(-start_delay)
		
		ingame_scores_viewer.reload_users(ingame_users)
	else:
		push_error("Match restart for multiplayer not implemented yet.")
	
	print_debug("A44", " : ", get_stack())


func _on_restart_match_button_pressed():
	print_debug("A45", " : ", get_stack())
	restart_match()
	print_debug("A46", " : ", get_stack())
