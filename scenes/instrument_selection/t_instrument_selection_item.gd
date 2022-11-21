extends Object
class_name TInstrumentSelectionItem

var nItem: InstrumentSelectionItem
var name: String
var image: Texture: set = set_image
var label: String: set = set_label
var songs_count: int: set = set_songs_count
var courses_count: int: set = set_courses_count

func _ready():
	pass

func _process(delta):
	pass

func set_label(p_label: String):
	label = p_label
	nItem.find_child("NameLabel").text = label

func set_songs_count(p_songs_count: int):
	songs_count = p_songs_count
	nItem.find_child("SongsCountLabel").text = label

func set_courses_count(p_courses_count: int):
	courses_count = p_courses_count
	nItem.find_child("CoursesCountLabel").text = label

func set_image(p_image: Texture):
	image = p_image
	var nImage = nItem.find_child("Image")
	nImage.texture = image
