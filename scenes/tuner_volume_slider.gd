extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready():
	value = InstrumentInput.microphone_input.volume_start_threshold
	value_changed.connect(_on_value_changed)

func _on_value_changed(value):
	InstrumentInput.microphone_input.volume_start_threshold = value
	InstrumentInput.microphone_input.volume_end_threshold = value * 0.5
	InstrumentInput.microphone_input.save_volume_profile()
