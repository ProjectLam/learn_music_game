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
	var document := _parse_xml_into_data(parser)
	
	print(document.get_elements_by_name("level").size(), " level tags")


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
