extends Node
class_name SongParser


var parser = XMLParser.new()
var current_song:Song


func parse_xml_from_file(filename: String, song: Song):
	parser = XMLParser.new()
	current_song = song
	var error_code = parser.open(filename)
	if error_code != OK:
		push_error("Something went wrong when trying to parse this file as XML")
		return
	
	_parse_xml(parser)


func parse_xml_from_buffer(buffer: PackedByteArray, song: Song):
	parser = XMLParser.new()
	current_song = song
	
	var error_code = parser.open_buffer(buffer)
	if error_code != OK:
		push_error("Something went wrong when trying to read this as XML")
		return
	
	_parse_xml(parser)


func _parse_xml(parser: XMLParser):
	# First, use the parser to create some generic objects with a parent/child structure
	var document: XmlElementBase = _parse_xml_into_data(parser)
	
	# Then, create and populate a Song object from that XML
	var song := Song.new()
	song.version = document.get_element_by_name("song").attributes["version"]
	song.title = document.get_element_by_name("title").get_text()
	song.arrangement = document.get_element_by_name("arrangement").get_text()
	song.part = document.get_element_by_name("part").get_text().to_int()
	song.offset = document.get_element_by_name("offset").get_text().to_float()
	song.cent_offset = document.get_element_by_name("centOffset").get_text().to_float()
	song.song_length = document.get_element_by_name("songLength").get_text().to_float()
	song.song_name_sort = document.get_element_by_name("songNameSort").get_text()
	song.start_beat = document.get_element_by_name("startBeat").get_text().to_float()
	song.average_tempo = document.get_element_by_name("averageTempo").get_text().to_float()
	song.tuning = document.get_element_by_name("tuning").attributes.duplicate()
	song.capo = document.get_element_by_name("capo").get_text().to_int()
	song.artist_name = document.get_element_by_name("artistName").get_text()
	song.artist_name_sort = document.get_element_by_name("artistNameSort").get_text()
	song.album_name = document.get_element_by_name("albumName").get_text()
	song.album_name_sort = document.get_element_by_name("albumNameSort").get_text()
	song.album_year = document.get_element_by_name("albumYear").get_text().to_int()
	song.album_art = document.get_element_by_name("albumArt").get_text()
	song.crowd_speed = document.get_element_by_name("crowdSpeed").get_text().to_int()
	song.arrangement_properties = document.get_element_by_name("arrangementProperties").attributes.duplicate()
	song.last_conversion_date_time = document.get_element_by_name("lastConversionDateTime").get_text()
	song.phrases = []
	for phrase_tag in document.get_element_by_name("phrases").get_elements_by_name("phrase"):
		var phrase := Song.SongPhrase.new()
		phrase.disparity = phrase_tag.attributes["disparity"] == "1"
		phrase.ignore = phrase_tag.attributes["ignore"] == "1"
		phrase.max_difficulty = phrase_tag.attributes["maxDifficulty"].to_int()
		phrase.name = phrase_tag.attributes["name"]
		phrase.solo = phrase_tag.attributes["solo"] == "1"
		song.phrases.append(phrase)
	song.new_linked_diffs = []
	for new_linked_diff_tag in document.get_element_by_name("newLinkedDiffs").get_elements_by_name("newLinkedDiff"):
		var new_linked_diff := Song.SongNewLinkedDiff.new()
		new_linked_diff.level_break = new_linked_diff_tag.attributes["levelBreak"].to_int()
		new_linked_diff.ratio = new_linked_diff_tag.attributes["ratio"]
		new_linked_diff.phrase_count = new_linked_diff_tag.attributes["phraseCount"]
		new_linked_diff.nld_phrases = []
		for nld_phrase_tag in new_linked_diff_tag.get_elements_by_name("nld_phrase"):
			new_linked_diff.nld_phrases.append(nld_phrase_tag.attributes["id"].to_int())
		song.new_linked_diffs.append(new_linked_diff)
	song.phrase_iterations = []
	for phrase_iteration_tag in document.get_element_by_name("phraseIterations").get_elements_by_name("phraseIteration"):
		var phrase_iteration := Song.SongPhraseIteration.new()
		phrase_iteration.time = phrase_iteration_tag.attributes["time"].to_float()
		phrase_iteration.phrase_id = phrase_iteration_tag.attributes["phraseId"].to_int()
		phrase_iteration.variation = phrase_iteration_tag.attributes["variation"]
		phrase_iteration.hero_levels = []
		for hero_level_tag in phrase_iteration_tag.get_elements_by_name("heroLevel"):
			var hero_level := Song.SongPhraseIteration.HeroLevel.new()
			hero_level.difficulty = hero_level_tag.attributes["difficulty"].to_int()
			hero_level.hero = hero_level_tag.attributes["hero"].to_int()
			phrase_iteration.hero_levels.append(hero_level)
		song.phrase_iterations.append(phrase_iteration)
	
	print_rich("[b]XML Parser:[/b] [i]Need to add linkedDiff data here, but no idea what that is yet[/i]")
	print_rich("[b]XML Parser:[/b] [i]Need to add phraseProperty data here, but no idea what that is yet[/i]")
	
	song.chord_templates = []
	for chord_template_tag in document.get_element_by_name("chordTemplates").get_elements_by_name("chordTemplate"):
		var chord_template := Song.SongChordTemplate.new()
		chord_template.display_name = chord_template_tag.attributes["displayName"]
		chord_template.chord_name = chord_template_tag.attributes["chordName"]
		chord_template.fret_0 = chord_template_tag.attributes["fret0"].to_int()
		chord_template.fret_1 = chord_template_tag.attributes["fret1"].to_int()
		chord_template.fret_2 = chord_template_tag.attributes["fret2"].to_int()
		chord_template.fret_3 = chord_template_tag.attributes["fret3"].to_int()
		chord_template.fret_4 = chord_template_tag.attributes["fret4"].to_int()
		chord_template.fret_5 = chord_template_tag.attributes["fret5"].to_int()
		chord_template.finger_0 = chord_template_tag.attributes["finger0"].to_int()
		chord_template.finger_1 = chord_template_tag.attributes["finger1"].to_int()
		chord_template.finger_2 = chord_template_tag.attributes["finger2"].to_int()
		chord_template.finger_3 = chord_template_tag.attributes["finger3"].to_int()
		chord_template.finger_4 = chord_template_tag.attributes["finger4"].to_int()
		chord_template.finger_5 = chord_template_tag.attributes["finger5"].to_int()
		song.chord_templates.append(chord_template)
	
	print_rich("[b]XML Parser:[/b] [i]Need to add fretHandMuteTemplate data here, but no idea what that is yet[/i]")
	
	song.ebeats = []
	for ebeat_tag in document.get_element_by_name("ebeats").get_elements_by_name("ebeat"):
		var ebeat := Song.SongEbeat.new()
		ebeat.time = ebeat_tag.attributes["time"].to_float()
		ebeat.measure = ebeat_tag.attributes["measure"].to_int()
		song.ebeats.append(ebeat)
	song.tonebase = document.get_element_by_name("tonebase").get_text()
	song.tone_a = document.get_element_by_name("tonea").get_text()
	song.tone_b = document.get_element_by_name("toneb").get_text()
	song.tone_c = document.get_element_by_name("tonec").get_text()
	song.tone_d = document.get_element_by_name("toned").get_text()
	song.tones = []
	for tone_tag in document.get_element_by_name("tones").get_elements_by_name("tone"):
		var tone := Song.SongTone.new()
		tone.time = tone_tag.attributes["time"].to_float()
		tone.id = tone_tag.attributes["id"].to_int()
		tone.name = tone_tag.attributes["name"]
		song.tones.append(tone)
	song.sections = []
	for section_tag in document.get_element_by_name("sections").get_elements_by_name("section"):
		var section := Song.SongSection.new()
		section.name = section_tag.attributes["name"]
		section.number = section_tag.attributes["number"].to_int()
		section.start_time = section_tag.attributes["startTime"].to_float()
		song.sections.append(section)
	song.events = []
	for event_tag in document.get_element_by_name("events").get_elements_by_name("event"):
		var event := Song.SongEvent.new()
		event.time = event_tag.attributes["time"].to_float()
		event.code = event_tag.attributes["code"]
		song.events.append(event)
	
	var transcription_track_tag = document.get_element_by_name("transcriptionTrack")
	var transcription_track := Song.SongTranscriptionTrack.new()
	transcription_track.difficulty = transcription_track_tag.attributes["difficulty"].to_int()
	
	print_rich("[b]XML Parser:[/b] [i]Need to add transcription track data here, but no idea what the properties are yet[/i]")
	
	transcription_track.notes = []
	for note_tag in transcription_track_tag.get_element_by_name("notes").get_elements_by_name("note"):
		pass
	transcription_track.chords = []
	for chord_tag in transcription_track_tag.get_element_by_name("chords").get_elements_by_name("chord"):
		pass
	transcription_track.anchors = []
	for anchor_tag in transcription_track_tag.get_element_by_name("anchors").get_elements_by_name("anchor"):
		pass
	transcription_track.hand_shapes = []
	for hand_shape_tag in transcription_track_tag.get_element_by_name("handShapes").get_elements_by_name("handShape"):
		pass
	transcription_track.fret_hand_mutes = []
	for fret_hand_mute_tag in transcription_track_tag.get_element_by_name("fretHandMutes").get_elements_by_name("frethandMute"):
		pass
	
	song.levels = []
	for level_tag in document.get_element_by_name("levels").get_elements_by_name("level"):
		var level := Song.SongLevel.new()
		level.difficulty = level_tag.attributes["difficulty"].to_int()
		level.notes = []
		for note_tag in level_tag.get_element_by_name("notes").get_elements_by_name("note"):
			var note := Song.SongLevel.SongLevelNote.new()
			note.time = note_tag.attributes["time"].to_float()
			note.link_next = note_tag.attributes["linkNext"] == "1"
			note.accent = note_tag.attributes["accent"] == "1"
			note.bend = note_tag.attributes["bend"] == "1"
			note.fret = note_tag.attributes["fret"].to_int()
			note.hammer_on = note_tag.attributes["hammerOn"] == "1"
			note.harmonic = note_tag.attributes["harmonic"] == "1"
			note.hopo = note_tag.attributes["hopo"] == "1"
			note.ignore = note_tag.attributes["ignore"] == "1"
			note.left_hand = note_tag.attributes["leftHand"].to_int()
			note.mute = note_tag.attributes["mute"] == "1"
			note.palm_mute = note_tag.attributes["palmMute"] == "1"
			note.pluck = note_tag.attributes["pluck"].to_int()
			note.pull_off = note_tag.attributes["pullOff"] == "1"
			note.slap = note_tag.attributes["slap"].to_int()
			note.slide_to = note_tag.attributes["slideTo"].to_int()
			note.string = note_tag.attributes["string"].to_int()
			note.sustain = note_tag.attributes["sustain"].to_float()
			note.tremolo = note_tag.attributes["tremolo"] == "1"
			note.harmonic_pinch = note_tag.attributes["harmonicPinch"] == "1"
			note.pick_direction = note_tag.attributes["pickDirection"] == "1"
			note.right_hand = note_tag.attributes["rightHand"].to_int()
			note.slide_unpitch_to = note_tag.attributes["slideUnpitchTo"].to_int()
			note.tap = note_tag.attributes["tap"] == "1"
			note.vibrato = note_tag.attributes["vibrato"] == "1"
			level.notes.append(note)


