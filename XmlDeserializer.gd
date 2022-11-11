extends XMLParser
class_name XmlDeserializer

@export var tag_name : String #setget , get_tag_name
@export var node_type: String #setget, get_node_type_string

func get_tag_name():
	if get_node_type() == XMLParser.NODE_TEXT:
		return "[Text]"
	return get_node_name()

var err = OK
var current_file_name
func read_start_element() -> String:
	if is_empty() and get_node_type() == XMLParser.NODE_ELEMENT:
		return ""
	err = read()
	while err == OK:
		match get_node_type():
			XMLParser.NODE_ELEMENT:
				return get_node_name()
			XMLParser.NODE_ELEMENT_END:
				return ""
			_:
				pass
		err = read()
	return ""

func skip():
	if is_empty():
		err = read()
	else:
		skip_section()

func attr(name) -> String:
	return get_named_attribute_value(name)

func init_attribute(node, name, xml_name = null):
	if not xml_name:
		xml_name = name
	var old_value = node.get_indexed(name)
	var value = read_typed_value(typeof(old_value), xml_name)
	assert(value != null)
	node.set_indexed(name, value)

func read_typed_value(type, attribute):
	var xml_val = get_named_attribute_value(attribute)
	match type:
		TYPE_BOOL:
			return xml_val.to_lower() == "true"
		TYPE_INT:
			return xml_val.to_int()
#todo appears gone in gdscript 3
#		TYPE_REAL:
#			return xml_val.to_float()
		TYPE_STRING:
			return xml_val.xml_unescape()
		_:
			if xml_val == "null":
				return null
			else:
				error("Cannot initialize property: Unknown type: " + String(type))
				return null


func util_opt(prop_name, attribute):
	return prop_name

func init_property(node, prop_name = null):
	assert(get_node_type() == XMLParser.NODE_ELEMENT)
	assert(get_node_name() == "property")
#TODo where did this come from? #	prop_name = Util.opt(prop_name, attr("name"))
	prop_name = util_opt(prop_name, attr("name"))
	var old_value = node.get_indexed(prop_name)
	var value
	if has_attribute("value"):
		assert(old_value != null)
		value = read_typed_value(typeof(old_value), "value")
		assert(value != null)
		skip()
	else:
		value = read_value()
		assert(value != null)
		skip()

	node.set(prop_name, value)

func read_value():
	if not read_start_element() == "value":
		error("Malformed property tag")
		return null
	var value = parse_value()
	return value

func parse_value():
	match attr("type"):
		"Color":
			var value = Color(attr("r").to_float(), attr("g").to_float(), attr("b").to_float(), attr("a").to_float())
			skip()
			return value
		"Vector2":
			var value = Vector2(attr("x").to_float(), attr("y").to_float())
			skip()
			return value
		"Resource":
			var value = load(attr("value"))
			skip()
			return value
		"Rect2":
			var value = Rect2(attr("x").to_float(), attr("y").to_float(), attr("w").to_float(), attr("h").to_float())
			skip()
			return value
		"int":
			var value = attr("value").to_int()
			skip()
			return value
		"real":
			var value = attr("value").to_float()
			skip()
			return value
		"bool":
			var value =  attr("value").to_lower() == "true"
			skip()
			return value
		"string":
			var value =  attr("value").xml_unescape()
			skip()
			return value
		"Array":
			var res =[]
			var element = read_start_element()
			while element == "value":
				res.append(parse_value())
				element = read_start_element()
			return res

func read_text():
	assert(get_node_type() == NODE_ELEMENT)
	err = read()
	var text = get_node_data()
	err = read()
	assert(get_node_type() == NODE_ELEMENT_END)
	return text

func get_node_type_string():
	match get_node_type():
		NODE_NONE: return "NONE"
		NODE_ELEMENT: return "ELEMENT"
		NODE_ELEMENT_END: return "END_ELEMENT"
		NODE_TEXT: return "TEXT"
		NODE_COMMENT: return "COMMENT"
		NODE_CDATA: return "CDATA"
		NODE_UNKNOWN: return "UNKNOWN"


func read_world(file_name):
	current_file_name = file_name
	err = open(file_name)
	if err != OK:
		return

	err = read()
	var root = read_start_element()
	if root != "save_game":
		return null
	if not read_start_element() == "world":
		return null
	var world = load("res://world.tscn").instance()
	#TODO what is this? #Debug.dump_tree(world)
	world.deserialize(self)

	return world


func deserialize_children(node: Object, prefix="deserialize_"):
	if is_empty():
		skip()
		return
	assert(get_node_type() == NODE_ELEMENT)
	var tag = get_node_name()
	var element = read_start_element()
	while element:
		node.call(prefix+element, self)
		element = read_start_element()
	assert(get_node_type() == NODE_ELEMENT_END and get_node_name() == tag or is_empty())

func trace(msg = ""):
	print("%s:%d %s:%s %s" % [current_file_name, get_current_line(), get_node_type_string(), get_node_name(), msg])

func warning(text):
	push_warning("%s(%d): %s" % [current_file_name, get_current_line(), text])

func error(text):
	push_error("%s(%d): %s" % [current_file_name, get_current_line(), text])
