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
		
		var xml: PackedByteArray = _get_lead_xml(songs_path.path_join(json_data.songs[0]))
		var parser := SongParser.new()
		var song: Song
		song = parser.parse_xml_from_buffer(xml)
		print(song.levels.size())
		var notes = song.get_notes_and_chords_for_difficulty()
		print(notes.size(), " notes found")
		
		# print_chords(notes)
		print_notes(notes)


func print_notes(notes: Array):
	for i in notes.size():
		var note = notes[i]
		if (not note is Chord) and note.slide_unpitch_to >= 0:
			print("note ", i, " at string ", note.string, " and fret ", note.fret, " has an unpitched slide to fret ", note.slide_unpitch_to, " and should sustain for ", note.sustain, " seconds.")


func print_chords(notes: Array):
	for chord in notes:
		if chord is Chord and chord.is_barre_chord():
			var chord_name = "Nameless chord"
			if chord.display_name != " ":
				chord_name = chord.display_name
			print("\n", chord_name, ", with pitches: ")
			var pitches = chord.get_pitches()
			for pitch in pitches:
				print(NoteFrequency.CHROMATIC_NAMES[NoteFrequency.CHROMATIC.find(pitch)])
			
			if chord.finger_0 >= 0 and (
				chord.finger_0 == chord.finger_1 \
				or chord.finger_0 == chord.finger_2 \
				or chord.finger_0 == chord.finger_3 \
				or chord.finger_0 == chord.finger_4 \
				or chord.finger_0 == chord.finger_5
			):
				print("barre on fret ", chord.fret_0)
			
			if chord.finger_1 >= 0 and (
				chord.finger_1 == chord.finger_2 \
				or chord.finger_1 == chord.finger_3 \
				or chord.finger_1 == chord.finger_4 \
				or chord.finger_1 == chord.finger_5
			):
				print("barre on fret ", chord.fret_1)
			
			if chord.finger_2 >= 0 and (
				chord.finger_2 == chord.finger_3 \
				or chord.finger_2 == chord.finger_4 \
				or chord.finger_2 == chord.finger_5
			):
				print("barre on fret ", chord.fret_2)
			
			if chord.finger_3 >= 0 and (
				chord.finger_3 == chord.finger_4 \
				or chord.finger_3 == chord.finger_5
			):
				print("barre on fret ", chord.fret_3)
			
			if chord.finger_4 >= 0 and chord.finger_4 == chord.finger_5:
				print("barre on fret ", chord.fret_4)


func _get_lead_xml(path: String) -> PackedByteArray:
	var reader := ZIPReader.new()
	var err := reader.open(path)
	if err != OK:
		push_error("This ZIP file at path ", path, " couldn't be opened")
		return PackedByteArray()
	
	var song := Song.new()
#	PlayerVariables.songs.append(song)
	
	# Returns a PoolStringArray of all files in all directories
	var files := reader.get_files()
	print(files)
	
	for file in files:
		if file.ends_with("_lead.xml"):
			return reader.read_file(file)
	
	return PackedByteArray()