func _parse_xml_into_data(parser: XMLParser) -> XmlElementBase:
	var document := XmlElementBase.new()
	var current_element = document
	
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var element := XmlElement.new()
				current_element.add_child(element)
				
				element.name = parser.get_node_name()
				
				for i in parser.get_attribute_count():
					element.attributes[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				
				if not parser.is_empty():
					current_element = element
			XMLParser.NODE_ELEMENT_END:
				current_element = current_element.parent
			XMLParser.NODE_TEXT:
				var element := XmlText.new()
				element.text = parser.get_node_data()
				current_element.add_child(element)
	
	assert(current_element == document, "The number of opening and closing tags doesn't match")
	
	return document


class XmlElementBase:
	var parent: XmlElementBase
	var children: Array[XmlElementBase]
	
	
	func add_child(child: XmlElementBase):
		child.parent = self
		children.append(child)
	
	
	# Returns the first element with this name
	func get_element_by_name(name: String) -> XmlElement:
		for child in children:
			if child.get("name") == name:
				return child
			var candidate := child.get_element_by_name(name)
			if candidate:
				return candidate
		return null
	
	
	# Returns all elements with this name
	func get_elements_by_name(name: String) -> Array[XmlElement]:
		var elements: Array[XmlElement] = []
		for child in children:
			if child.get("name") == name:
				elements.append(child)
			elements.append_array(child.get_elements_by_name(name))
		return elements
	
	
	# Returns the text of the first text element
	func get_text() -> String:
		for child in children:
			if child is XmlText:
				return child.text
		return ""
	
	
	# Returns the text of all text elements
	func get_texts() -> Array[String]:
		var texts: Array[String] = []
		for child in children:
			if child is XmlText:
				texts.append(child.text)
			texts.append_array(child.get_texts())
		return texts


class XmlElement extends XmlElementBase:
	var name: String
	var attributes: Dictionary


class XmlText extends XmlElementBase:
	var text: String
