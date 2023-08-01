extends VBoxContainer

@onready var h_slider = $HSlider
@onready var cl_label = $CL_Label

func _ready():
	h_slider.value = InstrumentInput.microphone_input.clarity_threshold
	cl_label.text = "Clarity Threshold : %.2f" % h_slider.value
	h_slider.value_changed.connect(_on_value_changed)

func _on_value_changed(value):
	InstrumentInput.microphone_input.clarity_threshold = value
	InstrumentInput.microphone_input.save_volume_profile()
	cl_label.text = "Clarity Threshold : %.2f" % value
