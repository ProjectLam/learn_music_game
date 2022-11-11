extends Node3D
@onready var audio_stream:AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var current_song:Song


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


# Called when the node enters the scene tree for the first time.
func _ready():
	current_song = PlayerVariables.current_song;
	print(current_song)
		
	var currentStream:AudioStream
	if current_song == null || current_song.songMusicFile == "":
		# just for quick debugging
		currentStream = load_mp3("res://Arlow - How Do You Know [NCS Release].mp3")
	else:
		print(current_song.songMusicFile)
		#TODO determine file type and handle ogg in future also
		currentStream = load_mp3(current_song.songMusicFile)
		print("Title of song from Meta Data-"+ current_song.title)
		#print("Ebeat data ----")
		#print("count-"+ current_song.ebeats.count)
		#for beat in current_song.ebeats.beats:
		#	print("beat(time"+ str(beat.x) + "-measure-" + str(beat.y))
		#print("--- end Ebeat data ----")


		print("Levels data ----")
		print("count-"+ current_song.levels_count)
		for level in current_song.levels:
			print("level(difficulty"+ str(level.difficulty)+ " )")
			print("notes data ----")
			for note in level.notes:
				print("---note -" + str(note)) #TODO expand
			
			print("--- end notes data ----")
			
		print("--- end level data ----")

	audio_stream.stream = currentStream
	audio_stream.playing = true
#	audio_stream.volume_db = -16
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
