extends Node
class_name SongParser

var errorCode = 0
var parser = XMLParser.new()
var extractNodes = { "artistName": true, "title": true, "albumName": true }
var customParser = { "ebeats": true, "levels": true }
var notesAllowed = { "sustain": true, "time": true, "harmonic": true, "fret": true }
var current_song:Song


func attr(name) -> String:
	return parser.get_named_attribute_value(name)

func parser_note(note:Note):
	for i in range(parser.get_attribute_count()):
		var attr_name = parser.get_attribute_name(i)
		var val = parser.get_attribute_value(i)
		#lets not filter any for now, TODO in future we should
		#if(!notesAllowed.has(attr_name)):
		#	continue

		if attr_name == "sustain"  || attr_name == "time" :
#			print("attr-" + attr_name  + " val-" + val)
			note.set(attr_name, val.to_float())
		else:
			note.set(attr_name, val.to_int())
	return note

func parser_notes(notes:Array[Note]):
	var node_name = ""
	var last_node_data = ""
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			node_name = parser.get_node_name()
		elif parser.get_node_type() == XMLParser.NODE_TEXT:
			last_node_data = parser.get_node_data()
			
#		print(node_name, ": ", last_node_data)
		if parser.get_node_type() == parser.NODE_ELEMENT && node_name == "notes":
			var count = parser.get_named_attribute_value_safe("count")
			current_song.levels_count = count
		elif parser.get_node_type() == parser.NODE_ELEMENT && node_name == "note":
			var note:Note = Note.new() 
			parser_note(note)
			notes.append(note)
		elif node_name == "notes" && parser.get_node_type() == parser.NODE_ELEMENT_END:
			break
	print("final - notes size- " + str(len(notes)))			
	return

func parser_levels():
	print("levels")
	var count = parser.get_named_attribute_value_safe("count")
	current_song.levels_count = count
	var node_name = ""
	var last_node_data = ""
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			node_name = parser.get_node_name()
		elif parser.get_node_type() == XMLParser.NODE_TEXT:
			last_node_data = parser.get_node_data()

		#print(node_name, ": ", last_node_data)
		if parser.get_node_type() == parser.NODE_ELEMENT && node_name == "level":
			var difficulty = parser.get_named_attribute_value_safe("difficulty")
			if difficulty.to_int() > 0:
				print("weee debug")

			var level = Level.new()
			parser_notes(level.notes)
			current_song.levels.append(level)
			node_name = ""
		elif node_name == "levels"	 && parser.get_node_type() == parser.NODE_ELEMENT_END:
			return #ok done

	
func parser_ebeats():
	var count = parser.get_named_attribute_value_safe("count")
	current_song.ebeats.count = count

	var node_name = ""
	var last_node_data = ""
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			node_name = parser.get_node_name()
		elif parser.get_node_type() == XMLParser.NODE_TEXT:
			last_node_data = parser.get_node_data()

		#print(node_name, ": ", last_node_data)
		if parser.get_node_type() == parser.NODE_ELEMENT && node_name == "ebeat":
			var time = parser.get_named_attribute_value_safe("time").to_float()
			var measure = parser.get_named_attribute_value_safe("measure").to_int()
			current_song.ebeats.add_beat(measure, time)
		elif node_name != "ebeat" && parser.get_node_type() == parser.NODE_ELEMENT_END:
			return #ok done

			

# Extracts a xml element and reads the text 
# for examle <bob a="123">test</bob> would return "test"
func xml_read_text():
	if parser.get_node_type() == parser.NODE_ELEMENT:
		var err = parser.read()
		if errorCode != OK:
			return "Errror!"
		var text = parser.get_node_data()
		err = parser.read()
		#if parser.get_node_type() == NODE_ELEMENT_END:
		#TODO check
		return text
	return ""
	
func parse_xml(filename:String, song:Song):
	parser = XMLParser.new()
	current_song = song
	var errorCode = parser.open(filename)
	if errorCode != OK:
		return #exit(errorCode)
			
	var node_name = ""
	var last_node_data = ""
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			node_name = parser.get_node_name()
		elif parser.get_node_type() == XMLParser.NODE_TEXT:
			last_node_data = parser.get_node_data()
			
		#print("Node-" + node_name, ": ", last_node_data)
#		print(parser.get_node_name(), ": default---"+ parser.get_named_attribute_value_safe("value"))
		if(customParser.has(node_name)):
			call("parser_"+node_name)
			node_name = ""
		if(extractNodes.has(node_name)):
			var data = xml_read_text()
			if data != "":
				song.set(node_name, data)
			node_name = ""
