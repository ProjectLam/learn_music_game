extends Object
class_name TSong

var name: String: set = set_name
var artist: String: set = set_artist
var file_name: String: set = set_file_name

var nItem: SongSelectionItem

func _ready():
	pass

func _process(delta):
	pass

func set_name(p_name: String):
	name = p_name

func set_artist(p_artist: String):
	artist = p_artist

func set_file_name(p_file_name: String):
	file_name = p_file_name
