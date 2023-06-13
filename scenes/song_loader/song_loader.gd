extends Node

signal song_loaded(song: Song)

# (Song : loading information) pair
var loading := {}

# (Song : { main_stream: Audio stream, preview_stream : Audio stream)) pair
var loaded := {}

var loading_requests := {}
# Initiates loading a new song.
# Returns true if force_reload is false and song is already loaded.
func load_song(new_song: Song, force_reload: bool = false):
	if not force_reload and not loading.has(new_song) and loaded.has(new_song):
		# song is already loaded.
		_on_song_loaded(new_song)
		return true
	
	if loading.has(new_song):
		# already loading
		return
	
	if not loaded.has(new_song):
		loaded[new_song] = {
			"main_stream": null,
			"preview_stream": null,
		}
	
	print("loading song [%s] from [%s]" % [new_song.title, new_song.song_music_file])
	if new_song.song_music_file == "":
		loaded[new_song]["main_stream"] = load_mp3_from_buffer(new_song.song_music_buffer)
		_on_song_loaded(new_song)
	elif ( # It's a remote path
			new_song.song_music_file.begins_with("http://")
			or new_song.song_music_file.begins_with("https://")):
		push_error("Absolute remote path not implemented.")
	else:
		if(new_song.song_music_file_access == FileAccess):
			loaded[new_song]["main_stream"] = load_mp3_from_path(new_song.song_music_file)
			_on_song_loaded(new_song)
		else:
			# Song has a custom access. posibly a remote access.
			# create a new loader node.
			var loaderRequest = new_song.song_music_file_access.create_request(new_song.song_music_file)
			# prevent this from happening again if the song is being loaded.
			loading[new_song] = true
			# connect to the signal that indicates the request is completed
			loaderRequest.request_completed.connect(func(buffer) : _on_song_buffer_loaded(new_song, buffer))
			# add the new node to allow automatic pullling and resource handling. this way if the
			# song loader node is destroyed, loaderRequest will be freed as well.
			add_child(loaderRequest)
			loading_requests[new_song] = loaderRequest


func _on_song_buffer_loaded(song: Song, buffer):
	song.song_music_buffer = PackedByteArray(buffer)
	loaded[song]["main_stream"] = load_mp3_from_buffer(song.song_music_buffer)
	_on_song_loaded(song)
	

func _on_song_loaded(song: Song) -> void:
	if loading.has(song):
		loading.erase(song)
	print("loaded song [%s]" % song)
	song_loaded.emit(song)


# You can load a file without having to import it beforehand using the code snippet below. Keep in mind that this snippet loads the whole file into memory and may not be ideal for huge files (hundreds of megabytes or more).
func load_mp3_from_path(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound


func load_mp3_from_buffer(buffer):
	var sound := AudioStreamMP3.new()
	sound.data = PackedByteArray(buffer)
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


func get_main_stream(song: Song) -> AudioStream:
	if not loaded.has(song):
		push_error("Song loaded yet")
		return null
	
	return loaded[song]["main_stream"]
