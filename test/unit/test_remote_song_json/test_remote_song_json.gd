extends Control


@onready var song_buttons = %SongButtons
@onready var audio_stream_player = %AudioStreamPlayer
@onready var song_loader = %SongLoader
@onready var preloader_status = %PreloaderStatus
@onready var player_indicator = %AudioStreamPlayerIndicator



# Called when the node enters the scene tree for the first time.
func _ready():
	SongsConfigPreloader.song_preloaded.connect(_on_song_preloaded)
	for sid in PlayerVariables.songs:
		_on_song_preloaded(PlayerVariables.songs[sid])
	
	if not SongsConfigPreloader.is_song_repload_completed:
		await SongsConfigPreloader.song_preload_completed
	preloader_status.text = "Preloader Status : Preload completed"


func _process(delta):
	if audio_stream_player.playing:
		player_indicator.text = "Playing : %.0f/%.0f" % [
				audio_stream_player.get_playback_position(), 
				audio_stream_player.stream.get_length()]
	else:
		player_indicator.text = "Paused"

func _on_song_loaded(song: Song):
	audio_stream_player.stream = song_loader.get_main_stream(song)
	audio_stream_player.play()


func _on_song_preloaded(song: Song):
	var new_button := Button.new()
	new_button.text = song.title
	new_button.set("theme_override_font_sizes/font_size", 25)
	new_button.pressed.connect(func() : _on_play_song_pressed(song))
	song_buttons.add_child(new_button)


func _on_play_song_pressed(song: Song):
	song_loader.load_song(song)
