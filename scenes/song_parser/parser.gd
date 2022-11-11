extends Node
class_name SongParser

var errorCode = 0
var parser = XMLParser.new()
var xmlPBA = PackedByteArray()
var extractNodes = { "artistName": true, "title": true, "albumName": true }
var customParser = { "ebeats": true }

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func parser_ebeats():
	print("weeee ebeats")

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
