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


func _ready():
	current_song = PlayerVariables.current_song
	print_song_loading_debug(current_song)
		
	var current_stream:AudioStream
	if current_song == null:
		# just for quick debugging
		current_stream = load_mp3_from_path("res://Arlow - How Do You Know [NCS Release].mp3")
	else:
		print_song_loading_debug(current_song.song_music_file)
		#TODO determine file type and handle ogg in future also
		
		if current_song.song_music_file == "":
			current_stream = load_mp3_from_buffer(current_song.song_music_buffer)
		else:
			current_stream = load_mp3_from_path(current_song.song_music_file)
		
		print_song_loading_debug("Title of song from Meta Data-"+ current_song.title)
		#print("Ebeat data ----")
		#print("count-"+ current_song.ebeats.count)
		#for beat in current_song.ebeats.beats:
		#	print("beat(time"+ str(beat.x) + "-measure-" + str(beat.y))
		#print("--- end Ebeat data ----")
		
		
#		print_song_loading_debug("Levels data ----")
#		print_song_loading_debug("count-"+ current_song.levels_count)
#		for level in current_song.levels:
#			print_song_loading_debug("level(difficulty"+ str(level.difficulty)+ " )")
#			print_song_loading_debug("notes data ----")
#			for note in level.notes:
#				print_song_loading_debug("---note -" + str(note)  + "- time-" + str(note.time)) #TODO expand
#
#			print_song_loading_debug("--- end notes data ----")
#
#		print_song_loading_debug("--- end level data ----")
		
#		var tab_creator = preload("res://scenes/tab_creator/tab_creator.gd").new()
#		tab_creator.create_tabs(current_song)
		
		match SessionVariables.instrument:
			SessionVariables.Instrument.GUITAR:
				performance_instrument = preload("res://scenes/performance/instruments/performance_guitar.tscn").instantiate()
			SessionVariables.Instrument.PIANO:
				performance_instrument = preload("res://scenes/performance/instruments/performance_piano.tscn").instantiate()
			SessionVariables.Instrument.PHIN:
				pass
		
		add_child(performance_instrument)
		performance_instrument.start_game(current_song)
	
	audio_stream.stream = current_stream
	audio_stream.play()
#	audio_stream.volume_db = -16


func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")
		return


func _on_QuitBtn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/instrument_selection/instrument_selection.tscn")
