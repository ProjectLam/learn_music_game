extends Node2D

@onready var item_list = get_node(^"ItemListOutput")
@onready var item_list_input = get_node(^"ItemListInput")

func _ready():
	for item in AudioServer.get_device_list():
		item_list.add_item(item)

	var device = AudioServer.get_device()
	for i in range(item_list.get_item_count()):
		if device == item_list.get_item_text(i):
			item_list.select(i)
			break
	
	var mic_list : Array = AudioServer.capture_get_device_list()
	for i in mic_list:
		AudioServer.capture_set_device(i)
		print(AudioServer.capture_get_device())
		item_list_input.add_item(i)

func _process(_delta):
	var speaker_mode_text = "Stereo"
	var input_device_text = AudioServer.capture_get_device()
	var speaker_mode = AudioServer.get_speaker_mode()

	if speaker_mode == AudioServer.SPEAKER_SURROUND_31:
		speaker_mode_text = "Surround 3.1"
	elif speaker_mode == AudioServer.SPEAKER_SURROUND_51:
		speaker_mode_text = "Surround 5.1"
	elif speaker_mode == AudioServer.SPEAKER_SURROUND_71:
		speaker_mode_text = "Surround 7.1"

	$DeviceInfo.text = "Current Device: " + AudioServer.get_device() + "\n"
	$DeviceInfo.text += "Speaker Mode: " + speaker_mode_text + "\n"
	$DeviceInfo.text += "Input Device: " + input_device_text


func _on_set_speaker_pressed():
	for item in item_list.get_selected_items():
		var device = item_list.get_item_text(item)
		AudioServer.set_device(device)



func _on_play_audio_pressed():
	if $AudioStreamPlayer.playing:
		$AudioStreamPlayer.stop()
		$PlayAudio.text = "Play Audio"
	else:
		$AudioStreamPlayer.play()
		$PlayAudio.text = "Stop Audio"


func _on_set_input_pressed():
	for item in item_list_input.get_selected_items():
		var device = item_list_input.get_item_text(item)
		AudioServer.capture_set_device(device)



func _on_back_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
