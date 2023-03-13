extends Node

@export var parent_url: String = ""
@export var target_url: String = ""

@onready var audio_stream_player = %AudioStreamPlayer
@onready var progress_label = %ProgressLabel

var remote_access := RemoteFileAccess.new()
var request_node

func _ready():
	GBackend.skip_remote_json_load = true
	GBackend.ui_node.visible = false
	Dialogs.disable_all()
	audio_stream_player.finished.connect(audio_play_finished)
	
	remote_access.parent_url = parent_url
	request_node = remote_access.create_request(target_url)
	request_node.request_completed.connect(_on_request_completed)
	add_child(request_node)


func _on_request_completed(mp3_buffer):
	print("request completed. downloaded buffer length is :", mp3_buffer.size())
	var sound := AudioStreamMP3.new()
	sound.data = mp3_buffer
	audio_stream_player.stream = sound
	audio_stream_player.play()


func audio_play_finished():
	audio_stream_player.play()


func _process(delta):
	if(is_instance_valid(request_node)):
		progress_label.text = "%s/%s" % [
				request_node.get_downloaded_bytes(), 
				request_node.get_remaining_bytes()]
