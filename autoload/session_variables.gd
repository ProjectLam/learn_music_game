extends Node

var load_test_song := true

var instrument: String = ""

var current_song :Song

var single_player := true

var song_identifier : String :
	set(sid):
		var n_song = PlayerVariables.songs.get(sid)
		if !n_song:
			push_error("Song not found")
		else:
			current_song = n_song
	get:
		if current_song:
			return current_song.get_identifier()
		else:
			return "invalid_song"

const synch_variables := {
	"song_identifier": true,
	"instrument": true,
}

signal song_changed
signal instrument_changed

func sync_remote():
	var sync_dict := {}
	for k in synch_variables:
		sync_dict[k] = get(k)
	rpc("_sync_remote", sync_dict)

@rpc("authority", "call_local", "reliable") func _sync_remote(sync_dict : Dictionary):
	print("sync called with ", sync_dict)
	var prev_song := current_song
	var prev_instrument := instrument
	
	for k in sync_dict:
		# TODO , some sort of a security is needed. is this solution fine?
		if synch_variables.get(k):
			set(k, sync_dict[k])
	
	# Note : In the current implementations 'instrument_changed' needs to emit 
	#   before 'song_changed'.
	
	if instrument != prev_instrument:
		instrument_changed.emit()

	if prev_song != current_song:
		song_changed.emit()
