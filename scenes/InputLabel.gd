extends Label

func _process(delta):
	var instrument_name := InstrumentInput.get_instrument_name(InstrumentInput.current_instrument)
	var devices: PackedStringArray = InstrumentInput.get_device_names(InstrumentInput.current_instrument)
	if devices.size() > 0:
		text = instrument_name + "\n" + devices[devices.size() - 1]
	else:
		text = instrument_name
	
