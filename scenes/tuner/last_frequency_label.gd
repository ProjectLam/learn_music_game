extends Label

func _ready():
	InstrumentInput.microphone_input.new_dominant_peak_detected.connect(_on_new_peak)


func _on_new_peak(peak: Vector3) -> void:
	text = "Dominant Peak\n%.1f Hz %.2f Volume" % [peak.x, peak.y]
