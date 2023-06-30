extends Label

func _process(delta):
	text = InstrumentInput.get_instrument_name(InstrumentInput.current_instrument)
