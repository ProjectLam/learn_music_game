extends ProgressBar

@onready var limit_panel = %LimitPanel


func _process(delta):
	if not InstrumentInput.microphone_input.is_active:
		value = 0.0
	else:
		value = InstrumentInput.microphone_input.last_volume
	
	limit_panel.anchor_right = InstrumentInput.microphone_input.volume_start_threshold
