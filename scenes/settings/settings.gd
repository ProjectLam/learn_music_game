extends Control

@onready var audio_device = %AudioDevice as OptionButton

func _ready():
	refresh()


const refresh_interval := 60
var refresh_counter := 0
func _process(delta):
	refresh_counter += 1
	if refresh_counter == refresh_interval:
		refresh_counter = 0
		refresh()


func refresh():
	if not is_inside_tree():
		return
	
	_init_audio_devices()


func go_back():
	var current_scene := get_tree().current_scene
	if self == current_scene:
		get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")
	else:
		hide()


func _init_audio_devices():
	audio_device.clear()
	for device in AudioServer.get_input_device_list():
		audio_device.add_item(device)
		if device == AudioServer.input_device:
			audio_device.selected = audio_device.item_count - 1


func _on_audio_device_item_selected(index):
	var dev_name: String = audio_device.get_item_text(index)
	AudioServer.input_device = dev_name
	PlayerVariables.selected_input_device = dev_name
	PlayerVariables.save()
