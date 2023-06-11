extends Node

@export var local_songs_path = "user://songs"
@export var local_songs_json_file = "songs.json"

var is_song_preload_completed := false
signal song_preload_completed

signal song_preloaded(song: Song)

const FILE_REQUEST_SCENE := preload("res://scenes/networking/remote_file_access/remote_file_request.tscn")
@onready var remote_file_requests = %RemoteFileRequests


func _ready():
	load_songs()


func load_songs():
	load_local_songs()
	
	# remote songs can override local songs. change order if this is not desired.
	load_remote_songs()


func load_remote_songs():
	if not GBackend.remote_songs_json_initialized:
		while true:
			await get_tree().process_frame
			if GBackend.remote_songs_json_initialized:
				break
			elif GBackend.file_src_mode == GBackend.FILE_SRC_MODE.OFFLINE:
				print("Offline mode detected. Preloading song aborted.")
				is_song_preload_completed = true
				song_preload_completed.emit()
				return
	
	
	for key in GBackend.remote_songs_info:
		var song_info = GBackend.remote_songs_info[key]
		if not (song_info is Dictionary):
			push_error("Invalid remote song info. Skipping...")
			continue
		var lead_xml_url = song_info.get("lead_xml_url")
		var song_file_url = song_info.get("song_file_url")
		if not (lead_xml_url is String):
			push_error("Invalid remote song xml url. Skipping...")
			continue
		if not (song_file_url is String):
			push_error("Invalid remote song url. Skipping...")
			continue
		var new_xml_request = FILE_REQUEST_SCENE.instantiate()
		new_xml_request.request_completed.connect(func(buffer) : _on_lead_xml_received(song_file_url, buffer))
		new_xml_request.target_url = GBackend.remote_songs_json_url.get_base_dir().path_join(lead_xml_url)
		remote_file_requests.add_child(new_xml_request)
	
	while(remote_file_requests.get_child_count() > 0):
		await remote_file_requests.child_exiting_tree
		await get_tree().process_frame
	
	print("Preloading song configurations completed.")
	is_song_preload_completed = true
	song_preload_completed.emit()


func load_local_songs():
	var local_json_path := local_songs_path.path_join(local_songs_json_file)
	# check for songs.json
	if FileAccess.file_exists(local_json_path):
		var json_string = FileAccess.get_file_as_string(local_json_path)
		var json_data = JSON.parse_string(json_string)
		if json_data == null or not json_data.has("songs"):
			push_error("Failed to parse the json file at ", local_json_path)
			return
		for song in json_data.songs as String:
			# TODO : add more handling for json file.
			_handle_local_song_zip(local_songs_path.path_join(song))
	
	else:
		# else check for files
		
		# processing directories
		#Assume each directory is 1 song
		#TODO in future allow a JSON file that has direct links to song zip or directories
		var song_dirs := DirAccess.get_directories_at(local_songs_path)
		for song_dir in song_dirs:
			if song_dir.begins_with("."):
				continue
			var song_dpath = local_songs_path.path_join(song_dir)
			print("Found directory - " + song_dpath)
			_handle_song_dir(song_dpath)
		
		# Assume each zip file is 1 song.
		var song_files := DirAccess.get_files_at(local_songs_path)
		for sfile in song_files:
			if sfile.begins_with(".") or sfile.get_extension() != "zip":
				continue
			var sfile_path := local_songs_path.path_join(sfile)
			#TODO in future allow songs to be .zip files
			print("Found zip - " + sfile_path)
			_handle_local_song_zip(sfile_path)


func _on_lead_xml_received(song_file_path, xml_buffer):
	var sp := SongParser.new()
	var song = sp.parse_xml_from_buffer(xml_buffer)
	if(song):
		song.song_music_file = song_file_path
		song.song_music_file_access = GBackend.song_remote_access
		PlayerVariables.songs[song.get_identifier()] = song
		print("song [%s] added" % song.get_identifier())
		song_preloaded.emit(song)
	else:
		push_error("Could not parse song xml")


func _handle_song_dir(song_dpath: String):
	print("handle_song_dir-" + song_dpath)
	
	var song: Song
	
	var files := DirAccess.get_files_at(song_dpath)
	
	for file in files:
		if file.begins_with(".") or file.get_extension() != "xml":
			continue
		var fpath := song_dpath.path_join(file)
		print("got song data xml - " + fpath)
		var sp:SongParser = SongParser.new()
		#sp.parse_xml_from_file(full_xml, song)
		#NOTE this is the core Xml File, there are up to 4 other ones
	
	var sarr_path := song_dpath.path_join("songs/arr")
	var arrfiles := DirAccess.get_files_at(sarr_path)
	#Find the instrument specific ones, for now we are only going to look for lead guitair
	for file in arrfiles:
		if file.begins_with(".") or file.get_extension() != "xml":
			continue
		var fpath := sarr_path.path_join(file)
		if file.ends_with("_lead.xml"):
			print("got lead xml - " + fpath)
			var sp:SongParser = SongParser.new()
			song = sp.parse_xml_from_file(fpath)
			#NOTE  TODO this is the lead guitar Xml File, there are up to 4 other ones, including vocals
	
	# Find the first .mp3 file that doesn't include _preview in audio/windows for now
	# TODO in future do full directory traversal
	var windows_path := song_dpath.path_join("audio/windows")
	var wfiles := DirAccess.get_files_at(windows_path)
	for file in wfiles:
		if file.begins_with("."):
			continue
		var fpath := windows_path.path_join(file)
		if file.get_extension() == "mp3" and not file.contains("preview"):
			if song:
				song.song_music_file = fpath
				print("song file found : ", song.song_music_file)
	if song:
		PlayerVariables.songs[song.get_identifier()] = song
		print("song [%s] added" % song.get_identifier())
		song_preloaded.emit(song)
	else:
		push_warning("no song found in directory : ", song_dpath)


func _handle_local_song_zip(path: String):
	var reader := ZIPReader.new()
	var err := reader.open(path)
	if err != OK:
		push_error("This ZIP file at path ", path, " couldn't be opened")
		return
	
	var song: Song
	var song_music_buffer: PackedByteArray
	
	# Returns a PoolStringArray of all files in all directories
	var files := reader.get_files()
	
	for file in files:
		if file.ends_with("_lead.xml"):
			var song_parser := SongParser.new()
			song = song_parser.parse_xml_from_buffer(reader.read_file(file))
		if file.ends_with(".mp3") and not "preview" in file:
			song_music_buffer = reader.read_file(file)
	
	if song:
		song.song_music_buffer = song_music_buffer
		PlayerVariables.songs[song.get_identifier()] = song
		print("song [%s] added" % song.get_identifier())
		song_preloaded.emit(song)
