extends PerformanceInstrument


const MIDDLE_C_OFFSET = 3 + 3 * 12


func _ready():
	var keyboard_instrument = InstrumentInput.get_instrument(InstrumentInput.get_instrument_index("ComputerKeyboardInput"))
	keyboard_instrument.octave_changed.connect(on_keyboard_octave_changed)
	keyboard_instrument.activated.connect(on_keyboard_activated)
	keyboard_instrument.deactivated.connect(on_keyboard_deactivated)
	
	if keyboard_instrument.is_active:
		on_keyboard_activated()
	else:
		on_keyboard_deactivated()


func on_keyboard_octave_changed(new_offset):
	$ComputerKeyboardLabels.position.x = 7 * (new_offset - MIDDLE_C_OFFSET) / 12


func on_keyboard_activated():
	$ComputerKeyboardLabels.show()


func on_keyboard_deactivated():
	$ComputerKeyboardLabels.hide()
