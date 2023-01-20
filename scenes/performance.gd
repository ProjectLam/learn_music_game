extends Node3D


@onready var audio_stream: AudioStreamPlayer = $AudioStreamPlayer
@onready var current_song: Song
@onready var ingame_scores_viewer = %IngameScores
@export var should_print_song_loading_debugs: bool = false

var self_user := IngameUser.new()
var ingame_users := {}

var performance_instrument: PerformanceInstrument

# You can load a file without having to import it beforehand using the code snippet below. Keep in mind that this snippet loads the whole file into memory and may not be ideal for huge files (hundreds of megabytes or more).
func load_mp3_from_path(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound


func load_mp3_from_buffer(buffer: PackedByteArray):
	var sound := AudioStreamMP3.new()
	sound.data = buffer
	return sound


#NOTE THIS DOESN't WORK in GODOT 4 cause of https://github.com/godotengine/godot/issues/61091
func load_ogg(path):
	var oggfile = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamOggVorbis.new()
	var packet_seq = OggPacketSequence.new()
	var len = oggfile.get_length()
	var data = oggfile.get_buffer(len)
	packet_seq.packet_data = data
	sound.packet_sequence = packet_seq
	sound.instantiate_playback()
	return sound


func print_song_loading_debug(to_print):
	if should_print_song_loading_debugs:
		print(to_print)


func _on_song_changed():
	current_song = SessionVariables.current_song
	if current_song is Song:
		print("performance song changed to ", current_song.get_identifier())
	else:
		print("performance song changed to none")
	var current_stream:AudioStream
	if current_song:
		print_song_loading_debug(current_song.song_music_file)
		
		if current_song.song_music_file == "":
			current_stream = load_mp3_from_buffer(current_song.song_music_buffer)
		else:
			current_stream = load_mp3_from_path(current_song.song_music_file)
		
		print_song_loading_debug("Title of song from Meta Data-"+ current_song.title)
		
		if is_instance_valid(performance_instrument):
			print("Instrument [%s] is valid. starting note sequence." % performance_instrument)
			performance_instrument.start_game(current_song)
		
		audio_stream.stream = current_stream
		audio_stream.play()
	else:
		print("No song selected")


func sync_audiostream_remote(p_playing: bool, p_seek):
	rpc("_sync_audiostream_remote", p_playing, p_seek, -1)


@rpc("any_peer", "call_local", "reliable") func _sync_audiostream_remote(p_playing : bool, p_seek : float, relay_source):
	if(multiplayer.get_unique_id() == relay_source):
		return
	if(audio_stream.playing == p_playing):
		# do nothing.
		return
	else:
		if(p_playing):
			audio_stream.play(p_seek)
		else:
			audio_stream.stream_paused = true
			if multiplayer.get_unique_id() != multiplayer.get_remote_sender_id():
				# relay pause command to sychronize state.
				rpc("_sync_audiostream_remote", p_playing, p_seek, multiplayer.get_remote_sender_id())


func _ready():
	multiplayer.peer_connected.connect(_on_user_connected)
	multiplayer.peer_disconnected.connect(_on_user_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	ingame_scores_viewer.reload_users({"self": self_user})
	
	if multiplayer.has_multiplayer_peer():
		var cstate = multiplayer.multiplayer_peer.get_connection_status()
		if cstate == MultiplayerPeer.CONNECTION_CONNECTED:
			ingame_users["%s" % multiplayer.get_unique_id()] = self_user
			reload_network_users()
	
	SessionVariables.song_changed.connect(_on_song_changed)
	
	current_song = SessionVariables.current_song
	print_song_loading_debug(current_song)
		
	if current_song == null && SessionVariables.load_test_song:
		var current_stream = load_mp3_from_path("res://Arlow - How Do You Know [NCS Release].mp3")
		audio_stream.stream = current_stream
		audio_stream.play()
	
	print_debug(PlayerVariables.selected_instrument)
	match SessionVariables.instrument:
		SessionVariables.Instrument.GUITAR:
			performance_instrument = preload("res://scenes/performance/instruments/performance_guitar.tscn").instantiate()
		SessionVariables.Instrument.PIANO:
			performance_instrument = preload("res://scenes/performance/instruments/performance_piano.tscn").instantiate()
		SessionVariables.Instrument.PHIN:
			pass
	
	if !is_instance_valid(performance_instrument):
		push_error("Invalid performance instrument")
		# TODO : add error handling.
	add_child(performance_instrument)
	_on_connect_instrument()
	
	_on_song_changed()


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
	if multiplayer.has_multiplayer_peer():
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
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")


func _on_received_match_state(p_state):
	print("Received match state: ", p_state)


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
		ret[index] = "%s" % users[index]
	return ret


func reload_network_users():
	var users := get_all_network_users()
	for iuser in users:
		if not ingame_users.has(iuser):
			_add_new_user(iuser)
			


func _add_new_user(uid) -> IngameUser:
	var new_iuser = IngameUser.new()
	ingame_users[uid] = new_iuser
	ingame_scores_viewer.reload_users(ingame_users)
	return new_iuser


func _on_user_connected(id: int):
	reload_network_users()
	if is_multiplayer_authority():
		var udata := {}
		for iuser in ingame_users:
			udata[iuser] = iuser.get_data()
		rpc("_set_all_user_data", udata)


func _on_user_disconnected(id: int):
	reload_network_users()


func _on_server_disconnected() -> void:
	# TODO
	pass


func _on_connected_to_server() -> void:
	ingame_users["%s" % multiplayer.get_unique_id()] = self_user
	reload_network_users()


func update_user_data(uid: String) -> void:
	# user data for has changed.
	if multiplayer.has_multiplayer_peer():
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc("_set_user_data", self_user.get_data())


func broadcast_all_user_data() -> void:
	if multiplayer.has_multiplayer_peer():
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print_debug("broadcasting all user data")
			var udata := {}
			for iuser in ingame_users:
				udata[iuser] = iuser.get_data()
			rpc("_set_all_user_data", udata)


@rpc("authority", "call_remote", "reliable") func _set_all_user_data(data) -> void:
	print("rpc _set_all_user_data called with {%s}" % data)
	for key in data:
		if not (key is String):
			# invalid key
			push_error("invalid user key %s" % key)
			continue
		var iuser: IngameUser
		if ingame_users.has(key):
			iuser = ingame_users[key]
		elif key == ("%s" % multiplayer.get_unique_id()):
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


@rpc("any_peer", "call_remote", "reliable") func _set_user_data(data) -> void:
	print("received remote _set_user_data call with [%s]" % data)
	var uid :String = "%d" % multiplayer.get_remote_sender_id()
	if not (data is Dictionary):
		push_error("invalid user data for uid [%s]" % uid)
		return
	if not ingame_users.has(uid):
		push_warning("something went wrong, non existing user is sending data")
		return
	ingame_users[uid].parse_data(data)


func _on_connect_instrument() -> void:
	print_debug(performance_instrument)
	performance_instrument.notes.good_note_started.connect(_on_good_note_started)


func _on_good_note_started(note_index: int, time_error: float) -> void:
	self_user._on_good_note(note_index, time_error)
	if multiplayer.has_multiplayer_peer():
		await GBackend.await_connection()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc("_set_user_data", self_user.get_data())
