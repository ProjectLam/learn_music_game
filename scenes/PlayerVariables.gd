extends Node
var current_song = ""
var selected_output_device = ""
var selected_input_device = ""
const cfg_filename = "user://player.cfg"
var config = ConfigFile.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	selected_output_device = AudioServer.get_device()
	selected_input_device = AudioServer.capture_get_device()	

	# Load data from a file.
	var err = config.load(cfg_filename)
	if err != OK:
		print("Couldn't load config creating new one")
		
		config = ConfigFile.new()
		config.set_value("hardware", "selected_output_device", selected_output_device)
		config.set_value("hardware", "selected_input_device", selected_input_device)

		# Save it to a file (overwrite if already exists).
		config.save(cfg_filename)
	else:
		selected_output_device = config.get_value("hardware", "selected_output_device")
		selected_input_device = config.get_value("hardware", "selected_input_device")
		print("finished loading config")

func save():
	config.set_value("hardware", "selected_output_device", selected_output_device)
	config.set_value("hardware", "selected_input_device", selected_input_device)

	# Save it to a file (overwrite if already exists).
	config.save(cfg_filename)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
