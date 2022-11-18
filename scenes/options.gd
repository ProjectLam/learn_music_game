extends VBoxContainer


@onready var item_list = $%ItemListOutput
@onready var item_list_input = $%ItemListInput


func _ready():
	for item in AudioServer.get_device_list():
		item_list.add_item(item)

	for i in range(item_list.get_item_count()):
		if PlayerVariables.selected_output_device == item_list.get_item_text(i):
			item_list.select(i)
			break
	
	var mic_list : Array = AudioServer.capture_get_device_list()
	for i in mic_list:
		item_list_input.add_item(i)

	for i in range(item_list_input.get_item_count()):
		if PlayerVariables.selected_input_device == item_list_input.get_item_text(i):
			item_list_input.select(i)
			break
	
	var instrument_buttons: Array
	for child in $InputInstrumentMenu.get_children():
		if child is Button:
			instrument_buttons.append(child)
	instrument_buttons[InstrumentInput.current_instrument].button_pressed = true


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
		PlayerVariables.selected_output_device = device
		PlayerVariables.save()



func _on_play_audio_pressed():
	if $AudioStreamPlayer.playing:
		$AudioStreamPlayer.stop()
		$%PlayAudio.text = "Play Audio"
	else:
		$AudioStreamPlayer.play()
		$%PlayAudio.text = "Stop Audio"


func _on_set_input_pressed():
	for item in item_list_input.get_selected_items():
		var device = item_list_input.get_item_text(item)
		AudioServer.capture_set_device(device)
		# Not sure if we even need to keep track except to save in config file
		PlayerVariables.selected_input_device = device
		PlayerVariables.save()



func _on_back_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func on_instrument_toggled(button_pressed: bool, index: int):
	if button_pressed:
		InstrumentInput.set_instrument_by_index(index)
		PlayerVariables.selected_instrument = InstrumentInput.get_instrument_name(index)
		PlayerVariables.save()
