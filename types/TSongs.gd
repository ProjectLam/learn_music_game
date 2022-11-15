extends Object
class_name TSongs

var songs: Array

var serializable: Array: set = set_serializable, get = get_serializable
var json: String: set = set_json, get = get_json

func set_song(name: String, song_data: TSong) -> void:
	for i in range(songs.size()):
		var _song: TSong = songs[i]
		if _song.name == name:
			songs[i] = song_data
			return
	songs.append(song_data)

func get_song(name: String) -> TSong:
	var result: TSong = null
	for i in range(songs.size()):
		var _song: TSong = songs[i]
		if _song.name == name:
			return _song
	return null

func remove(name: String) -> void:
	get_song(name).item.remove()
	songs.erase(name)

func set_serializable(p_serializable: Array) -> void:
	for song in p_serializable:
		var interpreted = TSong.new()
		interpreted.serializable = song
		songs.append(interpreted)

func get_serializable() -> Array:
	var array = []
	for song in songs:
		array.append(song.serializable)
	return array

func set_json(p_json: String) -> void:
	set_serializable(JSON.parse_string(p_json))

func get_json() -> String:
	return JSON.stringify(get_serializable())
