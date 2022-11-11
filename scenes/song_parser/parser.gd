extends Node
class_name SongParser

var errorCode = 0
var parser = XMLParser.new()
var xmlPBA = PackedByteArray()
var extractNodes = { "artistName": true, "title": true, "albumName": true }
var customParser = { "ebeats": true, "levels": true }
var current_song:Song

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func attr(name) -> String:
	return parser.get_named_attribute_value(name)

func parser_note():
	var note:Vector2 = Vector2(attr("time").to_float(), attr("sustain").to_float())
	#TODO iterate each attribute
	return note

func parser_notes()  -> Array[Vector2]:
	var notes:Array[Vector2] = []
	print("notes")
	var count = parser.get_named_attribute_value_safe("count")
	current_song.levels_count = count
	while parser.read() != ERR_FILE_EOF:
		var node_name = parser.get_node_name()
		print(parser.get_node_name(), ": ", parser.get_node_data())
		if parser.get_node_type() == parser.NODE_ELEMENT && node_name == "note":
			var note = parser_note()
			notes.append(note)
		elif node_name == "notes" && parser.get_node_type() == parser.NODE_ELEMENT_END:
			break			
	return notes

func parser_levels():
	print("levels")
	var count = parser.get_named_attribute_value_safe("count")
	current_song.levels_count = count
	while parser.read() != ERR_FILE_EOF:
		var node_name = parser.get_node_name()
		print(parser.get_node_name(), ": ", parser.get_node_data())
		if parser.get_node_type() == parser.NODE_ELEMENT && node_name == "level":
			var difficulty = parser.get_named_attribute_value_safe("difficulty")
			var notes = parser_notes()
			var level = Level.new()
			level.notes = notes
			current_song.levels.append(level)
		elif node_name == "levels" && parser.get_node_type() == parser.NODE_ELEMENT_END:
			return #ok done

	
func parser_ebeats():
	var count = parser.get_named_attribute_value_safe("count")
	current_song.ebeats.count = count
	
	while parser.read() != ERR_FILE_EOF:
		var node_name = parser.get_node_name()
		print(parser.get_node_name(), ": ", parser.get_node_data())
		if parser.get_node_type() == parser.NODE_ELEMENT && node_name == "ebeat":
			var time = parser.get_named_attribute_value_safe("time").to_float()
			var measure = parser.get_named_attribute_value_safe("measure").to_float()
			var ebeat = Vector2(measure, time)
			current_song.ebeats.beats.append(ebeat)		
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

	#errorCode = parser.open_buffer(xmlPBA)
	#if errorCode != OK:
	#	return #exit(errorCode)
	for x in song.get_property_list():
		for key in x.keys():
			print(key)
			print(x[key])
			

	while parser.read() != ERR_FILE_EOF:
		print(parser.get_node_name(), ": ", parser.get_node_data())
#		print(parser.get_node_name(), ": default---"+ parser.get_named_attribute_value_safe("value"))
		var node_name = parser.get_node_name()
		if(customParser.has(node_name)):
			call("parser_"+node_name)
		if(extractNodes.has(node_name)):
			var data = xml_read_text()
			if data != "":
				song.set(node_name, data)
