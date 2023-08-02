extends Label

func _ready():
	InstrumentInput.microphone_input.new_dominant_peak_detected.connect(_on_new_peak)


func _on_new_peak(peak: Vector2) -> void:
	text = "%.1f Hz %.1f Volume" % [peak.x, peak.y]
