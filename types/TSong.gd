extends Object
class_name TSong

var name: String: set = set_name
var artist: String: set = set_artist
var filename: String

var item: TSongSelectionItem = null

var serializable: Dictionary: set = set_serializable, get = get_serializable
var json: String: set = set_json, get = get_json

func set_serializable(p_serializable: Dictionary) -> void:
	name = p_serializable["name"]
	artist = p_serializable["artist"]
	filename = p_serializable["filename"]

func get_serializable() -> Dictionary:
	return {
		name = name,
		artist = artist,
		filename = filename
	}

func set_name(p_name: String):
	name = p_name
	
	if item and item.nNameLabel:
		item.nNameLabel.text = name

func set_artist(p_artist: String):
	artist = p_artist
	
	if item and item.nArtistLabel:
		item.nArtistLabel.text = name

func set_json(p_json: String) -> void:
	serializable = JSON.parse_string(p_json)

func get_json() -> String:
	return JSON.stringify(serializable)

func update_ui() -> void:
	if not item:
		return
	
	if item.nNameLabel:
		item.nNameLabel.text = name
	if item.nArtistLabel:
		item.nArtistLabel.text = artist
