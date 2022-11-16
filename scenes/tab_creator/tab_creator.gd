# I wrote this script as a quick visualisation tool for the parsed note data. It's far from perfect,
# I'm 90% sure the timing is wrong on many of the notes, but they're close enough for the purpose of
# this script.

func create_tabs(song: Song):
	# one string for each guitar string
	var strings: Array
	for i in 6:
		strings.append("")
	
	var string_length: int = 0
	
	var notes = song.levels[0].notes.duplicate()
	
	var time: float
	var beat_length: float = song.ebeats.measures[0].beats[1].time - song.ebeats.measures[0].beats[0].time
	for measure in song.ebeats.measures:
		for i in strings.size():
			strings[i] += "+"
		string_length += 1
		
		for beat in measure.beats:
			for subdivision in 4:
				time = beat.time + beat_length / subdivision
				while abs(notes[0].time - time) < 0.5 * beat_length / subdivision:
					var note = notes.pop_front()
					strings[note.string] += str(note.fret)
				for i in strings.size():
					if strings[i].length() <= string_length:
						strings[i] += "-"
				string_length += 1
	
	for string in strings:
		print(string)
