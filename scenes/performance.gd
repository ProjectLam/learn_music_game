extends Node3D


@onready var audio_stream:AudioStreamPlayer = $AudioStreamPlayer
@onready var current_song:Song


@export var should_print_song_loading_debugs: bool = false

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
	print("performance song changed")
	current_song = SessionVariables.current_song
	var current_stream:AudioStream
	if current_song:
		print_song_loading_debug(current_song.song_music_file)
		
		if current_song.song_music_file == "":
			current_stream = load_mp3_from_buffer(current_song.song_music_buffer)
		else:
			current_stream = load_mp3_from_path(current_song.song_music_file)
		
		print_song_loading_debug("Title of song from Meta Data-"+ current_song.title)
		
		if is_instance_valid(performance_instrument):
			performance_instrument.start_game(current_song)
		
		audio_stream.stream = current_stream
		audio_stream.play()
	else:
		print("No song selected")

func sync_audiostream_remote(p_playing : bool, p_seek):
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
	SessionVariables.song_changed.connect(_on_song_changed)
	
	current_song = SessionVariables.current_song
	print_song_loading_debug(current_song)
		
	if current_song == null && SessionVariables.load_test_song:
		var current_stream = load_mp3_from_path("res://Arlow - How Do You Know [NCS Release].mp3")
		audio_stream.stream = current_stream
		audio_stream.play()
		
	match SessionVariables.instrument:
		SessionVariables.Instrument.GUITAR:
			performance_instrument = preload("res://scenes/performance/instruments/performance_guitar.tscn").instantiate()
		SessionVariables.Instrument.PIANO:
			performance_instrument = preload("res://scenes/performance/instruments/performance_piano.tscn").instantiate()
		SessionVariables.Instrument.PHIN:
			pass
	
	if (!is_instance_valid(performance_instrument)):
		push_error("Invalid performance instrument")
		# TODO : add error handling.
	add_child(performance_instrument)
	
	_on_song_changed()
#	audio_stream.volume_db = -16

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
		if !is_playing():
			audio_stream.play()
	
func _on_QuitBtn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")

func _on_received_match_state(p_state):
	print("Received match state: ", p_state)

func _exit_tree():
	performance_instrument = null


func _on_pause_play_button_pressed():
	media_pause_play()
