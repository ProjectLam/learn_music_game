extends Node3D


@onready var audio_stream:AudioStreamPlayer = $AudioStreamPlayer
@onready var current_song:Song


@export var should_print_song_loading_debugs: bool = false


# You can load a file without having to import it beforehand using the code snippet below. Keep in mind that this snippet loads the whole file into memory and may not be ideal for huge files (hundreds of megabytes or more).
func load_mp3(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound


#NOTE THIS DOESN't WORK in GODOT 4 cause of https://github.com/godotengine/godot/issues/61091
func load_ogg(path):
	var oggfile = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamOggVorbis.new()
	var packetSeq = OggPacketSequence.new()
	var len = oggfile.get_length()
	var data = oggfile.get_buffer(len)
	packetSeq.packet_data = data
	sound.packet_sequence = packetSeq
	sound.instantiate_playback()
	return sound


func print_song_loading_debug(to_print):
	if should_print_song_loading_debugs:
		print(to_print)


func _ready():
	current_song = PlayerVariables.current_song;
	print_song_loading_debug(current_song)
		
	var currentStream:AudioStream
	if current_song == null || current_song.songMusicFile == "":
		# just for quick debugging
		currentStream = load_mp3("res://Arlow - How Do You Know [NCS Release].mp3")
	else:
		print_song_loading_debug(current_song.songMusicFile)
		#TODO determine file type and handle ogg in future also
		currentStream = load_mp3(current_song.songMusicFile)
		print_song_loading_debug("Title of song from Meta Data-"+ current_song.title)
		#print("Ebeat data ----")
		#print("count-"+ current_song.ebeats.count)
		#for beat in current_song.ebeats.beats:
		#	print("beat(time"+ str(beat.x) + "-measure-" + str(beat.y))
		#print("--- end Ebeat data ----")
		
		
		print_song_loading_debug("Levels data ----")
		print_song_loading_debug("count-"+ current_song.levels_count)
		for level in current_song.levels:
			print_song_loading_debug("level(difficulty"+ str(level.difficulty)+ " )")
			print_song_loading_debug("notes data ----")
			for note in level.notes:
				print_song_loading_debug("---note -" + str(note)  + "- time-" + str(note.time)) #TODO expand
			
			print_song_loading_debug("--- end notes data ----")
			
		print_song_loading_debug("--- end level data ----")
		
#		var tab_creator = preload("res://scenes/tab_creator/tab_creator.gd").new()
#		tab_creator.create_tabs(current_song)
		
		$Notes.start_game(current_song.levels[0])
	
	audio_stream.stream = currentStream
	audio_stream.play()
#	audio_stream.volume_db = -16
