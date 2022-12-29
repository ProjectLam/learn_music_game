extends Node


func _ready():
	var songs_path = "user://songs"
	var songs_json_file := "songs.json"
	var dir := DirAccess.open(songs_path)
	if dir.file_exists(songs_json_file):
		var json_path: String = songs_path + "/" + songs_json_file
		var json_string = FileAccess.get_file_as_string(json_path)
		var json_data = JSON.parse_string(json_string)
		if json_data == null or not json_data.has("songs"):
			push_error("Failed to parse the json file at ", json_path)
			return
		
		print(json_data.songs[0])
		
		var xml: PackedByteArray = _get_lead_xml(songs_path.path_join(json_data.songs[0]))
		var parser := SongParser.new()
		parser.parse_xml_from_buffer(xml, Song.new())


func _get_lead_xml(path: String) -> PackedByteArray:
	var reader := ZIPReader.new()
	var err := reader.open(path)
	if err != OK:
		push_error("This ZIP file at path ", path, " couldn't be opened")
		return PackedByteArray()

	var song := Song.new()
	PlayerVariables.songs.append(song)

	# Returns a PoolStringArray of all files in all directories
	var files := reader.get_files()
	print(files)

	for file in files:
		if file.ends_with("_lead.xml"):
			return reader.read_file(file)
	
	return PackedByteArray()
