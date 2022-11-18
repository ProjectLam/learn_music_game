extends Node


const CFG_FILENAME = "user://player.cfg"

var current_song:Song
var songs:Array[Song] = []

var selected_output_device = ""
var selected_input_device = ""

var selected_instrument = ""

var config = ConfigFile.new()


func _ready():
	selected_output_device = AudioServer.get_device()
	selected_input_device = AudioServer.capture_get_device()
	selected_instrument = InstrumentInput.get_instrument_name(0)
	
	# Load data from a file.
	var err = config.load(CFG_FILENAME)
	if err != OK:
		print("Couldn't load config creating new one")
		save()
	else:
		selected_output_device = config.get_value("hardware", "selected_output_device")
		selected_input_device = config.get_value("hardware", "selected_input_device")
		selected_instrument = config.get_value("hardware", "selected_instrument")
		print("finished loading config")


func save():
	config.set_value("hardware", "selected_output_device", selected_output_device)
	config.set_value("hardware", "selected_input_device", selected_input_device)
	config.set_value("hardware", "selected_instrument", selected_instrument)
	
	# Save it to a file (overwrite if already exists).
	config.save(CFG_FILENAME)
