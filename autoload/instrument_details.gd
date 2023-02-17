extends Node

# this singleton is made for future use.

func get_songs_number(idata: InstrumentData) -> int:
	if not SongsConfigPreloader.is_song_preload_completed:
		push_warning("Getting songs number before songs are loaded")
	return PlayerVariables.songs.keys().size()


func get_courses_number(idata : InstrumentData) -> int:
	if not SongsConfigPreloader.is_song_preload_completed:
		push_warning("courses songs number before songs are loaded")
	return 0
