extends Node
class_name SongParser


var parser = XMLParser.new()
var current_song:Song


func parse_xml_from_file(filename: String) -> Song:
	parser = XMLParser.new()
	var error_code = parser.open(filename)
	if error_code != OK:
		push_error("Something went wrong when trying to parse this file as XML")
		return null
	
	return _parse_xml(parser)


func parse_xml_from_buffer(buffer: PackedByteArray) -> Song:
	parser = XMLParser.new()
	
	var error_code = parser.open_buffer(buffer)
	if error_code != OK:
		push_error("Something went wrong when trying to read this as XML")
		return null
	
	return _parse_xml(parser)


func _parse_xml(parser: XMLParser) -> Song:
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
	var songNameSort = document.get_element_by_name("songNameSort")
	if songNameSort:
		song.song_name_sort = songNameSort.get_text()
	song.start_beat = document.get_element_by_name("startBeat").get_text().to_float()
	song.average_tempo = document.get_element_by_name("averageTempo").get_text().to_float()
	song.tuning = document.get_element_by_name("tuning").attributes.duplicate()
	song.capo = document.get_element_by_name("capo").get_text().to_int()
	song.artist_name = document.get_element_by_name("artistName").get_text()
	song.artist_name_sort = document.get_element_by_name("artistNameSort").get_text()
	song.album_name = document.get_element_by_name("albumName").get_text()
	var albumNameSort = document.get_element_by_name("albumNameSort")
	if albumNameSort:
		song.album_name_sort = albumNameSort.get_text()
	var albumYear = document.get_element_by_name("albumYear")
	if albumYear:
		song.album_year = albumYear.get_text().to_int()
	var albumArt = document.get_element_by_name("albumArt")
	if albumArt:
		song.album_art = albumArt.get_text()
	song.crowd_speed = document.get_element_by_name("crowdSpeed").get_text().to_int()
	song.arrangement_properties = document.get_element_by_name("arrangementProperties").attributes.duplicate()
	song.last_conversion_date_time = document.get_element_by_name("lastConversionDateTime").get_text()
	song.phrases = []
	for phrase_tag in document.get_element_by_name("phrases").get_elements_by_name("phrase"):
		var phrase := Song.SongPhrase.new()
		var disparity = phrase_tag.attributes.get("disparity")
		if disparity is String:
			phrase.disparity = disparity == "1"
		var ignore = phrase_tag.attributes.get("ignore")
		if ignore is String:
			phrase.ignore = ignore == "1"
		var maxDifficulty = phrase_tag.attributes.get("maxDifficulty")
		if maxDifficulty is String:
			phrase.max_difficulty = maxDifficulty.to_int()
		var name = phrase_tag.attributes.get("name")
		if name:
			phrase.name = name
		var solo = phrase_tag.attributes.get("solo")
		if solo is String:
			phrase.solo = solo == "1"
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
		var variation = phrase_iteration_tag.attributes.get("variation")
		if variation is String:
			phrase_iteration.variation = variation
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
		var time = ebeat_tag.attributes.get("time")
		if time is String:
			ebeat.time = time.to_float()
		var measure = ebeat_tag.attributes.get("measure")
		if measure is String:
			ebeat.measure = measure.to_int()
		song.ebeats.append(ebeat)
	var tonebase = document.get_element_by_name("tonebase")
	if tonebase:
		song.tonebase = tonebase.get_text()
	var tonea = document.get_element_by_name("tonea")
	if tonea:
		song.tone_a = tonea.get_text()
	var toneb = document.get_element_by_name("toneb")
	if toneb:
		song.tone_b = toneb.get_text()
	var tonec = document.get_element_by_name("tonec")
	if tonec:
		song.tone_c = tonec.get_text()
	var toned = document.get_element_by_name("toned")
	if toned:
		song.tone_d = toned.get_text()
	song.tones = []
	var tones = document.get_element_by_name("tones")
	if tones:
		for tone_tag in tones.get_elements_by_name("tone"):
			var tone := Song.SongTone.new()
			tone.time = tone_tag.attributes["time"].to_float()
			tone.id = tone_tag.attributes["id"].to_int()
			tone.name = tone_tag.attributes["name"]
			song.tones.append(tone)
	song.sections = []
	var sections = document.get_element_by_name("sections")
	if sections:
		for section_tag in sections.get_elements_by_name("section"):
			var section := Song.SongSection.new()
			section.name = section_tag.attributes["name"]
			section.number = section_tag.attributes["number"].to_int()
			section.start_time = section_tag.attributes["startTime"].to_float()
			song.sections.append(section)
			
	song.events = []
	var events = document.get_element_by_name("events")
	if events:
		for event_tag in events.get_elements_by_name("event"):
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
	var fretHandMutes = transcription_track_tag.get_element_by_name("fretHandMutes")
	if fretHandMutes:
		for fret_hand_mute_tag in fretHandMutes.get_elements_by_name("frethandMute"):
			pass
	
	song.levels = []
	for level_tag in document.get_element_by_name("levels").get_elements_by_name("level"):
		var level := Song.SongLevel.new()
		level.difficulty = level_tag.attributes["difficulty"].to_int()
		level.notes = []
		for note_tag in level_tag.get_element_by_name("notes").get_elements_by_name("note"):
			var note := Song.SongLevel.SongLevelNote.new()
			note.time = note_tag.attributes["time"].to_float()
			var linkNext = note_tag.attributes.get("linkNext")
			if linkNext is String:
				note.link_next = linkNext == "1"
			var accent = note_tag.attributes.get("accent")
			if accent is String:
				note.accent = accent == "1"
			var bend = note_tag.attributes.get("bend")
			if bend is String:
				note.bend = bend == "1"
			note.fret = note_tag.attributes["fret"].to_int()
			var hammerOn = note_tag.attributes.get("hammerOn")
			if hammerOn is String:
				note.hammer_on = hammerOn == "1"
			var harmonic = note_tag.attributes.get("harmonic")
			if harmonic is String:
				note.harmonic = harmonic == "1"
			var hopo = note_tag.attributes.get("hopo")
			if hopo is String:
				note.hopo = hopo == "1"
			var ignore = note_tag.attributes.get("ignore")
			if ignore is String:
				note.ignore = ignore == "1"
			var leftHand = note_tag.attributes.get("leftHand")
			if leftHand is String:
				note.left_hand = leftHand.to_int()
			var mute = note_tag.attributes.get("mute")
			if mute is String:
				note.mute = mute == "1"
			var palm_mute = note_tag.attributes.get("palmMute")
			if palm_mute is String:
				note.palm_mute = palm_mute == "1"
			var pluck = note_tag.attributes.get("pluck")
			if pluck is String:
				note.pluck = pluck.to_int()
			var pullOff = note_tag.attributes.get("pullOff")
			if pullOff is String:
				note.pull_off = pullOff == "1"
			var slap = note_tag.attributes.get("slap")
			if slap is String:
				note.slap = slap.to_int()
			var slide_to = note_tag.attributes.get("slideTo")
			if slide_to is String:
				note.slide_to = slide_to.to_int()
			note.string = note_tag.attributes["string"].to_int()
			var sustain = note_tag.attributes.get("sustain")
			if sustain is String:
				note.sustain = sustain.to_float()
			var tremolo = note_tag.attributes.get("tremolo")
			if tremolo:
				note.tremolo = tremolo == "1"
			var harmonicPinch = note_tag.attributes.get("harmonicPinch")
			if harmonicPinch is String:
				note.harmonic_pinch = harmonicPinch == "1"
			var pickDirection = note_tag.attributes.get("pickDirection")
			if pickDirection is String:
				note.pick_direction = pickDirection == "1"
			var rightHand = note_tag.attributes.get("rightHand")
			if rightHand is String:
				note.right_hand = rightHand.to_int()
			var slideUnpitchTo = note_tag.attributes.get("slideUnpitchTo")
			if slideUnpitchTo is String:
				note.slide_unpitch_to = slideUnpitchTo.to_int()
			var tap = note_tag.attributes.get("tap")
			if tap is String:
				note.tap = tap == "1"
			var vibrato = note_tag.attributes.get("vibrato")
			if vibrato is String:
				note.vibrato = vibrato == "1"
			level.notes.append(note)
		level.chords = []
		for chord_tag in level_tag.get_element_by_name("chords").get_elements_by_name("chord"):
			var chord := Song.SongLevel.SongLevelChord.new()
			chord.time = chord_tag.attributes["time"].to_float()
			chord.link_next = chord_tag.attributes["linkNext"] == "1"
			chord.accent = chord_tag.attributes["accent"] == "1"
			chord.chord_id = chord_tag.attributes["chordId"].to_int()
			chord.fret_hand_mute = chord_tag.attributes["fretHandMute"] == "1"
			chord.high_density = chord_tag.attributes["highDensity"] == "1"
			chord.ignore = chord_tag.attributes["ignore"] == "1"
			chord.palm_mute = chord_tag.attributes["palmMute"] == "1"
			chord.hopo = chord_tag.attributes["hopo"] == "1"
			chord.strum = chord_tag.attributes["strum"]
			chord.chord_notes = []
			for chord_note_tag in chord_tag.get_elements_by_name("chordNote"):
				var chord_note := Song.SongLevel.SongLevelChord.SongLevelChordNote.new()
				chord_note.time = chord_note_tag.attributes["time"].to_float()
				chord_note.link_next = chord_note_tag.attributes["linkNext"] == "1"
				chord_note.accent = chord_note_tag.attributes["accent"] == "1"
				chord_note.bend = chord_note_tag.attributes["bend"] == "1"
				chord_note.fret = chord_note_tag.attributes["fret"].to_int()
				chord_note.hammer_on = chord_note_tag.attributes["hammerOn"] == "1"
				chord_note.harmonic = chord_note_tag.attributes["harmonic"] == "1"
				chord_note.hopo = chord_note_tag.attributes["hopo"] == "1"
				chord_note.ignore = chord_note_tag.attributes["ignore"] == "1"
				chord_note.left_hand = chord_note_tag.attributes["leftHand"].to_int()
				chord_note.mute = chord_note_tag.attributes["mute"] == "1"
				chord_note.palm_mute = chord_note_tag.attributes["palmMute"] == "1"
				chord_note.pluck = chord_note_tag.attributes["pluck"].to_int()
				chord_note.pull_off = chord_note_tag.attributes["pullOff"] == "1"
				chord_note.slap = chord_note_tag.attributes["slap"].to_int()
				chord_note.slide_to = chord_note_tag.attributes["slideTo"].to_int()
				chord_note.string = chord_note_tag.attributes["string"].to_int()
				chord_note.sustain = chord_note_tag.attributes["sustain"].to_float()
				chord_note.tremolo = chord_note_tag.attributes["tremolo"] == "1"
				chord_note.harmonic_pinch = chord_note_tag.attributes["harmonicPinch"] == "1"
				chord_note.pick_direction = chord_note_tag.attributes["pickDirection"] == "1"
				chord_note.right_hand = chord_note_tag.attributes["rightHand"].to_int()
				chord_note.slide_unpitch_to = chord_note_tag.attributes["slideUnpitchTo"].to_int()
				chord_note.tap = chord_note_tag.attributes["tap"] == "1"
				chord_note.vibrato = chord_note_tag.attributes["vibrato"] == "1"
				chord.chord_notes.append(chord_note)
			level.chords.append(chord)
		song.levels.append(level)
	
	return song


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
	
	assert(current_element == null or current_element == document, "The number of opening and closing tags doesn't match")
	
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
