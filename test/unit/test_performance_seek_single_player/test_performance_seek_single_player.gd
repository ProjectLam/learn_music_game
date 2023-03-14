extends Node

enum Songs {
	TOUGHER_THAN_THE_REST,
	THE_DARK_SIDE_OF_THE_MOON,
}

var SongIds := {
	Songs.TOUGHER_THAN_THE_REST: "Tougher Than the Rest",
	Songs.THE_DARK_SIDE_OF_THE_MOON: "The Dark Side of the Moon"
}

enum Instruments {
	PIANO,
	GUITAR,
}

var Instrument_ids := {
	Instruments.PIANO: "piano.tres",
	Instruments.GUITAR: "guitar.tres",
}

const PERFORMANCE_SCENE := preload("res://scenes/performance.tscn")

@export var load_remote_songs := false

@export var current_song: Songs = Songs.TOUGHER_THAN_THE_REST

@export var instrument: Instruments = Instruments.GUITAR

@export var initial_seek := {
	SongIds[Songs.TOUGHER_THAN_THE_REST]: 0.0,
	SongIds[Songs.THE_DARK_SIDE_OF_THE_MOON]: 0.0
}

@export var vfx := false

var performance_node: Node

func _ready():
	Debug.print_note = true
	GBackend.ui_node.visible = false
	Dialogs.disable_all()
	Dialogs.file_offline_dialog.disabled = false
	
	SessionVariables.instrument = Instrument_ids[instrument]
	if not SongsConfigPreloader.is_song_preload_completed:
		await SongsConfigPreloader.song_preload_completed
	GBackend.skip_remote_json_load = not load_remote_songs
	SessionVariables.song_identifier = SongIds[current_song]
	
	performance_node = PERFORMANCE_SCENE.instantiate()
	add_child(performance_node)
	performance_node.vfx.visible = vfx
	
	while(not performance_node.is_music_playing()):
		await get_tree().process_frame

	var initial_seek_value: float = initial_seek[SongIds[current_song]]
	performance_node.audio_stream.seek(initial_seek_value)
	performance_node.performance_instrument.notes.time = initial_seek_value
	
