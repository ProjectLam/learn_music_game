extends Node3D


@onready var audio_stream: AudioStreamPlayer = $AudioStreamPlayer
@onready var current_song: Song
@onready var ingame_scores_viewer = %IngameScores
@onready var song_loader = %SongLoader
@export var should_print_song_loading_debugs: bool = false
@onready var vfx = %VFX
@onready var chat_box = %ChatBox
@onready var chat_text = %RichTextLabel

var test_song_path := "res://Arlow - How Do You Know [NCS Release].mp3"

var self_user := IngameUser.new()
var ingame_users := {}
# the state that we intend to go to after the song loads.
var target_ready_state := IngameUser.ReadyStatus.READY

var performance_instrument: PerformanceInstrument

var is_ready := false


func _ready():
	multiplayer.peer_connected.connect(_on_user_connected)
	multiplayer.peer_disconnected.connect(_on_user_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	song_loader.song_loaded.connect(_on_song_loaded)
	
	
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		var cstate = multiplayer.multiplayer_peer.get_connection_status()
		if cstate == MultiplayerPeer.CONNECTION_CONNECTED:
			ingame_users[get_user_id(multiplayer.get_unique_id())] = self_user
			reload_network_users()
		else:
			ingame_scores_viewer.reload_users({"self": self_user})
	else:
		ingame_scores_viewer.reload_users({"self": self_user})
	
	SessionVariables.song_changed.connect(_on_song_changed)
	SessionVariables.instrument_changed.connect(_on_instrument_changed)
	
	current_song = SessionVariables.current_song
	
	if current_song == null && SessionVariables.load_test_song:
		var current_stream = song_loader.load_mp3_from_path(test_song_path)
		audio_stream.stream = current_stream
		audio_stream.play()
	
	if SessionVariables.instrument != "":
		var instrument_data := InstrumentList.get_instrument_by_name(SessionVariables.instrument)
		performance_instrument = instrument_data.performance_scene.instantiate()

	
	if !is_instance_valid(performance_instrument):
		push_error("Invalid performance instrument")
		# TODO : add error handling.
	add_child(performance_instrument)
	_on_connect_instrument()
	
	_on_song_changed()
	
	is_ready = true


func print_song_loading_debug(to_print):
	if should_print_song_loading_debugs:
		print(to_print)


func _on_song_changed():
	self_user.ready_status = IngameUser.ReadyStatus.NOT_READY
	try_sync_user_data()
	current_song = SessionVariables.current_song
	if current_song is Song:
		print("performance song changed to ", current_song.get_identifier())
	else:
		print("performance song changed to none")
	var current_stream:AudioStream
	if current_song:
		song_loader.load_song(current_song)
	else:
		print("No song selected")


func _on_song_loaded(song: Song) -> void:
	if song != current_song:
		# Not the song we're looking for.
		print("Song [%s] loaded but it's not the intended song." % song.title)
		return
	
	audio_stream.stream = song_loader.get_main_stream(song)
	self_user.ready_status = target_ready_state
	try_sync_user_data()
	if is_everyone_ready():
		print("All clients seem to be ready.")
		_on_game_start()


func is_everyone_ready() -> bool:
	if SessionVariables.single_player:
		return self_user.ready_status == IngameUser.ReadyStatus.READY
	
	assert(multiplayer.has_multiplayer_peer())
	
	var cstate = multiplayer.multiplayer_peer.get_connection_status()
	if cstate != MultiplayerPeer.CONNECTION_CONNECTED:
		print("Not connected yet. Cannot check for ready status.")
		return false
	
	# check to see if anybody is ready
	for uid in ingame_users:
		var iuser: IngameUser = ingame_users[uid]
		if iuser.ready_status != IngameUser.ReadyStatus.READY:
			return false
	
	return true  


func _on_game_start():
	print("Starting game")
	sync_audiostream_remote(true, 0.0)


func sync_audiostream_remote(p_playing: bool, p_seek):
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		rpc("_sync_audiostream_remote", p_playing, p_seek, -1)
	else:
		if p_playing:
			audio_stream.play(p_seek)
			if is_instance_valid(performance_instrument) and p_seek == 0:
				# TODO : there is an issue with browser not allowing music to play unless the tab is clicked on.
				performance_instrument.start_game(current_song)
		else:
			audio_stream.stream_paused = true

func is_music_playing() -> bool:
	return audio_stream.playing


# The current play/pause mechanism is designed in a way that if there are any conflicts in the 
# play/pause state, then the clients will try to relay pause requests to each other so that 
# everyone ends up pausing. 
@rpc("any_peer", "call_local", "reliable") func _sync_audiostream_remote(p_playing: bool, p_seek: float, relay_source):
	if multiplayer.get_unique_id() == relay_source:
		return
	if is_music_playing() == p_playing:
		# do nothing.
		return
	else:
		if(p_playing):
			if not is_everyone_ready():
				print("Ignoring stream sync. Not everyone is ready.")
				# Probably everyone is ready but we don't know that yet.
				return
			audio_stream.play(p_seek)
			# TODO : add notes seeking
			if is_instance_valid(performance_instrument) and p_seek == 0:
				performance_instrument.start_game(current_song)
		else:
			audio_stream.stream_paused = true
			if multiplayer.get_unique_id() != multiplayer.get_remote_sender_id():
				# relay pause command to sychronize state.
				rpc("_sync_audiostream_remote", p_playing, p_seek, multiplayer.get_remote_sender_id())


func _on_instrument_changed():
	if performance_instrument:
		push_error("Changing performance instrument mid game is unsupported")
		return
	
	if not is_ready:
		return
	
	var instrument_data := InstrumentList.get_instrument_by_name(SessionVariables.instrument)
	performance_instrument = instrument_data.performance_scene.instantiate()
	add_child(performance_instrument)
	_on_connect_instrument()


func is_playing() -> bool:
	return audio_stream.playing


func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")
		return
	if Input.is_action_just_pressed("media_pause_play"):
		print("media_pause_play pressed")
		media_pause_play()


func media_pause_play():
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			if is_playing():
				sync_audiostream_remote(false, audio_stream.get_playback_position())
			else:
				sync_audiostream_remote(true, audio_stream.get_playback_position())
			return
	
	if is_playing():
		audio_stream.stream_paused = true
	else:
		audio_stream.stream_paused = false
		if not is_playing():
			audio_stream.play()


func _on_QuitBtn_pressed() -> void:
	await GBackend.leave_async()
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")


func _exit_tree():
	performance_instrument = null


func _on_pause_play_button_pressed():
	media_pause_play()


# returns an array of all user identifiers.
func get_all_network_users() -> PackedStringArray:
	var users: PackedInt32Array = multiplayer.get_peers()
	users.append(multiplayer.get_unique_id())
	var ret: PackedStringArray
	ret.resize(users.size())
	for index in users.size():
		ret[index] = get_user_id(users[index])
	return ret


func reload_network_users():
	var users := get_all_network_users()
	for iuser in users:
		if not ingame_users.has(iuser):
			_add_new_user(iuser)
	ingame_scores_viewer.reload_users(ingame_users)


func _add_new_user(uid) -> IngameUser:
	var new_iuser = IngameUser.new()
	ingame_users[uid] = new_iuser
	ingame_scores_viewer.reload_users(ingame_users)
	new_iuser.ready_status_changed.connect(_on_users_ready_changed)
	return new_iuser


func try_pause_game() -> void:
	if is_music_playing():
		sync_audiostream_remote(false, 0.0)


func _on_users_ready_changed() -> void:
	print("Users ready status changed.")
	if is_everyone_ready():
		_on_game_start()
	else:
		try_pause_game()


func _on_user_connected(peer_id: int):
	reload_network_users()
	if is_multiplayer_authority():
		var udata := {}
		for iuser in ingame_users:
			udata[iuser] = iuser.get_data()
		rpc("_set_all_user_data", udata)
	add_chat_notification("%s connected." % get_user_id(peer_id))


func _on_user_disconnected(peer_id: int):
	reload_network_users()
	add_chat_notification("%s disconnected" % get_user_id(peer_id))


func _on_server_disconnected() -> void:
	# TODO
	pass


func _on_connected_to_server() -> void:
	ingame_users[get_user_id(multiplayer.get_unique_id())] = self_user
	reload_network_users()


func update_user_data(uid: String) -> void:
	# user data for has changed.
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc("_set_user_data", self_user.get_data())


func broadcast_all_user_data() -> void:
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print("Broadcasting all user data")
			var udata := {}
			for iuser in ingame_users:
				udata[iuser] = iuser.get_data()
			rpc("_set_all_user_data", udata)


@rpc("authority", "call_remote", "reliable") func _set_all_user_data(data) -> void:
	print("rpc _set_all_user_data called by {%s} with {%s}" % [multiplayer.get_remote_sender_id(), data])
	for key in data:
		if not (key is String):
			# invalid key
			push_error("invalid user key %s" % key)
			continue
		var iuser: IngameUser
		if ingame_users.has(key):
			iuser = ingame_users[key]
		elif key == get_user_id(multiplayer.get_unique_id()):
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


@rpc("any_peer", "call_remote", "reliable") func _set_user_data(data) -> void:
	print("received remote _set_user_data call with [id = %d, data = %s]" % 
			[multiplayer.get_remote_sender_id(), data])
	var uid :String = get_user_id(multiplayer.get_remote_sender_id())
	if not (data is Dictionary):
		push_error("invalid user data for uid [%s]" % uid)
		return
	if not ingame_users.has(uid):
		push_warning("something went wrong, non existing user is sending data")
		return
	ingame_users[uid].parse_data(data)
	ingame_scores_viewer.reload_users(ingame_users)


func _on_connect_instrument() -> void:
	if performance_instrument:
		performance_instrument.notes.good_note_started.connect(_on_good_note_started)


func try_sync_user_data() -> void:
	if not SessionVariables.single_player:
		assert(multiplayer.has_multiplayer_peer())
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc("_set_user_data", self_user.get_data())

func _on_good_note_started(note_index: int, time_error: float) -> void:
	self_user._on_good_note(note_index, time_error)
	try_sync_user_data()


# temporary unique user id generator. will be replaced with a user id system.
func get_user_id(peer_id: int) -> String:
	var username: String = GBackend.multiplayer_bridge.get_peer_username(peer_id)
	if username != "":
		return username
	else:
		# TODO : this changes the username of the users that have left.
		#  add a global profile cache for user profiles and use that for usernames.
		return "user_%s" % peer_id
		


func add_chat_notification(message: String) -> void:
	chat_text.text += "\n%s" % message
	chat_box.refresh()
