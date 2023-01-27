extends Node


const CFG_FILENAME = "user://player.cfg"

var songs := {}

var selected_output_device := ""
var selected_input_device := ""

var selected_hw_instrument := ""

var _gameplay_instrument_data: InstrumentData

var gameplay_instrument_name: String:
	set = set_gameplay_instrument_name,
	get = get_gameplay_instrument_name

var gameplay_instrument_data: InstrumentData : 
	set = set_gameplay_instrument_data,
	get = get_gameplay_instrument_data

var config = ConfigFile.new()


func _ready():
	selected_output_device = AudioServer.get_device()
	selected_input_device = AudioServer.capture_get_device()
	selected_hw_instrument = InstrumentInput.get_instrument_name(0)
	gameplay_instrument_data = InstrumentList.instruments.values()[0]
	
	# Load data from a file.
	var err = config.load(CFG_FILENAME)
	if err != OK:
		print("Couldn't load config creating new one")
		save()
	else:
		selected_output_device = config.get_value("hardware", "selected_output_device", selected_output_device)
		selected_input_device = config.get_value("hardware", "selected_input_device", selected_input_device)
		selected_hw_instrument = config.get_value("hardware", "selected_instrument", selected_hw_instrument)
		gameplay_instrument_name = config.get_value("gameplay", "selected_instrument_name", gameplay_instrument_name)
		print("finished loading config")


func save():
	config.set_value("hardware", "selected_output_device", selected_output_device)
	config.set_value("hardware", "selected_input_device", selected_input_device)
	config.set_value("hardware", "selected_instrument", selected_hw_instrument)
	config.set_value("gameplay", "selected_instrument_name", gameplay_instrument_name)
	
	# Save it to a file (overwrite if already exists).
	config.save(CFG_FILENAME)


func get_gameplay_instrument_name() -> String:
	return _gameplay_instrument_data.instrument_name


func set_gameplay_instrument_name(iname: String) -> void:
	var ins = InstrumentList.get_instrument_by_name(iname)
	_gameplay_instrument_data = ins


func get_gameplay_instrument_data() -> InstrumentData:
	return _gameplay_instrument_data


func set_gameplay_instrument_data(idata : InstrumentData) -> void:
	_gameplay_instrument_data = idata
